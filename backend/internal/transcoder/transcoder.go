package transcoder

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/tareeqmajdapp/backend/internal/logger"
)

type State string

const (
	StateNone       State = "none"
	StateQueued     State = "queued"
	StateProcessing State = "processing"
	StateReady      State = "ready"
	StateFailed     State = "failed"
)

type Variant struct {
	Height   int    `json:"height"`
	Name     string `json:"name"`
	Playlist string `json:"playlist"`
}

type Status struct {
	State     State     `json:"state"`
	Error     string    `json:"error,omitempty"`
	HLS       string    `json:"hls,omitempty"`
	Variants  []Variant `json:"variants,omitempty"`
	UpdatedAt string    `json:"updatedAt"`
}

var idPattern = regexp.MustCompile(`^[0-9A-Za-z._-]{6,160}$`)

type rendition struct {
	name     string
	height   int
	vBitrate string
	vMax     string
	vBuf     string
}

type Transcoder struct {
	uploadsDir  string
	ffmpegPath  string
	ffprobePath string
	available   bool
	jobs        chan string
	mu          sync.Mutex
	inflight    map[string]bool
}

func New(uploadsDir string) *Transcoder {
	ffmpeg, errF := exec.LookPath("ffmpeg")
	ffprobe, errP := exec.LookPath("ffprobe")
	t := &Transcoder{
		uploadsDir:  uploadsDir,
		ffmpegPath:  ffmpeg,
		ffprobePath: ffprobe,
		available:   errF == nil && errP == nil,
		jobs:        make(chan string, 512),
		inflight:    make(map[string]bool),
	}
	if t.available {
		logger.Info("Transcoder: ffmpeg=%s ffprobe=%s (adaptive HLS enabled)", ffmpeg, ffprobe)
	} else {
		logger.Warn("Transcoder: ffmpeg/ffprobe not found — lectures play progressively, no adaptive HLS")
	}
	return t
}

func (t *Transcoder) Available() bool { return t.available }

func (t *Transcoder) Start() {
	if !t.available {
		return
	}
	go t.worker()
}

func (t *Transcoder) worker() {
	for src := range t.jobs {
		t.process(src)
	}
}

func idForVideoPath(p string) string {
	base := filepath.Base(p)
	return strings.TrimSuffix(base, filepath.Ext(base))
}

func (t *Transcoder) outDir(id string) string {
	return filepath.Join(t.uploadsDir, "hls", id)
}

func (t *Transcoder) statusPath(id string) string {
	return filepath.Join(t.outDir(id), "status.json")
}

func (t *Transcoder) Enqueue(absVideoPath string) {
	if !t.available {
		return
	}
	id := idForVideoPath(absVideoPath)
	if !idPattern.MatchString(id) {
		return
	}
	t.mu.Lock()
	if t.inflight[id] {
		t.mu.Unlock()
		return
	}
	t.inflight[id] = true
	t.mu.Unlock()

	_ = os.MkdirAll(t.outDir(id), 0755)
	t.writeStatus(id, Status{State: StateQueued})
	select {
	case t.jobs <- absVideoPath:
	default:
		t.mu.Lock()
		delete(t.inflight, id)
		t.mu.Unlock()
		t.writeStatus(id, Status{State: StateNone})
	}
}

func (t *Transcoder) writeStatus(id string, s Status) {
	s.UpdatedAt = time.Now().UTC().Format(time.RFC3339)
	data, err := json.Marshal(s)
	if err != nil {
		return
	}
	_ = os.MkdirAll(t.outDir(id), 0755)
	_ = os.WriteFile(t.statusPath(id), data, 0644)
}

func (t *Transcoder) StatusFor(videoPathOrID string) Status {
	id := videoPathOrID
	if strings.Contains(videoPathOrID, "/") || strings.Contains(videoPathOrID, ".") {
		id = idForVideoPath(videoPathOrID)
	}
	if !idPattern.MatchString(id) {
		return Status{State: StateNone}
	}
	data, err := os.ReadFile(t.statusPath(id))
	if err != nil {
		return Status{State: StateNone}
	}
	var s Status
	if err := json.Unmarshal(data, &s); err != nil {
		return Status{State: StateNone}
	}
	return s
}

func (t *Transcoder) process(src string) {
	id := idForVideoPath(src)
	defer func() {
		t.mu.Lock()
		delete(t.inflight, id)
		t.mu.Unlock()
	}()

	t.writeStatus(id, Status{State: StateProcessing})

	height, hasAudio, err := t.probe(src)
	if err != nil {
		logger.Error("Transcoder: probe %s: %v", id, err)
		t.writeStatus(id, Status{State: StateFailed, Error: "probe failed"})
		return
	}

	renditions := planRenditions(height)
	if len(renditions) == 0 {
		t.writeStatus(id, Status{State: StateFailed, Error: "unsupported resolution"})
		return
	}

	out := t.outDir(id)
	start := time.Now()
	if err := t.runFFmpeg(src, out, renditions, hasAudio); err != nil {
		logger.Error("Transcoder: ffmpeg %s: %v", id, err)
		t.writeStatus(id, Status{State: StateFailed, Error: "encode failed"})
		return
	}

	variants := make([]Variant, 0, len(renditions))
	for i, r := range renditions {
		variants = append(variants, Variant{
			Height:   r.height,
			Name:     r.name,
			Playlist: fmt.Sprintf("/uploads/hls/%s/stream_%d/playlist.m3u8", id, i),
		})
	}
	t.writeStatus(id, Status{
		State:    StateReady,
		HLS:      fmt.Sprintf("/uploads/hls/%s/master.m3u8", id),
		Variants: variants,
	})
	logger.Info("Transcoder: %s ready (%d renditions) in %s", id, len(renditions), time.Since(start).Round(time.Second))
}

func (t *Transcoder) probe(src string) (height int, hasAudio bool, err error) {
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()

	hCmd := exec.CommandContext(ctx, t.ffprobePath,
		"-v", "error", "-select_streams", "v:0",
		"-show_entries", "stream=height", "-of", "csv=p=0", src)
	hOut, herr := hCmd.Output()
	if herr != nil {
		return 0, false, herr
	}
	height, err = strconv.Atoi(strings.TrimSpace(strings.SplitN(string(hOut), "\n", 2)[0]))
	if err != nil {
		return 0, false, fmt.Errorf("parse height: %w", err)
	}

	aCmd := exec.CommandContext(ctx, t.ffprobePath,
		"-v", "error", "-select_streams", "a",
		"-show_entries", "stream=index", "-of", "csv=p=0", src)
	aOut, _ := aCmd.Output()
	hasAudio = strings.TrimSpace(string(aOut)) != ""
	return height, hasAudio, nil
}

func planRenditions(srcHeight int) []rendition {
	r1080 := rendition{"1080p", 1080, "5000k", "5350k", "7500k"}
	r720 := rendition{"720p", 720, "2800k", "3000k", "4200k"}
	r480 := rendition{"480p", 480, "1400k", "1500k", "2100k"}

	switch {
	case srcHeight >= 1080:
		return []rendition{r720, r1080}
	case srcHeight >= 720:
		return []rendition{r480, r720}
	case srcHeight >= 480:
		return []rendition{{"480p", srcHeight, "1400k", "1500k", "2100k"}}
	case srcHeight > 0:
		return []rendition{{fmt.Sprintf("%dp", srcHeight), srcHeight, "900k", "1000k", "1500k"}}
	default:
		return nil
	}
}

func (t *Transcoder) runFFmpeg(src, out string, renditions []rendition, hasAudio bool) error {
	if err := os.MkdirAll(out, 0755); err != nil {
		return err
	}

	n := len(renditions)
	var filterParts []string
	splitOuts := ""
	for i := 0; i < n; i++ {
		splitOuts += fmt.Sprintf("[vin%d]", i)
	}
	filterParts = append(filterParts, fmt.Sprintf("[0:v]split=%d%s", n, splitOuts))
	for i, r := range renditions {
		filterParts = append(filterParts, fmt.Sprintf("[vin%d]scale=w=-2:h=%d[v%d]", i, r.height, i))
	}
	filter := strings.Join(filterParts, ";")

	args := []string{
		"-y", "-i", src,
		"-filter_complex", filter,
		"-preset", "veryfast",
		"-sc_threshold", "0",
		"-g", "48", "-keyint_min", "48",
		"-c:v", "libx264", "-pix_fmt", "yuv420p",
	}

	var maps []string
	var streamMap []string
	for i, r := range renditions {
		maps = append(maps, "-map", fmt.Sprintf("[v%d]", i))
		if hasAudio {
			maps = append(maps, "-map", "0:a:0?")
		}
		args = append(args,
			fmt.Sprintf("-b:v:%d", i), r.vBitrate,
			fmt.Sprintf("-maxrate:v:%d", i), r.vMax,
			fmt.Sprintf("-bufsize:v:%d", i), r.vBuf,
		)
		if hasAudio {
			streamMap = append(streamMap, fmt.Sprintf("v:%d,a:%d", i, i))
		} else {
			streamMap = append(streamMap, fmt.Sprintf("v:%d", i))
		}
	}
	args = append(args, maps...)
	if hasAudio {
		args = append(args, "-c:a", "aac", "-ar", "48000", "-b:a", "128k")
	}
	args = append(args,
		"-f", "hls",
		"-hls_time", "6",
		"-hls_playlist_type", "vod",
		"-hls_flags", "independent_segments",
		"-hls_segment_type", "mpegts",
		"-hls_segment_filename", filepath.Join(out, "stream_%v", "data_%03d.ts"),
		"-master_pl_name", "master.m3u8",
		"-var_stream_map", strings.Join(streamMap, " "),
		filepath.Join(out, "stream_%v", "playlist.m3u8"),
	)

	ctx, cancel := context.WithTimeout(context.Background(), 12*time.Hour)
	defer cancel()

	cmd := exec.CommandContext(ctx, t.ffmpegPath, args...)
	var stderr strings.Builder
	cmd.Stderr = &stderr
	if err := cmd.Run(); err != nil {
		tail := stderr.String()
		if len(tail) > 800 {
			tail = tail[len(tail)-800:]
		}
		return fmt.Errorf("%w: %s", err, tail)
	}
	return nil
}

func (t *Transcoder) Reconcile() {
	if !t.available {
		return
	}
	videosDir := filepath.Join(t.uploadsDir, "videos")
	entries, err := os.ReadDir(videosDir)
	if err != nil {
		return
	}
	for _, e := range entries {
		if e.IsDir() {
			continue
		}
		abs := filepath.Join(videosDir, e.Name())
		id := idForVideoPath(abs)
		st := t.StatusFor(id)
		if st.State == StateReady || st.State == StateProcessing {
			continue
		}
		t.Enqueue(abs)
	}
}

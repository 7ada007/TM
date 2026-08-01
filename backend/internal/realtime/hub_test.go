package realtime

import (
	"encoding/json"
	"sync"
	"testing"
	"time"

	"github.com/tareeqmajdapp/backend/internal/models"
)

type fakeStore struct {
	mu      sync.Mutex
	batches [][]models.ProgressUpdate
	rows    map[string]models.LectureProgress
}

func newFakeStore() *fakeStore {
	return &fakeStore{rows: map[string]models.LectureProgress{}}
}

func (f *fakeStore) UpsertBatch(updates []models.ProgressUpdate) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.batches = append(f.batches, updates)
	return nil
}

func (f *fakeStore) Get(userID, lectureID string) (*models.LectureProgress, error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	row, ok := f.rows[userID+"|"+lectureID]
	if !ok {
		return nil, nil
	}
	return &row, nil
}

func (f *fakeStore) totalDelta(userID, lectureID string) float64 {
	f.mu.Lock()
	defer f.mu.Unlock()
	total := 0.0
	for _, batch := range f.batches {
		for _, u := range batch {
			if u.UserID == userID && u.LectureID == lectureID {
				total += u.WatchedDeltaSeconds
			}
		}
	}
	return total
}

func (f *fakeStore) lastFor(userID, lectureID string) (models.ProgressUpdate, bool) {
	f.mu.Lock()
	defer f.mu.Unlock()
	var last models.ProgressUpdate
	found := false
	for _, batch := range f.batches {
		for _, u := range batch {
			if u.UserID == userID && u.LectureID == lectureID {
				last = u
				found = true
			}
		}
	}
	return last, found
}

func newTestHub(store ProgressStore) *Hub {
	h := NewHub(store)
	go h.Run()
	return h
}

func studentClient(h *Hub, id, name string) *Client {
	return &Client{
		hub:        h,
		send:       make(chan []byte, sendBuffer),
		registered: make(chan struct{}),
		userID:     id,
		userName:   name,
		section:    "شعبة أ",
		role:       "student",
	}
}

func monitorClient(h *Hub, id string) *Client {
	return &Client{
		hub:        h,
		send:       make(chan []byte, sendBuffer),
		registered: make(chan struct{}),
		userID:     id,
		userName:   "مشرف",
		role:       "admin",
		monitor:    true,
	}
}

func connect(t *testing.T, h *Hub, c *Client) *Client {
	t.Helper()
	h.register <- c
	select {
	case <-c.registered:
	case <-time.After(time.Second):
		t.Fatalf("registration of %s timed out", c.userID)
	}
	return c
}

func drainFor(t *testing.T, c *Client, want string, timeout time.Duration) map[string]any {
	t.Helper()
	deadline := time.After(timeout)
	for {
		select {
		case payload := <-c.send:
			var decoded map[string]any
			if err := json.Unmarshal(payload, &decoded); err != nil {
				t.Fatalf("bad payload: %v", err)
			}
			if decoded["type"] == want {
				return decoded
			}
		case <-deadline:
			t.Fatalf("timed out waiting for %q", want)
		}
	}
}

func TestMonitorReceivesSnapshotOnConnect(t *testing.T) {
	h := newTestHub(newFakeStore())
	defer h.Stop()

	student := studentClient(h, "s1", "أحمد")
	connect(t, h, student)

	monitor := monitorClient(h, "a1")
	connect(t, h, monitor)

	msg := drainFor(t, monitor, MsgSnapshot, time.Second)
	viewers, _ := msg["viewers"].([]any)
	if len(viewers) != 1 {
		t.Fatalf("expected 1 viewer in snapshot, got %d", len(viewers))
	}
	first, _ := viewers[0].(map[string]any)
	if first["userId"] != "s1" {
		t.Fatalf("unexpected viewer: %v", first)
	}
	if first["online"] != true {
		t.Fatalf("connected student should be online")
	}
}

func TestProgressBroadcastsToMonitor(t *testing.T) {
	h := newTestHub(newFakeStore())
	defer h.Stop()

	student := studentClient(h, "s1", "أحمد")
	connect(t, h, student)
	monitor := monitorClient(h, "a1")
	connect(t, h, monitor)
	drainFor(t, monitor, MsgSnapshot, time.Second)

	h.inbound <- clientMessage{client: student, message: InboundMessage{
		Type:                MsgProgress,
		LectureID:           "l1",
		LectureTitle:        "المشتقات",
		PositionSeconds:     30,
		DurationSeconds:     600,
		WatchedDeltaSeconds: 30,
		Playing:             true,
	}}

	msg := drainFor(t, monitor, MsgActivity, time.Second)
	viewer, _ := msg["viewer"].(map[string]any)
	if viewer["lectureId"] != "l1" {
		t.Fatalf("expected lectureId l1, got %v", viewer["lectureId"])
	}
	if viewer["playing"] != true {
		t.Fatalf("expected playing true")
	}
	if p, _ := viewer["percent"].(float64); p < 0.049 || p > 0.051 {
		t.Fatalf("expected percent ~0.05, got %v", viewer["percent"])
	}
}

func TestWatchedSecondsAccumulateAcrossReports(t *testing.T) {
	store := newFakeStore()
	h := newTestHub(store)
	defer h.Stop()

	student := studentClient(h, "s1", "أحمد")
	connect(t, h, student)
	monitor := monitorClient(h, "a1")
	connect(t, h, monitor)
	drainFor(t, monitor, MsgSnapshot, time.Second)

	for i := 1; i <= 4; i++ {
		h.inbound <- clientMessage{client: student, message: InboundMessage{
			Type:                MsgProgress,
			LectureID:           "l1",
			PositionSeconds:     float64(i * 5),
			DurationSeconds:     600,
			WatchedDeltaSeconds: 5,
			Playing:             true,
		}}
		drainFor(t, monitor, MsgActivity, time.Second)
	}

	h.inbound <- clientMessage{client: student, message: InboundMessage{
		Type: MsgStopped, LectureID: "l1",
	}}
	drainFor(t, monitor, MsgActivity, time.Second)

	deadline := time.Now().Add(time.Second)
	for time.Now().Before(deadline) {
		if store.totalDelta("s1", "l1") == 20 {
			return
		}
		time.Sleep(10 * time.Millisecond)
	}
	t.Fatalf("expected 20s persisted, got %v", store.totalDelta("s1", "l1"))
}

func TestSeekingDoesNotInflateWatchedSeconds(t *testing.T) {
	store := newFakeStore()
	h := newTestHub(store)
	defer h.Stop()

	student := studentClient(h, "s1", "أحمد")
	connect(t, h, student)

	h.inbound <- clientMessage{client: student, message: InboundMessage{
		Type: MsgProgress, LectureID: "l1", PositionSeconds: 10,
		DurationSeconds: 600, WatchedDeltaSeconds: 10, Playing: true,
	}}
	h.inbound <- clientMessage{client: student, message: InboundMessage{
		Type: MsgProgress, LectureID: "l1", PositionSeconds: 500,
		DurationSeconds: 600, WatchedDeltaSeconds: 0, Playing: true,
	}}
	h.inbound <- clientMessage{client: student, message: InboundMessage{
		Type: MsgStopped, LectureID: "l1",
	}}

	deadline := time.Now().Add(time.Second)
	for time.Now().Before(deadline) {
		if last, ok := store.lastFor("s1", "l1"); ok {
			if store.totalDelta("s1", "l1") != 10 {
				t.Fatalf("seek inflated watched time: %v", store.totalDelta("s1", "l1"))
			}
			if last.LastPositionSeconds != 500 {
				t.Fatalf("expected final position 500, got %v", last.LastPositionSeconds)
			}
			return
		}
		time.Sleep(10 * time.Millisecond)
	}
	t.Fatal("no progress persisted")
}

func TestCompletionIsDetectedAndPersisted(t *testing.T) {
	store := newFakeStore()
	h := newTestHub(store)
	defer h.Stop()

	student := studentClient(h, "s1", "أحمد")
	connect(t, h, student)
	monitor := monitorClient(h, "a1")
	connect(t, h, monitor)
	drainFor(t, monitor, MsgSnapshot, time.Second)

	h.inbound <- clientMessage{client: student, message: InboundMessage{
		Type: MsgProgress, LectureID: "l1", PositionSeconds: 599,
		DurationSeconds: 600, WatchedDeltaSeconds: 599, Playing: true,
	}}

	msg := drainFor(t, monitor, MsgActivity, time.Second)
	viewer, _ := msg["viewer"].(map[string]any)
	if viewer["completed"] != true {
		t.Fatalf("expected completed true, got %v", viewer["completed"])
	}

	deadline := time.Now().Add(time.Second)
	for time.Now().Before(deadline) {
		if last, ok := store.lastFor("s1", "l1"); ok && last.Completed {
			return
		}
		time.Sleep(10 * time.Millisecond)
	}
	t.Fatal("completion was not persisted")
}

func TestDisconnectMarksOfflineAndFlushes(t *testing.T) {
	store := newFakeStore()
	h := newTestHub(store)
	defer h.Stop()

	student := studentClient(h, "s1", "أحمد")
	connect(t, h, student)
	monitor := monitorClient(h, "a1")
	connect(t, h, monitor)
	drainFor(t, monitor, MsgSnapshot, time.Second)

	h.inbound <- clientMessage{client: student, message: InboundMessage{
		Type: MsgProgress, LectureID: "l1", PositionSeconds: 42,
		DurationSeconds: 600, WatchedDeltaSeconds: 42, Playing: true,
	}}
	drainFor(t, monitor, MsgActivity, time.Second)

	h.unregister <- student

	msg := drainFor(t, monitor, MsgPresence, time.Second)
	viewer, _ := msg["viewer"].(map[string]any)
	if viewer["online"] != false {
		t.Fatalf("expected offline after disconnect")
	}

	deadline := time.Now().Add(time.Second)
	for time.Now().Before(deadline) {
		if store.totalDelta("s1", "l1") == 42 {
			return
		}
		time.Sleep(10 * time.Millisecond)
	}
	t.Fatalf("disconnect did not flush progress, got %v", store.totalDelta("s1", "l1"))
}

func TestMultipleDevicesKeepStudentOnlineUntilLastLeaves(t *testing.T) {
	h := newTestHub(newFakeStore())
	defer h.Stop()

	first := studentClient(h, "s1", "أحمد")
	second := studentClient(h, "s1", "أحمد")
	connect(t, h, first)
	connect(t, h, second)

	monitor := monitorClient(h, "a1")
	connect(t, h, monitor)
	drainFor(t, monitor, MsgSnapshot, time.Second)

	h.unregister <- first

	select {
	case payload := <-monitor.send:
		var decoded map[string]any
		_ = json.Unmarshal(payload, &decoded)
		if decoded["type"] == MsgPresence {
			viewer, _ := decoded["viewer"].(map[string]any)
			if viewer["online"] == false {
				t.Fatal("student went offline while a second device was still connected")
			}
		}
	case <-time.After(200 * time.Millisecond):
	}

	h.unregister <- second
	msg := drainFor(t, monitor, MsgPresence, time.Second)
	viewer, _ := msg["viewer"].(map[string]any)
	if viewer["online"] != false {
		t.Fatal("student should be offline after the last device disconnects")
	}
}

func TestPreviousWatchedTimeIsRestoredForResumedLecture(t *testing.T) {
	store := newFakeStore()
	store.rows["s1|l1"] = models.LectureProgress{
		UserID: "s1", LectureID: "l1",
		WatchedSeconds: 120, DurationSeconds: 600,
	}
	h := newTestHub(store)
	defer h.Stop()

	student := studentClient(h, "s1", "أحمد")
	connect(t, h, student)
	monitor := monitorClient(h, "a1")
	connect(t, h, monitor)
	drainFor(t, monitor, MsgSnapshot, time.Second)

	h.inbound <- clientMessage{client: student, message: InboundMessage{
		Type: MsgProgress, LectureID: "l1", PositionSeconds: 125,
		DurationSeconds: 600, WatchedDeltaSeconds: 5, Playing: true,
	}}

	deadline := time.After(time.Second)
	for {
		select {
		case payload := <-monitor.send:
			var decoded map[string]any
			_ = json.Unmarshal(payload, &decoded)
			if decoded["type"] != MsgActivity {
				continue
			}
			viewer, _ := decoded["viewer"].(map[string]any)
			if w, _ := viewer["watchedSeconds"].(float64); w >= 125 {
				return
			}
		case <-deadline:
			t.Fatal("restored watched time never reached the monitor")
		}
	}
}

func TestMonitorMessagesAreIgnoredAsProgress(t *testing.T) {
	store := newFakeStore()
	h := newTestHub(store)
	defer h.Stop()

	monitor := monitorClient(h, "a1")
	connect(t, h, monitor)
	drainFor(t, monitor, MsgSnapshot, time.Second)

	h.inbound <- clientMessage{client: monitor, message: InboundMessage{
		Type: MsgProgress, LectureID: "l1", PositionSeconds: 10,
		DurationSeconds: 600, WatchedDeltaSeconds: 10, Playing: true,
	}}

	time.Sleep(150 * time.Millisecond)
	if store.totalDelta("a1", "l1") != 0 {
		t.Fatal("monitor progress should never be recorded")
	}
}

func TestReconnectPreservesLectureAndWatchedTime(t *testing.T) {
	store := newFakeStore()
	h := newTestHub(store)
	defer h.Stop()

	monitor := monitorClient(h, "a1")
	connect(t, h, monitor)
	drainFor(t, monitor, MsgSnapshot, time.Second)

	first := studentClient(h, "s1", "أحمد")
	connect(t, h, first)
	for i := 1; i <= 3; i++ {
		h.inbound <- clientMessage{client: first, message: InboundMessage{
			Type: MsgProgress, LectureID: "l1", LectureTitle: "المشتقات",
			PositionSeconds: float64(i * 10), DurationSeconds: 600,
			WatchedDeltaSeconds: 10, Playing: true,
		}}
		drainFor(t, monitor, MsgActivity, time.Second)
	}

	h.unregister <- first
	offline := drainFor(t, monitor, MsgPresence, time.Second)
	if v, _ := offline["viewer"].(map[string]any); v["online"] != false {
		t.Fatal("expected offline after socket drop")
	}

	second := studentClient(h, "s1", "أحمد")
	connect(t, h, second)
	online := drainFor(t, monitor, MsgPresence, time.Second)
	viewer, _ := online["viewer"].(map[string]any)
	if viewer["online"] != true {
		t.Fatal("expected online after reconnect")
	}
	if viewer["lectureId"] != "l1" {
		t.Fatalf("reconnect lost the active lecture: %v", viewer["lectureId"])
	}
	if w, _ := viewer["watchedSeconds"].(float64); w < 30 {
		t.Fatalf("reconnect reset watched time to %v, expected >= 30", w)
	}

	h.inbound <- clientMessage{client: second, message: InboundMessage{
		Type: MsgProgress, LectureID: "l1", PositionSeconds: 40,
		DurationSeconds: 600, WatchedDeltaSeconds: 10, Playing: true,
	}}
	act := drainFor(t, monitor, MsgActivity, time.Second)
	viewer, _ = act["viewer"].(map[string]any)
	if w, _ := viewer["watchedSeconds"].(float64); w < 40 {
		t.Fatalf("watched time did not accumulate across reconnect: %v", w)
	}
}

func TestUnregisterBeforeReconnectDoesNotDropSession(t *testing.T) {
	store := newFakeStore()
	h := newTestHub(store)
	defer h.Stop()

	monitor := monitorClient(h, "a1")
	connect(t, h, monitor)
	drainFor(t, monitor, MsgSnapshot, time.Second)

	first := studentClient(h, "s1", "أحمد")
	connect(t, h, first)
	h.inbound <- clientMessage{client: first, message: InboundMessage{
		Type: MsgProgress, LectureID: "l1", LectureTitle: "المشتقات",
		PositionSeconds: 50, DurationSeconds: 600,
		WatchedDeltaSeconds: 50, Playing: true,
	}}
	drainFor(t, monitor, MsgActivity, time.Second)

	second := studentClient(h, "s1", "أحمد")
	h.unregister <- first
	connect(t, h, second)

	deadline := time.After(time.Second)
	for {
		select {
		case payload := <-monitor.send:
			var decoded map[string]any
			_ = json.Unmarshal(payload, &decoded)
			if decoded["type"] != MsgPresence && decoded["type"] != MsgActivity {
				continue
			}
			viewer, _ := decoded["viewer"].(map[string]any)
			if viewer["online"] == true && viewer["lectureId"] == "l1" {
				if w, _ := viewer["watchedSeconds"].(float64); w >= 50 {
					return
				}
			}
		case <-deadline:
			t.Fatal("session state was lost across an unregister/register race")
		}
	}
}

func TestHeartbeatKeepsSessionWithoutCountingProgress(t *testing.T) {
	store := newFakeStore()
	h := newTestHub(store)
	defer h.Stop()

	student := studentClient(h, "s1", "أحمد")
	connect(t, h, student)

	for i := 0; i < 3; i++ {
		h.inbound <- clientMessage{client: student, message: InboundMessage{
			Type: MsgHeartbeat,
		}}
	}

	time.Sleep(120 * time.Millisecond)
	if store.totalDelta("s1", "l1") != 0 {
		t.Fatal("heartbeat must not record progress")
	}
}

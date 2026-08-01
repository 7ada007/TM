package realtime

import (
	"encoding/json"
	"sort"
	"time"

	"github.com/tareeqmajdapp/backend/internal/logger"
	"github.com/tareeqmajdapp/backend/internal/models"
)

const (
	persistInterval  = 15 * time.Second
	inboundQueueSize = 512
	persistQueueSize = 128
	restoreQueueSize = 128
	staleAfter       = 2 * time.Minute
	sweepInterval    = 30 * time.Second
	completionRatio  = 0.95
)

type ProgressStore interface {
	UpsertBatch(updates []models.ProgressUpdate) error
	Get(userID, lectureID string) (*models.LectureProgress, error)
}

type clientMessage struct {
	client  *Client
	message InboundMessage
}

type restoreResult struct {
	userID    string
	lectureID string
	watched   float64
	duration  float64
	completed bool
	found     bool
}

type session struct {
	userID          string
	userName        string
	section         string
	connections     int
	online          bool
	connectedAt     time.Time
	lastSeen        time.Time
	offlineAt       time.Time
	lectureID       string
	lectureTitle    string
	lectureSubject  string
	playing         bool
	positionSeconds float64
	durationSeconds float64
	watchedSeconds  float64
	completed       bool
	startedAt       time.Time
	baseWatched     float64
	sessionWatched  float64
	pendingDelta    float64
	lastPersistedAt time.Time
	dirty           bool
}

type Hub struct {
	register   chan *Client
	unregister chan *Client
	inbound    chan clientMessage
	persist    chan []models.ProgressUpdate
	restored   chan restoreResult
	done       chan struct{}
	writerDone chan struct{}

	clients  map[*Client]struct{}
	monitors map[*Client]struct{}
	sessions map[string]*session

	store ProgressStore
}

func NewHub(store ProgressStore) *Hub {
	return &Hub{
		register:   make(chan *Client, 64),
		unregister: make(chan *Client, 64),
		inbound:    make(chan clientMessage, inboundQueueSize),
		persist:    make(chan []models.ProgressUpdate, persistQueueSize),
		restored:   make(chan restoreResult, restoreQueueSize),
		done:       make(chan struct{}),
		writerDone: make(chan struct{}),
		clients:    make(map[*Client]struct{}),
		monitors:   make(map[*Client]struct{}),
		sessions:   make(map[string]*session),
		store:      store,
	}
}

func (h *Hub) Run() {
	go h.writeLoop()

	persistTicker := time.NewTicker(persistInterval)
	sweepTicker := time.NewTicker(sweepInterval)
	defer func() {
		persistTicker.Stop()
		sweepTicker.Stop()
	}()

	for {
		select {
		case c := <-h.register:
			h.handleRegister(c)
		case c := <-h.unregister:
			h.handleUnregister(c)
		case m := <-h.inbound:
			h.handleInbound(m)
		case r := <-h.restored:
			h.applyRestore(r)
		case <-persistTicker.C:
			h.collect(false)
		case <-h.done:
			h.collect(true)
			close(h.persist)
			<-h.writerDone
			return
		case <-sweepTicker.C:
			h.sweepStale()
		}
	}
}

func (h *Hub) Stop() {
	close(h.done)
}

func (h *Hub) writeLoop() {
	defer close(h.writerDone)
	for batch := range h.persist {
		if h.store == nil || len(batch) == 0 {
			continue
		}
		if err := h.store.UpsertBatch(batch); err != nil {
			logger.Error("realtime: persist %d progress rows: %v", len(batch), err)
		}
	}
}

func (h *Hub) enqueuePersist(batch []models.ProgressUpdate) {
	if len(batch) == 0 {
		return
	}
	select {
	case h.persist <- batch:
	default:
		logger.Warn("realtime: persist queue saturated, dropping %d rows", len(batch))
	}
}

func (h *Hub) handleRegister(c *Client) {
	h.clients[c] = struct{}{}
	defer close(c.registered)

	if c.monitor {
		h.monitors[c] = struct{}{}
		h.sendSnapshot(c)
		return
	}

	now := time.Now().UTC()
	s, exists := h.sessions[c.userID]
	if !exists {
		s = &session{
			userID:      c.userID,
			userName:    c.userName,
			section:     c.section,
			connectedAt: now,
		}
		h.sessions[c.userID] = s
	}
	s.userName = c.userName
	s.section = c.section
	s.connections++
	s.online = true
	s.offlineAt = time.Time{}
	s.lastSeen = now

	h.broadcastViewer(MsgPresence, s)
}

func (h *Hub) handleUnregister(c *Client) {
	if _, ok := h.clients[c]; !ok {
		return
	}
	delete(h.clients, c)
	close(c.send)

	if c.monitor {
		delete(h.monitors, c)
		return
	}

	s, ok := h.sessions[c.userID]
	if !ok {
		return
	}
	s.connections--
	if s.connections > 0 {
		return
	}
	s.connections = 0

	now := time.Now().UTC()
	s.online = false
	s.playing = false
	s.offlineAt = now
	s.lastSeen = now
	h.enqueuePersist(h.drain(s))
	h.broadcastViewer(MsgPresence, s)
}

func (h *Hub) handleInbound(m clientMessage) {
	if m.client.monitor {
		return
	}
	s, ok := h.sessions[m.client.userID]
	if !ok {
		return
	}

	now := time.Now().UTC()
	s.lastSeen = now

	switch m.message.Type {
	case MsgHeartbeat:
		return

	case MsgStopped:
		s.playing = false
		h.enqueuePersist(h.drain(s))
		s.lectureID = ""
		s.lectureTitle = ""
		s.lectureSubject = ""
		s.positionSeconds = 0
		s.durationSeconds = 0
		s.baseWatched = 0
		s.sessionWatched = 0
		s.watchedSeconds = 0
		s.completed = false
		h.broadcastViewer(MsgActivity, s)

	case MsgProgress:
		if m.message.LectureID == "" {
			return
		}
		if s.lectureID != m.message.LectureID {
			h.enqueuePersist(h.drain(s))
			s.lectureID = m.message.LectureID
			s.baseWatched = 0
			s.sessionWatched = 0
			s.watchedSeconds = 0
			s.completed = false
			s.startedAt = now
			h.requestRestore(s.userID, s.lectureID)
		}

		s.lectureTitle = m.message.LectureTitle
		s.lectureSubject = m.message.LectureSubject
		s.playing = m.message.Playing
		s.positionSeconds = sanitize(m.message.PositionSeconds)
		if m.message.DurationSeconds > 0 {
			s.durationSeconds = m.message.DurationSeconds
		}

		delta := sanitize(m.message.WatchedDeltaSeconds)
		s.sessionWatched += delta
		s.watchedSeconds = s.baseWatched + s.sessionWatched
		s.pendingDelta += delta
		s.dirty = true

		if m.message.Completed || ratio(s.positionSeconds, s.durationSeconds) >= completionRatio {
			s.completed = true
		}

		h.broadcastViewer(MsgActivity, s)

		if s.completed || now.Sub(s.lastPersistedAt) >= persistInterval {
			h.enqueuePersist(h.drain(s))
		}
	}
}

func (h *Hub) requestRestore(userID, lectureID string) {
	if h.store == nil {
		return
	}
	go func() {
		row, err := h.store.Get(userID, lectureID)
		if err != nil {
			logger.Error("realtime: restore progress for %s: %v", userID, err)
			return
		}
		result := restoreResult{userID: userID, lectureID: lectureID}
		if row != nil {
			result.found = true
			result.watched = row.WatchedSeconds
			result.duration = row.DurationSeconds
			result.completed = row.Completed
		}
		select {
		case h.restored <- result:
		case <-h.done:
		}
	}()
}

func (h *Hub) applyRestore(r restoreResult) {
	if !r.found {
		return
	}
	s, ok := h.sessions[r.userID]
	if !ok || s.lectureID != r.lectureID {
		return
	}
	if r.watched > s.baseWatched {
		s.baseWatched = r.watched
	}
	s.watchedSeconds = s.baseWatched + s.sessionWatched
	if s.durationSeconds <= 0 && r.duration > 0 {
		s.durationSeconds = r.duration
	}
	if r.completed {
		s.completed = true
	}
	h.broadcastViewer(MsgActivity, s)
}

func (h *Hub) drain(s *session) []models.ProgressUpdate {
	if s.lectureID == "" || (!s.dirty && s.pendingDelta == 0) {
		return nil
	}
	update := models.ProgressUpdate{
		UserID:              s.userID,
		LectureID:           s.lectureID,
		LastPositionSeconds: s.positionSeconds,
		WatchedDeltaSeconds: s.pendingDelta,
		DurationSeconds:     s.durationSeconds,
		Completed:           s.completed,
		OccurredAt:          time.Now().UTC().Format(time.RFC3339),
	}
	s.pendingDelta = 0
	s.dirty = false
	s.lastPersistedAt = time.Now().UTC()
	return []models.ProgressUpdate{update}
}

func (h *Hub) collect(final bool) {
	updates := make([]models.ProgressUpdate, 0, len(h.sessions))
	for _, s := range h.sessions {
		updates = append(updates, h.drain(s)...)
	}
	if len(updates) == 0 {
		return
	}
	if final {
		if h.store != nil {
			if err := h.store.UpsertBatch(updates); err != nil {
				logger.Error("realtime: final flush of %d rows: %v", len(updates), err)
				return
			}
		}
		logger.Info("realtime: flushed %d progress rows on shutdown", len(updates))
		return
	}
	h.enqueuePersist(updates)
}

func (h *Hub) sweepStale() {
	cutoff := time.Now().UTC().Add(-staleAfter)
	for id, s := range h.sessions {
		if s.connections > 0 {
			continue
		}
		if s.offlineAt.IsZero() || s.offlineAt.After(cutoff) {
			continue
		}
		h.enqueuePersist(h.drain(s))
		delete(h.sessions, id)
	}
}

func sanitize(v float64) float64 {
	if v != v || v < 0 {
		return 0
	}
	return v
}

func ratio(position, duration float64) float64 {
	if duration <= 0 {
		return 0
	}
	r := position / duration
	if r > 1 {
		return 1
	}
	return r
}

func (h *Hub) viewerOf(s *session) Viewer {
	v := Viewer{
		UserID:          s.userID,
		UserName:        s.userName,
		Section:         s.section,
		Online:          s.online,
		LectureID:       s.lectureID,
		LectureTitle:    s.lectureTitle,
		LectureSubject:  s.lectureSubject,
		Playing:         s.playing && s.online,
		PositionSeconds: s.positionSeconds,
		DurationSeconds: s.durationSeconds,
		WatchedSeconds:  s.watchedSeconds,
		Percent:         ratio(s.positionSeconds, s.durationSeconds),
		Completed:       s.completed,
		LastSeenAt:      s.lastSeen.Format(time.RFC3339),
	}
	if !s.startedAt.IsZero() {
		v.StartedAt = s.startedAt.Format(time.RFC3339)
	}
	if !s.connectedAt.IsZero() {
		v.ConnectedAt = s.connectedAt.Format(time.RFC3339)
	}
	return v
}

func (h *Hub) sendSnapshot(c *Client) {
	viewers := make([]Viewer, 0, len(h.sessions))
	for _, s := range h.sessions {
		viewers = append(viewers, h.viewerOf(s))
	}
	sort.Slice(viewers, func(i, j int) bool {
		return viewers[i].UserName < viewers[j].UserName
	})

	payload, err := json.Marshal(SnapshotMessage{
		Type:       MsgSnapshot,
		Viewers:    viewers,
		ServerTime: time.Now().UTC().Format(time.RFC3339),
	})
	if err != nil {
		return
	}
	if !c.enqueue(payload) {
		logger.Warn("realtime: monitor %s send buffer full on snapshot", c.userID)
	}
}

func (h *Hub) broadcastViewer(kind string, s *session) {
	if len(h.monitors) == 0 {
		return
	}
	payload, err := json.Marshal(ViewerMessage{
		Type:   kind,
		Viewer: h.viewerOf(s),
	})
	if err != nil {
		return
	}
	for c := range h.monitors {
		if !c.enqueue(payload) {
			logger.Warn("realtime: dropping update for saturated monitor %s", c.userID)
		}
	}
}

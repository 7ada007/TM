package realtime

const (
	MsgProgress  = "progress"
	MsgStopped   = "stopped"
	MsgSnapshot  = "snapshot"
	MsgPresence  = "presence"
	MsgActivity  = "activity"
	MsgError     = "error"
	MsgHeartbeat = "heartbeat"
)

type Envelope struct {
	Type string `json:"type"`
}

type InboundMessage struct {
	Type                string  `json:"type"`
	LectureID           string  `json:"lectureId"`
	LectureTitle        string  `json:"lectureTitle"`
	LectureSubject      string  `json:"lectureSubject"`
	PositionSeconds     float64 `json:"positionSeconds"`
	DurationSeconds     float64 `json:"durationSeconds"`
	WatchedDeltaSeconds float64 `json:"watchedDeltaSeconds"`
	Playing             bool    `json:"playing"`
	Completed           bool    `json:"completed"`
}

type Viewer struct {
	UserID          string  `json:"userId"`
	UserName        string  `json:"userName"`
	Section         string  `json:"section"`
	Online          bool    `json:"online"`
	LectureID       string  `json:"lectureId,omitempty"`
	LectureTitle    string  `json:"lectureTitle,omitempty"`
	LectureSubject  string  `json:"lectureSubject,omitempty"`
	Playing         bool    `json:"playing"`
	PositionSeconds float64 `json:"positionSeconds"`
	DurationSeconds float64 `json:"durationSeconds"`
	WatchedSeconds  float64 `json:"watchedSeconds"`
	Percent         float64 `json:"percent"`
	Completed       bool    `json:"completed"`
	StartedAt       string  `json:"startedAt,omitempty"`
	LastSeenAt      string  `json:"lastSeenAt"`
	ConnectedAt     string  `json:"connectedAt,omitempty"`
}

type SnapshotMessage struct {
	Type       string   `json:"type"`
	Viewers    []Viewer `json:"viewers"`
	ServerTime string   `json:"serverTime"`
}

type ViewerMessage struct {
	Type   string `json:"type"`
	Viewer Viewer `json:"viewer"`
}

type ErrorMessage struct {
	Type    string `json:"type"`
	Message string `json:"message"`
}

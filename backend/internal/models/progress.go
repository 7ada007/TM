package models

type LectureProgress struct {
	UserID              string  `db:"user_id" json:"userId"`
	LectureID           string  `db:"lecture_id" json:"lectureId"`
	StartedAt           string  `db:"started_at" json:"startedAt"`
	LastPositionSeconds float64 `db:"last_position_seconds" json:"lastPositionSeconds"`
	WatchedSeconds      float64 `db:"watched_seconds" json:"watchedSeconds"`
	DurationSeconds     float64 `db:"duration_seconds" json:"durationSeconds"`
	Percent             float64 `db:"percent" json:"percent"`
	Completed           bool    `db:"completed" json:"completed"`
	CompletedAt         *string `db:"completed_at" json:"completedAt"`
	UpdatedAt           string  `db:"updated_at" json:"updatedAt"`
}

type ProgressUpdate struct {
	UserID              string
	LectureID           string
	LastPositionSeconds float64
	WatchedDeltaSeconds float64
	DurationSeconds     float64
	Completed           bool
	OccurredAt          string
}

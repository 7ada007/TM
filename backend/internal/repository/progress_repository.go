package repository

import (
	"database/sql"

	"github.com/jmoiron/sqlx"
	"github.com/tareeqmajdapp/backend/internal/models"
)

const CompletionThreshold = 0.95

const upsertProgressQuery = `
	INSERT INTO lecture_progress (
		user_id, lecture_id, started_at, last_position_seconds,
		watched_seconds, duration_seconds, percent, completed,
		completed_at, updated_at
	) VALUES (
		:user_id, :lecture_id, :occurred_at, :last_position_seconds,
		:watched_delta_seconds, :duration_seconds, :percent, :completed,
		CASE WHEN :completed THEN :occurred_at ELSE NULL END, :occurred_at
	)
	ON CONFLICT (user_id, lecture_id) DO UPDATE SET
		last_position_seconds = excluded.last_position_seconds,
		watched_seconds       = lecture_progress.watched_seconds + :watched_delta_seconds,
		duration_seconds      = CASE
			WHEN excluded.duration_seconds > 0 THEN excluded.duration_seconds
			ELSE lecture_progress.duration_seconds
		END,
		percent = CASE
			WHEN excluded.duration_seconds > 0
				THEN MIN(1.0, excluded.last_position_seconds / excluded.duration_seconds)
			WHEN lecture_progress.duration_seconds > 0
				THEN MIN(1.0, excluded.last_position_seconds / lecture_progress.duration_seconds)
			ELSE lecture_progress.percent
		END,
		completed = CASE
			WHEN lecture_progress.completed OR excluded.completed THEN 1
			ELSE 0
		END,
		completed_at = CASE
			WHEN lecture_progress.completed_at IS NOT NULL THEN lecture_progress.completed_at
			WHEN excluded.completed THEN excluded.updated_at
			ELSE NULL
		END,
		updated_at = excluded.updated_at`

type namedExecutor interface {
	NamedExec(query string, arg any) (sql.Result, error)
}

type ProgressRepository struct {
	db *sqlx.DB
}

func NewProgressRepository(db *sqlx.DB) *ProgressRepository {
	return &ProgressRepository{db: db}
}

func progressArgs(u models.ProgressUpdate) map[string]any {
	percent := 0.0
	if u.DurationSeconds > 0 {
		percent = u.LastPositionSeconds / u.DurationSeconds
		if percent > 1 {
			percent = 1
		}
	}
	completed := u.Completed || (u.DurationSeconds > 0 && percent >= CompletionThreshold)

	delta := u.WatchedDeltaSeconds
	if delta < 0 {
		delta = 0
	}

	position := u.LastPositionSeconds
	if position < 0 {
		position = 0
	}

	return map[string]any{
		"user_id":               u.UserID,
		"lecture_id":            u.LectureID,
		"occurred_at":           u.OccurredAt,
		"last_position_seconds": position,
		"watched_delta_seconds": delta,
		"duration_seconds":      u.DurationSeconds,
		"percent":               percent,
		"completed":             completed,
	}
}

func upsertProgress(ex namedExecutor, u models.ProgressUpdate) error {
	_, err := ex.NamedExec(upsertProgressQuery, progressArgs(u))
	return err
}

func (r *ProgressRepository) Upsert(u models.ProgressUpdate) error {
	return upsertProgress(r.db, u)
}

func (r *ProgressRepository) UpsertBatch(updates []models.ProgressUpdate) error {
	if len(updates) == 0 {
		return nil
	}
	if len(updates) == 1 {
		return upsertProgress(r.db, updates[0])
	}

	tx, err := r.db.Beginx()
	if err != nil {
		return err
	}
	defer tx.Rollback()

	for _, u := range updates {
		if err := upsertProgress(tx, u); err != nil {
			return err
		}
	}
	return tx.Commit()
}

func (r *ProgressRepository) Get(userID, lectureID string) (*models.LectureProgress, error) {
	var p models.LectureProgress
	err := r.db.Get(&p,
		"SELECT * FROM lecture_progress WHERE user_id = ? AND lecture_id = ?",
		userID, lectureID)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}
	return &p, nil
}

func (r *ProgressRepository) List() ([]models.LectureProgress, error) {
	rows := []models.LectureProgress{}
	err := r.db.Select(&rows, "SELECT * FROM lecture_progress ORDER BY updated_at DESC")
	return rows, err
}

func (r *ProgressRepository) ListByUser(userID string) ([]models.LectureProgress, error) {
	rows := []models.LectureProgress{}
	err := r.db.Select(&rows,
		"SELECT * FROM lecture_progress WHERE user_id = ? ORDER BY updated_at DESC",
		userID)
	return rows, err
}

func (r *ProgressRepository) ListByLecture(lectureID string) ([]models.LectureProgress, error) {
	rows := []models.LectureProgress{}
	err := r.db.Select(&rows,
		"SELECT * FROM lecture_progress WHERE lecture_id = ? ORDER BY updated_at DESC",
		lectureID)
	return rows, err
}

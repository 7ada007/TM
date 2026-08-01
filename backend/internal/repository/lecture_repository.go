package repository

import (
	"database/sql"

	"github.com/jmoiron/sqlx"
	"github.com/tareeqmajdapp/backend/internal/models"
)

type LectureRepository struct {
	db *sqlx.DB
}

func NewLectureRepository(db *sqlx.DB) *LectureRepository {
	return &LectureRepository{db: db}
}

func (r *LectureRepository) Create(l *models.Lecture) error {
	const query = `
		INSERT INTO lectures (
			id, title, description, subject, section, teacher_id, teacher_name,
			video_path, cover_image_path, date, published_at, duration,
			file_size_bytes, is_published, created_at
		) VALUES (
			:id, :title, :description, :subject, :section, :teacher_id, :teacher_name,
			:video_path, :cover_image_path, :date, :published_at, :duration,
			:file_size_bytes, :is_published, :created_at
		)`
	_, err := r.db.NamedExec(query, l)
	return err
}

func (r *LectureRepository) GetByID(id string) (*models.Lecture, error) {
	var l models.Lecture
	err := r.db.Get(&l, "SELECT * FROM lectures WHERE id = ?", id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}
	return &l, nil
}

func (r *LectureRepository) List() ([]models.Lecture, error) {
	var lectures []models.Lecture
	err := r.db.Select(&lectures, "SELECT * FROM lectures ORDER BY created_at DESC")
	return lectures, err
}

func (r *LectureRepository) Update(l *models.Lecture) error {
	const query = `
		UPDATE lectures SET
			title = :title,
			description = :description,
			subject = :subject,
			section = :section,
			teacher_id = :teacher_id,
			teacher_name = :teacher_name,
			video_path = :video_path,
			cover_image_path = :cover_image_path,
			date = :date,
			published_at = :published_at,
			duration = :duration,
			file_size_bytes = :file_size_bytes,
			is_published = :is_published
		WHERE id = :id`
	_, err := r.db.NamedExec(query, l)
	return err
}

func (r *LectureRepository) Delete(id string) error {
	_, err := r.db.Exec("DELETE FROM lectures WHERE id = ?", id)
	return err
}

type CommentRepository struct {
	db *sqlx.DB
}

func NewCommentRepository(db *sqlx.DB) *CommentRepository {
	return &CommentRepository{db: db}
}

func (r *CommentRepository) Create(c *models.Comment) error {
	const query = `
		INSERT INTO comments (id, lecture_id, user_id, user_name, user_photo_path, content, created_at)
		VALUES (:id, :lecture_id, :user_id, :user_name, :user_photo_path, :content, :created_at)`
	_, err := r.db.NamedExec(query, c)
	return err
}

func (r *CommentRepository) List() ([]models.Comment, error) {
	var comments []models.Comment
	err := r.db.Select(&comments, "SELECT * FROM comments ORDER BY created_at ASC")
	return comments, err
}

func (r *CommentRepository) ListByLecture(lectureID string) ([]models.Comment, error) {
	var comments []models.Comment
	err := r.db.Select(&comments, "SELECT * FROM comments WHERE lecture_id = ? ORDER BY created_at ASC", lectureID)
	return comments, err
}

func (r *CommentRepository) GetByID(id string) (*models.Comment, error) {
	var c models.Comment
	err := r.db.Get(&c, "SELECT * FROM comments WHERE id = ?", id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}
	return &c, nil
}

func (r *CommentRepository) Update(c *models.Comment) error {
	const query = `
		UPDATE comments SET
			content = :content,
			updated_at = :updated_at,
			is_edited = :is_edited
		WHERE id = :id`
	_, err := r.db.NamedExec(query, c)
	return err
}

func (r *CommentRepository) Delete(id string) error {
	_, err := r.db.Exec("DELETE FROM comments WHERE id = ?", id)
	return err
}

type RatingRepository struct {
	db *sqlx.DB
}

func NewRatingRepository(db *sqlx.DB) *RatingRepository {
	return &RatingRepository{db: db}
}

func (r *RatingRepository) Upsert(rating *models.LectureRating) error {
	const query = `
		INSERT INTO lecture_ratings (id, lecture_id, user_id, stars, created_at)
		VALUES (:id, :lecture_id, :user_id, :stars, :created_at)
		ON CONFLICT (lecture_id, user_id) DO UPDATE SET
			stars = excluded.stars,
			created_at = excluded.created_at`
	_, err := r.db.NamedExec(query, rating)
	return err
}

func (r *RatingRepository) List() ([]models.LectureRating, error) {
	var ratings []models.LectureRating
	err := r.db.Select(&ratings, "SELECT * FROM lecture_ratings ORDER BY created_at ASC")
	return ratings, err
}

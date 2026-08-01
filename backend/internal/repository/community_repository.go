package repository

import (
	"database/sql"
	"fmt"

	"github.com/jmoiron/sqlx"
	"github.com/tareeqmajdapp/backend/internal/models"
)

type CommunityRepository struct {
	db *sqlx.DB
}

func NewCommunityRepository(db *sqlx.DB) *CommunityRepository {
	return &CommunityRepository{db: db}
}

func (r *CommunityRepository) CreatePost(p *models.CommunityPost) error {
	const query = `
		INSERT INTO community_posts (
			id, user_id, user_name, user_photo_path, title, content,
			image_path, video_path, is_pinned, created_at, updated_at
		) VALUES (
			:id, :user_id, :user_name, :user_photo_path, :title, :content,
			:image_path, :video_path, :is_pinned, :created_at, :updated_at
		)`
	_, err := r.db.NamedExec(query, p)
	return err
}

const listPostsQuery = `
	SELECT p.*, COUNT(c.id) AS comment_count
	FROM community_posts p
	LEFT JOIN community_comments c ON c.post_id = p.id
	JOIN users u ON u.id = p.user_id
	%s
	GROUP BY p.id
	ORDER BY p.is_pinned DESC, p.created_at DESC`

func (r *CommunityRepository) ListPosts(studentGender *string) ([]models.CommunityPost, error) {
	var posts []models.CommunityPost
	if studentGender != nil {
		query := fmt.Sprintf(listPostsQuery, "WHERE (u.role != 'student' OR u.gender = ?)")
		err := r.db.Select(&posts, query, *studentGender)
		return posts, err
	}
	query := fmt.Sprintf(listPostsQuery, "")
	err := r.db.Select(&posts, query)
	return posts, err
}

func (r *CommunityRepository) GetPost(id string) (*models.CommunityPost, error) {
	var p models.CommunityPost
	query := fmt.Sprintf(listPostsQuery, "WHERE p.id = ?")
	err := r.db.Get(&p, query, id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}
	return &p, nil
}

func (r *CommunityRepository) UpdatePost(p *models.CommunityPost) error {
	const query = `
		UPDATE community_posts SET
			title = :title,
			content = :content,
			image_path = :image_path,
			video_path = :video_path,
			is_pinned = :is_pinned,
			updated_at = :updated_at
		WHERE id = :id`
	_, err := r.db.NamedExec(query, p)
	return err
}

func (r *CommunityRepository) DeletePost(id string) error {
	_, err := r.db.Exec("DELETE FROM community_posts WHERE id = ?", id)
	return err
}

func (r *CommunityRepository) CreateComment(c *models.CommunityComment) error {
	const query = `
		INSERT INTO community_comments (id, post_id, user_id, user_name, user_photo_path, content, created_at)
		VALUES (:id, :post_id, :user_id, :user_name, :user_photo_path, :content, :created_at)`
	_, err := r.db.NamedExec(query, c)
	return err
}

func (r *CommunityRepository) ListComments(postID string) ([]models.CommunityComment, error) {
	var comments []models.CommunityComment
	err := r.db.Select(&comments, "SELECT * FROM community_comments WHERE post_id = ? ORDER BY created_at ASC", postID)
	return comments, err
}

func (r *CommunityRepository) DeleteComment(id string) error {
	_, err := r.db.Exec("DELETE FROM community_comments WHERE id = ?", id)
	return err
}

func (r *CommunityRepository) CreateReport(rep *models.CommunityReport) error {
	const query = `
		INSERT INTO community_reports (id, post_id, reported_by, reason, status, created_at)
		VALUES (:id, :post_id, :reported_by, :reason, :status, :created_at)`
	_, err := r.db.NamedExec(query, rep)
	return err
}

func (r *CommunityRepository) ListOpenReports() ([]models.CommunityReport, error) {
	var reports []models.CommunityReport
	err := r.db.Select(&reports, "SELECT * FROM community_reports WHERE status = 'open' ORDER BY created_at DESC")
	return reports, err
}

func (r *CommunityRepository) UpdateReportStatus(id string, status models.ReportStatus) error {
	_, err := r.db.Exec("UPDATE community_reports SET status = ? WHERE id = ?", status, id)
	return err
}

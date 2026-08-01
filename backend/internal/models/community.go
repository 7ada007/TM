package models

type CommunityPost struct {
	ID            string  `db:"id" json:"id"`
	UserID        string  `db:"user_id" json:"userId"`
	UserName      string  `db:"user_name" json:"userName"`
	UserPhotoPath *string `db:"user_photo_path" json:"userPhotoPath"`
	Title         *string `db:"title" json:"title"`
	Content       string  `db:"content" json:"content"`
	ImagePath     *string `db:"image_path" json:"imagePath"`
	VideoPath     *string `db:"video_path" json:"videoPath"`
	IsPinned      bool    `db:"is_pinned" json:"isPinned"`
	CreatedAt     string  `db:"created_at" json:"createdAt"`
	UpdatedAt     *string `db:"updated_at" json:"updatedAt"`

	CommentCount int `db:"comment_count" json:"commentCount"`
}

type CommunityComment struct {
	ID            string  `db:"id" json:"id"`
	PostID        string  `db:"post_id" json:"postId"`
	UserID        string  `db:"user_id" json:"userId"`
	UserName      string  `db:"user_name" json:"userName"`
	UserPhotoPath *string `db:"user_photo_path" json:"userPhotoPath"`
	Content       string  `db:"content" json:"content"`
	CreatedAt     string  `db:"created_at" json:"createdAt"`
}

type ReportStatus string

const (
	ReportOpen      ReportStatus = "open"
	ReportDismissed ReportStatus = "dismissed"
	ReportResolved  ReportStatus = "resolved"
)

type CommunityReport struct {
	ID         string       `db:"id" json:"id"`
	PostID     string       `db:"post_id" json:"postId"`
	ReportedBy string       `db:"reported_by" json:"reportedBy"`
	Reason     *string      `db:"reason" json:"reason"`
	Status     ReportStatus `db:"status" json:"status"`
	CreatedAt  string       `db:"created_at" json:"createdAt"`
}

package models

type Lecture struct {
	ID             string  `db:"id" json:"id"`
	Title          string  `db:"title" json:"title"`
	Description    string  `db:"description" json:"description"`
	Subject        string  `db:"subject" json:"subject"`
	Section        string  `db:"section" json:"section"`
	TeacherID      string  `db:"teacher_id" json:"teacherId"`
	TeacherName    string  `db:"teacher_name" json:"teacherName"`
	VideoPath      string  `db:"video_path" json:"videoPath"`
	CoverImagePath *string `db:"cover_image_path" json:"coverImagePath"`
	Date           string  `db:"date" json:"date"`
	PublishedAt    *string `db:"published_at" json:"publishedAt"`
	Duration       *string `db:"duration" json:"duration"`
	FileSizeBytes  int64   `db:"file_size_bytes" json:"fileSizeBytes"`
	IsPublished    bool    `db:"is_published" json:"isPublished"`
	CreatedAt      string  `db:"created_at" json:"-"`
}

type Comment struct {
	ID            string  `db:"id" json:"id"`
	LectureID     string  `db:"lecture_id" json:"lectureId"`
	UserID        string  `db:"user_id" json:"userId"`
	UserName      string  `db:"user_name" json:"userName"`
	UserPhotoPath *string `db:"user_photo_path" json:"userPhotoPath"`
	Content       string  `db:"content" json:"content"`
	CreatedAt     string  `db:"created_at" json:"createdAt"`
	UpdatedAt     *string `db:"updated_at" json:"updatedAt"`
	IsEdited      bool    `db:"is_edited" json:"isEdited"`
}

type LectureRating struct {
	ID        string `db:"id" json:"id"`
	LectureID string `db:"lecture_id" json:"lectureId"`
	UserID    string `db:"user_id" json:"userId"`
	Stars     int    `db:"stars" json:"stars"`
	CreatedAt string `db:"created_at" json:"createdAt"`
}

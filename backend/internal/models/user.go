package models

type Role string

const (
	RoleStudent Role = "student"
	RoleTeacher Role = "teacher"
	RoleAdmin   Role = "admin"
)

type User struct {
	ID                string  `db:"id" json:"id"`
	Name              string  `db:"name" json:"name"`
	Username          string  `db:"username" json:"username"`
	PasswordHash      string  `db:"password_hash" json:"-"`
	TokenVersion      int     `db:"token_version" json:"-"`
	Email             *string `db:"email" json:"email"`
	Phone             *string `db:"phone" json:"phone"`
	Section           *string `db:"section" json:"section"`
	GuardianName      *string `db:"guardian_name" json:"guardianName"`
	GuardianPhone     *string `db:"guardian_phone" json:"guardianPhone"`
	Gender            string  `db:"gender" json:"gender"`
	SubjectsJSON      string  `db:"subjects" json:"-"`
	Notes             *string `db:"notes" json:"notes"`
	PhotoPath         *string `db:"photo_path" json:"photoPath"`
	SchoolName        *string `db:"school_name" json:"schoolName"`
	Bio               *string `db:"bio" json:"bio"`
	LastNameChangeAt  *string `db:"last_name_change_at" json:"lastNameChangeAt"`
	Role              Role    `db:"role" json:"role"`
	CanUploadLectures bool    `db:"can_upload_lectures" json:"canUploadLectures"`
	CreatedAt         string  `db:"created_at" json:"createdAt"`

	Subjects []string `db:"-" json:"subjects"`
}

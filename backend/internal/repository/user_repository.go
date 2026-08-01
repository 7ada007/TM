package repository

import (
	"database/sql"
	"encoding/json"
	"fmt"

	"github.com/jmoiron/sqlx"
	"github.com/tareeqmajdapp/backend/internal/models"
)

type UserRepository struct {
	db *sqlx.DB
}

func NewUserRepository(db *sqlx.DB) *UserRepository {
	return &UserRepository{db: db}
}

func decodeSubjects(u *models.User) {
	if u.SubjectsJSON == "" {
		u.Subjects = []string{}
		return
	}
	var subjects []string
	if err := json.Unmarshal([]byte(u.SubjectsJSON), &subjects); err != nil {
		u.Subjects = []string{}
		return
	}
	u.Subjects = subjects
}

func encodeSubjects(u *models.User) error {
	if u.Subjects == nil {
		u.SubjectsJSON = "[]"
		return nil
	}
	b, err := json.Marshal(u.Subjects)
	if err != nil {
		return fmt.Errorf("encode subjects: %w", err)
	}
	u.SubjectsJSON = string(b)
	return nil
}

func (r *UserRepository) Create(u *models.User) error {
	if err := encodeSubjects(u); err != nil {
		return err
	}
	const query = `
		INSERT INTO users (
			id, name, username, password_hash, token_version, email, phone,
			section, guardian_name, guardian_phone, gender, subjects, notes,
			photo_path, school_name, bio, last_name_change_at, role,
			can_upload_lectures, created_at
		) VALUES (
			:id, :name, :username, :password_hash, :token_version, :email, :phone,
			:section, :guardian_name, :guardian_phone, :gender, :subjects, :notes,
			:photo_path, :school_name, :bio, :last_name_change_at, :role,
			:can_upload_lectures, :created_at
		)`
	_, err := r.db.NamedExec(query, u)
	return err
}

func (r *UserRepository) GetByID(id string) (*models.User, error) {
	var u models.User
	err := r.db.Get(&u, "SELECT * FROM users WHERE id = ?", id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}
	decodeSubjects(&u)
	return &u, nil
}

func (r *UserRepository) GetByUsername(username string) (*models.User, error) {
	var u models.User
	err := r.db.Get(&u, "SELECT * FROM users WHERE username = ? COLLATE NOCASE", username)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}
	decodeSubjects(&u)
	return &u, nil
}

func (r *UserRepository) List() ([]models.User, error) {
	var users []models.User
	if err := r.db.Select(&users, "SELECT * FROM users ORDER BY created_at DESC"); err != nil {
		return nil, err
	}
	for i := range users {
		decodeSubjects(&users[i])
	}
	return users, nil
}

func (r *UserRepository) ListForStudentView(callerGender string) ([]models.User, error) {
	var users []models.User
	const query = `
		SELECT * FROM users
		WHERE role IN ('teacher', 'admin')
		   OR (role = 'student' AND gender = ?)
		ORDER BY created_at DESC`
	if err := r.db.Select(&users, query, callerGender); err != nil {
		return nil, err
	}
	for i := range users {
		decodeSubjects(&users[i])
	}
	return users, nil
}

func (r *UserRepository) Classmates(gender string, section *string) ([]models.User, error) {
	var users []models.User
	query := `SELECT * FROM users WHERE role = 'student' AND gender = ?`
	args := []any{gender}
	if section != nil && *section != "" {
		query += ` AND section = ?`
		args = append(args, *section)
	}
	query += ` ORDER BY name COLLATE NOCASE ASC`
	if err := r.db.Select(&users, query, args...); err != nil {
		return nil, err
	}
	for i := range users {
		decodeSubjects(&users[i])
	}
	return users, nil
}

func (r *UserRepository) Update(u *models.User) error {
	if err := encodeSubjects(u); err != nil {
		return err
	}
	const query = `
		UPDATE users SET
			name = :name,
			username = :username,
			email = :email,
			phone = :phone,
			section = :section,
			guardian_name = :guardian_name,
			guardian_phone = :guardian_phone,
			gender = :gender,
			subjects = :subjects,
			notes = :notes,
			photo_path = :photo_path,
			school_name = :school_name,
			bio = :bio,
			last_name_change_at = :last_name_change_at,
			role = :role,
			can_upload_lectures = :can_upload_lectures
		WHERE id = :id`
	_, err := r.db.NamedExec(query, u)
	return err
}

func (r *UserRepository) UpdatePassword(userID, newPasswordHash string) error {
	const query = `
		UPDATE users
		SET password_hash = ?, token_version = token_version + 1
		WHERE id = ?`
	_, err := r.db.Exec(query, newPasswordHash, userID)
	return err
}

func (r *UserRepository) Delete(id string) error {
	_, err := r.db.Exec("DELETE FROM users WHERE id = ?", id)
	return err
}

func (r *UserRepository) UsernameTaken(username, excludeUserID string) (bool, error) {
	var count int
	err := r.db.Get(&count,
		"SELECT COUNT(*) FROM users WHERE username = ? COLLATE NOCASE AND id != ?",
		username, excludeUserID,
	)
	return count > 0, err
}

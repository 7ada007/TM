package repository

import (
	"database/sql"

	"github.com/jmoiron/sqlx"
	"github.com/tareeqmajdapp/backend/internal/models"
)

type AttendanceRepository struct {
	db *sqlx.DB
}

func NewAttendanceRepository(db *sqlx.DB) *AttendanceRepository {
	return &AttendanceRepository{db: db}
}

func (r *AttendanceRepository) Create(a *models.AttendanceRecord) error {
	const query = `
		INSERT INTO attendance_records (
			id, student_id, student_name, section, subject, date, status,
			recorded_by, recorded_by_name, recorded_at
		) VALUES (
			:id, :student_id, :student_name, :section, :subject, :date, :status,
			:recorded_by, :recorded_by_name, :recorded_at
		)`
	_, err := r.db.NamedExec(query, a)
	return err
}

func (r *AttendanceRepository) GetByID(id string) (*models.AttendanceRecord, error) {
	var a models.AttendanceRecord
	err := r.db.Get(&a, "SELECT * FROM attendance_records WHERE id = ?", id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}
	return &a, nil
}

func (r *AttendanceRepository) List() ([]models.AttendanceRecord, error) {
	var records []models.AttendanceRecord
	err := r.db.Select(&records, "SELECT * FROM attendance_records ORDER BY date DESC")
	return records, err
}

func (r *AttendanceRepository) Update(a *models.AttendanceRecord) error {
	const query = `
		UPDATE attendance_records SET
			student_name = :student_name,
			section = :section,
			subject = :subject,
			date = :date,
			status = :status,
			recorded_by = :recorded_by,
			recorded_by_name = :recorded_by_name,
			recorded_at = :recorded_at
		WHERE id = :id`
	_, err := r.db.NamedExec(query, a)
	return err
}

func (r *AttendanceRepository) Delete(id string) error {
	_, err := r.db.Exec("DELETE FROM attendance_records WHERE id = ?", id)
	return err
}

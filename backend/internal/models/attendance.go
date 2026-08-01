package models

type AttendanceStatus string

const (
	AttendancePresent AttendanceStatus = "present"
	AttendanceAbsent  AttendanceStatus = "absent"
	AttendanceExcused AttendanceStatus = "excused"
)

type AttendanceRecord struct {
	ID             string           `db:"id" json:"id"`
	StudentID      string           `db:"student_id" json:"studentId"`
	StudentName    string           `db:"student_name" json:"studentName"`
	Section        string           `db:"section" json:"section"`
	Subject        *string          `db:"subject" json:"subject"`
	Date           string           `db:"date" json:"date"`
	Status         AttendanceStatus `db:"status" json:"status"`
	RecordedBy     string           `db:"recorded_by" json:"recordedBy"`
	RecordedByName string           `db:"recorded_by_name" json:"recordedByName"`
	RecordedAt     string           `db:"recorded_at" json:"recordedAt"`
}

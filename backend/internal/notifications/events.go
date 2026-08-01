package notifications

import (
	"fmt"
	"strings"

	"github.com/tareeqmajdapp/backend/internal/logger"
	"github.com/tareeqmajdapp/backend/internal/models"
	"github.com/tareeqmajdapp/backend/internal/repository"
)

// Audience resolves who should hear about an event.
//
// Kept behind an interface so the notifier can be tested without a database,
// and so the targeting rules live in one place rather than being re-derived at
// each call site.
type Audience interface {
	// StudentsForLecture returns the IDs of students who take the given
	// subject in the given section.
	StudentsForLecture(subject, section string) ([]string, error)
	// AllStudents returns every student ID — used for institute-wide notices.
	AllStudents() ([]string, error)
	// Everyone returns every account, used for announcements that also concern
	// staff.
	Everyone() ([]string, error)
	// StaffForSubject returns admins plus teachers assigned to a subject.
	StaffForSubject(subject string) ([]string, error)
}

// RepoAudience resolves audiences from the user table.
type RepoAudience struct {
	users *repository.UserRepository
}

func NewRepoAudience(users *repository.UserRepository) *RepoAudience {
	return &RepoAudience{users: users}
}

func (a *RepoAudience) StudentsForLecture(subject, section string) ([]string, error) {
	users, err := a.users.List()
	if err != nil {
		return nil, err
	}
	ids := make([]string, 0, len(users))
	for i := range users {
		u := &users[i]
		if u.Role != models.RoleStudent {
			continue
		}
		// A student only hears about a lecture that is actually theirs: right
		// section, and a subject on their timetable.
		if section != "" && (u.Section == nil || *u.Section != section) {
			continue
		}
		if subject != "" && !containsFold(u.Subjects, subject) {
			continue
		}
		ids = append(ids, u.ID)
	}
	return ids, nil
}

func (a *RepoAudience) AllStudents() ([]string, error) {
	return a.filter(func(u *models.User) bool { return u.Role == models.RoleStudent })
}

func (a *RepoAudience) Everyone() ([]string, error) {
	return a.filter(func(u *models.User) bool { return true })
}

func (a *RepoAudience) StaffForSubject(subject string) ([]string, error) {
	return a.filter(func(u *models.User) bool {
		if u.Role == models.RoleAdmin {
			return true
		}
		return u.Role == models.RoleTeacher && containsFold(u.Subjects, subject)
	})
}

func (a *RepoAudience) filter(keep func(*models.User) bool) ([]string, error) {
	users, err := a.users.List()
	if err != nil {
		return nil, err
	}
	ids := make([]string, 0, len(users))
	for i := range users {
		if keep(&users[i]) {
			ids = append(ids, users[i].ID)
		}
	}
	return ids, nil
}

func containsFold(haystack []string, needle string) bool {
	for _, item := range haystack {
		if strings.EqualFold(strings.TrimSpace(item), strings.TrimSpace(needle)) {
			return true
		}
	}
	return false
}

// Notifier turns academic events into addressed push notifications.
//
// Every method is fire-and-forget: audience resolution and delivery happen off
// the request goroutine, and any failure is logged rather than surfaced. A push
// that does not arrive must never stop a lecture from being published.
type Notifier struct {
	client   *Client
	audience Audience
}

func NewNotifier(client *Client, audience Audience) *Notifier {
	return &Notifier{client: client, audience: audience}
}

// Enabled reports whether notifications are configured in this environment.
func (n *Notifier) Enabled() bool {
	return n != nil && n.client.Enabled() && n.audience != nil
}

// dispatch resolves an audience and sends, entirely in the background.
func (n *Notifier) dispatch(describe string, resolve func() ([]string, error), build func([]string) Message) {
	if !n.Enabled() {
		return
	}
	go func() {
		recipients, err := resolve()
		if err != nil {
			logger.Warn("Push notification (%s): could not resolve audience: %v", describe, err)
			return
		}
		if len(recipients) == 0 {
			return
		}
		n.client.SendAsync(build(recipients), describe)
	}()
}

// excluding removes one user — normally the actor — from an audience, so
// nobody is notified about their own action.
func excluding(ids []string, exclude string) []string {
	if exclude == "" {
		return ids
	}
	out := make([]string, 0, len(ids))
	for _, id := range ids {
		if id != exclude {
			out = append(out, id)
		}
	}
	return out
}

// LecturePublished announces a newly published lecture to the students who
// take it.
func (n *Notifier) LecturePublished(lecture *models.Lecture) {
	if lecture == nil || !lecture.IsPublished {
		return
	}
	n.dispatch("new lecture", func() ([]string, error) {
		ids, err := n.audience.StudentsForLecture(lecture.Subject, lecture.Section)
		if err != nil {
			return nil, err
		}
		// The uploader does not need to be told about their own upload.
		return excluding(ids, lecture.TeacherID), nil
	}, func(recipients []string) Message {
		body := lecture.Title
		if lecture.TeacherName != "" {
			body = fmt.Sprintf("%s — %s", lecture.Title, lecture.TeacherName)
		}
		return Message{
			Recipients: recipients,
			Title:      fmt.Sprintf("محاضرة جديدة في %s", lecture.Subject),
			Body:       body,
			Route:      "/lecture/" + lecture.ID,
			Group:      "lectures",
		}
	})
}

// LectureUpdated tells students that a lecture they have already seen has
// changed materially.
func (n *Notifier) LectureUpdated(lecture *models.Lecture, actorID string) {
	if lecture == nil || !lecture.IsPublished {
		return
	}
	n.dispatch("lecture updated", func() ([]string, error) {
		ids, err := n.audience.StudentsForLecture(lecture.Subject, lecture.Section)
		if err != nil {
			return nil, err
		}
		return excluding(ids, actorID), nil
	}, func(recipients []string) Message {
		return Message{
			Recipients: recipients,
			Title:      fmt.Sprintf("تحديث محاضرة %s", lecture.Subject),
			Body:       fmt.Sprintf("تم تحديث «%s»، اطّلع على الجديد", lecture.Title),
			Route:      "/lecture/" + lecture.ID,
			Group:      "lectures",
		}
	})
}

// Announcement notifies the institute about a pinned community post.
//
// Pinning is what distinguishes an announcement from ordinary community
// chatter, so only pinned posts reach everyone.
func (n *Notifier) Announcement(post *models.CommunityPost, actorID string) {
	if post == nil || !post.IsPinned {
		return
	}
	n.dispatch("announcement", func() ([]string, error) {
		ids, err := n.audience.Everyone()
		if err != nil {
			return nil, err
		}
		return excluding(ids, actorID), nil
	}, func(recipients []string) Message {
		title := "إعلان من إدارة المعهد"
		if post.Title != nil && strings.TrimSpace(*post.Title) != "" {
			title = strings.TrimSpace(*post.Title)
		}
		return Message{
			Recipients: recipients,
			Title:      title,
			Body:       summarize(post.Content, 160),
			Route:      "/home",
			Group:      "announcements",
		}
	})
}

// MaterialShared notifies students when staff post study material — a
// community post carrying a file — to the community feed.
func (n *Notifier) MaterialShared(post *models.CommunityPost, actorRole models.Role, actorID string) {
	if post == nil {
		return
	}
	// Only staff uploads count as material; a student sharing a photo is not an
	// academic event worth paging everyone about.
	if actorRole != models.RoleAdmin && actorRole != models.RoleTeacher {
		return
	}
	hasAttachment := (post.ImagePath != nil && *post.ImagePath != "") ||
		(post.VideoPath != nil && *post.VideoPath != "")
	if !hasAttachment || post.IsPinned {
		// Pinned posts already go out as announcements; do not double-notify.
		return
	}

	n.dispatch("study material", func() ([]string, error) {
		ids, err := n.audience.AllStudents()
		if err != nil {
			return nil, err
		}
		return excluding(ids, actorID), nil
	}, func(recipients []string) Message {
		label := "ملف جديد"
		if post.VideoPath != nil && *post.VideoPath != "" {
			label = "مقطع جديد"
		}
		body := summarize(post.Content, 140)
		if post.Title != nil && strings.TrimSpace(*post.Title) != "" {
			body = strings.TrimSpace(*post.Title)
		}
		return Message{
			Recipients: recipients,
			Title:      fmt.Sprintf("%s من %s", label, post.UserName),
			Body:       body,
			Route:      "/home",
			Group:      "materials",
		}
	})
}

// AttendanceRecorded tells a student when they are marked absent.
//
// Only absences and excused absences are sent: a notification for every
// present mark would be noise that trains people to ignore the channel.
func (n *Notifier) AttendanceRecorded(record *models.AttendanceRecord) {
	if record == nil || record.Status == "present" {
		return
	}
	n.dispatch("attendance", func() ([]string, error) {
		return []string{record.StudentID}, nil
	}, func(recipients []string) Message {
		title := "تسجيل غياب"
		body := fmt.Sprintf("سُجّل غيابك بتاريخ %s", record.Date)
		if record.Status == "excused" {
			title = "غياب بعذر"
			body = fmt.Sprintf("سُجّل غيابك بعذر بتاريخ %s", record.Date)
		}
		if record.Subject != nil && strings.TrimSpace(*record.Subject) != "" {
			body = fmt.Sprintf("%s — %s", body, strings.TrimSpace(*record.Subject))
		}
		return Message{
			Recipients: recipients,
			Title:      title,
			Body:       body,
			Route:      "/home",
			Group:      "attendance",
		}
	})
}

// summarize trims a body of text to a notification-sized excerpt, cutting on a
// word boundary so the preview does not end mid-word.
func summarize(text string, limit int) string {
	clean := strings.Join(strings.Fields(text), " ")
	if clean == "" {
		return "اضغط للاطلاع على التفاصيل"
	}
	if len([]rune(clean)) <= limit {
		return clean
	}
	runes := []rune(clean)[:limit]
	cut := strings.LastIndex(string(runes), " ")
	if cut > limit/2 {
		return strings.TrimSpace(string(runes)[:cut]) + "…"
	}
	return strings.TrimSpace(string(runes)) + "…"
}

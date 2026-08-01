package notifications

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/tareeqmajdapp/backend/internal/models"
)

// captureServer stands in for OneSignal and records what was sent.
type captureServer struct {
	*httptest.Server
	mu       sync.Mutex
	payloads []map[string]any
	status   int
}

func newCaptureServer() *captureServer {
	cs := &captureServer{status: http.StatusOK}
	cs.Server = httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var body map[string]any
		_ = json.NewDecoder(r.Body).Decode(&body)
		body["_auth"] = r.Header.Get("Authorization")
		cs.mu.Lock()
		cs.payloads = append(cs.payloads, body)
		status := cs.status
		cs.mu.Unlock()
		w.WriteHeader(status)
		_, _ = w.Write([]byte(`{"id":"test"}`))
	}))
	return cs
}

func (cs *captureServer) sent() []map[string]any {
	cs.mu.Lock()
	defer cs.mu.Unlock()
	out := make([]map[string]any, len(cs.payloads))
	copy(out, cs.payloads)
	return out
}

// clientTo builds a client pointed at the fake server.
func clientTo(cs *captureServer) *Client {
	c := NewClient("app-id", "rest-key")
	c.http = cs.Client()
	c.endpoint = cs.URL
	return c
}

func recipientsOf(t *testing.T, payload map[string]any) []string {
	t.Helper()
	aliases, ok := payload["include_aliases"].(map[string]any)
	if !ok {
		t.Fatalf("payload has no include_aliases: %v", payload)
	}
	raw, ok := aliases["external_id"].([]any)
	if !ok {
		t.Fatalf("payload has no external_id list: %v", aliases)
	}
	out := make([]string, 0, len(raw))
	for _, v := range raw {
		out = append(out, v.(string))
	}
	return out
}

func TestSendAddressesExplicitUsers(t *testing.T) {
	cs := newCaptureServer()
	defer cs.Close()

	err := clientTo(cs).Send(context.Background(), Message{
		Recipients: []string{"u1", "u2", "u1", " ", "u3"},
		Title:      "عنوان",
		Body:       "نص",
		Route:      "/lecture/abc",
		Group:      "lectures",
	})
	if err != nil {
		t.Fatalf("send: %v", err)
	}

	sent := cs.sent()
	if len(sent) != 1 {
		t.Fatalf("expected 1 request, got %d", len(sent))
	}

	got := recipientsOf(t, sent[0])
	want := []string{"u1", "u2", "u3"}
	if strings.Join(got, ",") != strings.Join(want, ",") {
		t.Errorf("recipients = %v, want %v (duplicates and blanks must be dropped)", got, want)
	}

	if auth := sent[0]["_auth"]; auth != "Key rest-key" {
		t.Errorf("Authorization = %q, want %q", auth, "Key rest-key")
	}

	data, _ := sent[0]["data"].(map[string]any)
	if data["route"] != "/lecture/abc" {
		t.Errorf("route = %v, want /lecture/abc", data["route"])
	}
}

func TestSendRefusesEmptyAudienceAndBody(t *testing.T) {
	cs := newCaptureServer()
	defer cs.Close()

	c := clientTo(cs)

	// An empty audience must never become a broadcast.
	if err := c.Send(context.Background(), Message{Title: "t", Body: "b"}); err != nil {
		t.Fatalf("empty audience should be a silent no-op, got %v", err)
	}
	if len(cs.sent()) != 0 {
		t.Fatal("an empty audience must not produce a request")
	}

	if err := c.Send(context.Background(), Message{Recipients: []string{"u1"}, Title: "", Body: "b"}); err == nil {
		t.Error("expected an error for an empty title")
	}
	if len(cs.sent()) != 0 {
		t.Fatal("a malformed message must not be sent")
	}
}

func TestSendSplitsLargeAudiences(t *testing.T) {
	cs := newCaptureServer()
	defer cs.Close()

	recipients := make([]string, maxAliasesPerRequest+250)
	for i := range recipients {
		recipients[i] = "user-" + string(rune('a'+i%26)) + "-" + itoa(i)
	}

	if err := clientTo(cs).Send(context.Background(), Message{
		Recipients: recipients, Title: "t", Body: "b",
	}); err != nil {
		t.Fatalf("send: %v", err)
	}

	sent := cs.sent()
	if len(sent) != 2 {
		t.Fatalf("expected the audience to be split into 2 requests, got %d", len(sent))
	}
	if n := len(recipientsOf(t, sent[0])); n != maxAliasesPerRequest {
		t.Errorf("first batch = %d recipients, want %d", n, maxAliasesPerRequest)
	}
	if n := len(recipientsOf(t, sent[1])); n != 250 {
		t.Errorf("second batch = %d recipients, want 250", n)
	}
}

func TestDisabledClientIsANoOp(t *testing.T) {
	c := NewClient("app-id", "")
	if c.Enabled() {
		t.Fatal("a client without an API key must report itself disabled")
	}
	if err := c.Send(context.Background(), Message{Recipients: []string{"u1"}, Title: "t", Body: "b"}); err != nil {
		t.Errorf("a disabled client should drop messages silently, got %v", err)
	}
}

func TestSendSurfacesProviderErrors(t *testing.T) {
	cs := newCaptureServer()
	cs.status = http.StatusBadRequest
	defer cs.Close()

	err := clientTo(cs).Send(context.Background(), Message{
		Recipients: []string{"u1"}, Title: "t", Body: "b",
	})
	if err == nil || !strings.Contains(err.Error(), "400") {
		t.Errorf("expected the provider status in the error, got %v", err)
	}
}

// --- audience targeting -----------------------------------------------------

type stubAudience struct {
	students []string
	everyone []string
	all      []string
}

func (s stubAudience) StudentsForLecture(string, string) ([]string, error) { return s.students, nil }
func (s stubAudience) AllStudents() ([]string, error)                      { return s.all, nil }
func (s stubAudience) Everyone() ([]string, error)                         { return s.everyone, nil }
func (s stubAudience) StaffForSubject(string) ([]string, error)            { return nil, nil }

func waitForRequests(cs *captureServer, want int) []map[string]any {
	deadline := time.Now().Add(2 * time.Second)
	for time.Now().Before(deadline) {
		if len(cs.sent()) >= want {
			break
		}
		time.Sleep(10 * time.Millisecond)
	}
	return cs.sent()
}

func TestLecturePublishedExcludesTheUploader(t *testing.T) {
	cs := newCaptureServer()
	defer cs.Close()

	n := NewNotifier(clientTo(cs), stubAudience{students: []string{"s1", "s2", "teacher-1"}})
	n.LecturePublished(&models.Lecture{
		ID: "lec-1", Title: "الوحدة الأولى", Subject: "الرياضيات", Section: "شعبة أ",
		TeacherID: "teacher-1", TeacherName: "أ. أحمد", IsPublished: true,
	})

	sent := waitForRequests(cs, 1)
	if len(sent) != 1 {
		t.Fatalf("expected 1 notification, got %d", len(sent))
	}
	got := recipientsOf(t, sent[0])
	if strings.Join(got, ",") != "s1,s2" {
		t.Errorf("recipients = %v; the uploading teacher must be excluded", got)
	}

	headings := sent[0]["headings"].(map[string]any)
	if !strings.Contains(headings["en"].(string), "الرياضيات") {
		t.Errorf("title should name the subject, got %q", headings["en"])
	}
	data := sent[0]["data"].(map[string]any)
	if data["route"] != "/lecture/lec-1" {
		t.Errorf("route = %v, want /lecture/lec-1", data["route"])
	}
}

func TestUnpublishedLectureIsNotAnnounced(t *testing.T) {
	cs := newCaptureServer()
	defer cs.Close()

	n := NewNotifier(clientTo(cs), stubAudience{students: []string{"s1"}})
	n.LecturePublished(&models.Lecture{ID: "d", Title: "مسودة", IsPublished: false})

	time.Sleep(150 * time.Millisecond)
	if len(cs.sent()) != 0 {
		t.Error("a draft lecture must not notify anyone")
	}
}

func TestAttendanceNotifiesOnlyAbsences(t *testing.T) {
	cs := newCaptureServer()
	defer cs.Close()

	n := NewNotifier(clientTo(cs), stubAudience{})

	n.AttendanceRecorded(&models.AttendanceRecord{StudentID: "s1", Status: "present", Date: "2026-01-01"})
	time.Sleep(150 * time.Millisecond)
	if len(cs.sent()) != 0 {
		t.Fatal("a present mark must not notify")
	}

	n.AttendanceRecorded(&models.AttendanceRecord{StudentID: "s1", Status: "absent", Date: "2026-01-01"})
	sent := waitForRequests(cs, 1)
	if len(sent) != 1 {
		t.Fatalf("an absence should notify the student, got %d requests", len(sent))
	}
	if got := recipientsOf(t, sent[0]); strings.Join(got, ",") != "s1" {
		t.Errorf("recipients = %v, want only the affected student", got)
	}
}

func TestAnnouncementRequiresAPinnedPost(t *testing.T) {
	cs := newCaptureServer()
	defer cs.Close()

	n := NewNotifier(clientTo(cs), stubAudience{everyone: []string{"s1", "s2", "admin-1"}})

	n.Announcement(&models.CommunityPost{ID: "p1", Content: "نص", IsPinned: false}, "admin-1")
	time.Sleep(150 * time.Millisecond)
	if len(cs.sent()) != 0 {
		t.Fatal("an unpinned post is not an announcement")
	}

	n.Announcement(&models.CommunityPost{ID: "p2", Content: "تبدأ الامتحانات الأسبوع القادم", IsPinned: true}, "admin-1")
	sent := waitForRequests(cs, 1)
	if len(sent) != 1 {
		t.Fatalf("expected 1 announcement, got %d", len(sent))
	}
	if got := recipientsOf(t, sent[0]); strings.Join(got, ",") != "s1,s2" {
		t.Errorf("recipients = %v; the author must be excluded", got)
	}
}

func TestMaterialSharedIsStaffOnlyAndNeedsAnAttachment(t *testing.T) {
	cs := newCaptureServer()
	defer cs.Close()

	n := NewNotifier(clientTo(cs), stubAudience{all: []string{"s1", "s2"}})
	file := "uploads/documents/notes.pdf"

	// A student sharing a photo is not study material.
	n.MaterialShared(&models.CommunityPost{ID: "p1", ImagePath: &file, UserName: "طالب"}, models.RoleStudent, "s1")
	// Staff text-only post is not material either.
	n.MaterialShared(&models.CommunityPost{ID: "p2", Content: "تذكير", UserName: "أ. أحمد"}, models.RoleTeacher, "t1")
	time.Sleep(150 * time.Millisecond)
	if len(cs.sent()) != 0 {
		t.Fatalf("expected no notifications, got %d", len(cs.sent()))
	}

	n.MaterialShared(&models.CommunityPost{ID: "p3", ImagePath: &file, UserName: "أ. أحمد"}, models.RoleTeacher, "t1")
	sent := waitForRequests(cs, 1)
	if len(sent) != 1 {
		t.Fatalf("staff sharing a file should notify students, got %d", len(sent))
	}
}

func TestSummarizeKeepsPreviewsShortAndWhole(t *testing.T) {
	long := strings.Repeat("كلمة ", 200)
	got := summarize(long, 60)
	if len([]rune(got)) > 61 {
		t.Errorf("summary too long: %d runes", len([]rune(got)))
	}
	if !strings.HasSuffix(got, "…") {
		t.Errorf("a truncated summary should be elided, got %q", got)
	}
	if summarize("", 60) == "" {
		t.Error("an empty body must still produce a usable preview")
	}
	if got := summarize("  نص   قصير  ", 60); got != "نص قصير" {
		t.Errorf("whitespace should be collapsed, got %q", got)
	}
}

func itoa(i int) string {
	if i == 0 {
		return "0"
	}
	var b []byte
	for i > 0 {
		b = append([]byte{byte('0' + i%10)}, b...)
		i /= 10
	}
	return string(b)
}

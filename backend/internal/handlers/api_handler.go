package handlers

import (
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/tareeqmajdapp/backend/internal/httpx"
	"github.com/tareeqmajdapp/backend/internal/models"
	"github.com/tareeqmajdapp/backend/internal/notifications"
	"github.com/tareeqmajdapp/backend/internal/repository"
	"github.com/tareeqmajdapp/backend/internal/utils"
)

type ApiHandler struct {
	userRepo       *repository.UserRepository
	lectureRepo    *repository.LectureRepository
	commentRepo    *repository.CommentRepository
	ratingRepo     *repository.RatingRepository
	attendanceRepo *repository.AttendanceRepository
	notifier       *notifications.Notifier
}

func NewApiHandler(
	userRepo *repository.UserRepository,
	lectureRepo *repository.LectureRepository,
	commentRepo *repository.CommentRepository,
	ratingRepo *repository.RatingRepository,
	attendanceRepo *repository.AttendanceRepository,
	notifier *notifications.Notifier,
) *ApiHandler {
	return &ApiHandler{
		userRepo:       userRepo,
		lectureRepo:    lectureRepo,
		commentRepo:    commentRepo,
		ratingRepo:     ratingRepo,
		attendanceRepo: attendanceRepo,
		notifier:       notifier,
	}
}

const minPasswordLength = 6

func nowISO() string { return time.Now().UTC().Format(time.RFC3339) }

func currentUser(c *gin.Context) *models.User {
	v, ok := c.Get("currentUser")
	if !ok {
		return nil
	}
	u, _ := v.(*models.User)
	return u
}

// actorID returns the acting user's ID, or "" when the request is unauthenticated.
func actorID(u *models.User) string {
	if u == nil {
		return ""
	}
	return u.ID
}

// materiallyChanged reports whether an edit changed something a student would
// want to be told about. Pairs are (before, after); metadata-only edits such as
// a resolved duration or a corrected file size deliberately do not qualify.
func materiallyChanged(pairs ...string) bool {
	for i := 0; i+1 < len(pairs); i += 2 {
		if pairs[i] != pairs[i+1] {
			return true
		}
	}
	return false
}

func validGender(g string) bool {
	return g == "" || g == "ذكر" || g == "أنثى"
}

type userInput struct {
	ID                string   `json:"id"`
	Name              string   `json:"name" binding:"required"`
	Username          string   `json:"username" binding:"required"`
	Password          string   `json:"password"`
	Email             *string  `json:"email"`
	Phone             *string  `json:"phone"`
	Section           *string  `json:"section"`
	GuardianName      *string  `json:"guardianName"`
	GuardianPhone     *string  `json:"guardianPhone"`
	Gender            string   `json:"gender"`
	Subjects          []string `json:"subjects"`
	Notes             *string  `json:"notes"`
	PhotoPath         *string  `json:"photoPath"`
	SchoolName        *string  `json:"schoolName"`
	Bio               *string  `json:"bio"`
	LastNameChangeAt  *string  `json:"lastNameChangeAt"`
	Role              string   `json:"role" binding:"required"`
	CanUploadLectures bool     `json:"canUploadLectures"`
}

func (h *ApiHandler) CreateUser(c *gin.Context) {
	actor := currentUser(c)
	if !isAdmin(actor) {
		httpx.Error(c, http.StatusForbidden, httpx.MsgForbidden)
		return
	}

	var in userInput
	if err := c.ShouldBindJSON(&in); err != nil {
		httpx.Error(c, http.StatusBadRequest, httpx.MsgMissingFields)
		return
	}

	in.Username = strings.TrimSpace(in.Username)
	if len(in.Username) < 3 || len(in.Username) > 64 {
		httpx.Error(c, http.StatusBadRequest, "اسم المستخدم يجب أن يكون بين 3 و 64 حرفاً")
		return
	}

	if !validGender(in.Gender) {
		httpx.Error(c, http.StatusBadRequest, "قيمة الجنس غير صالحة")
		return
	}

	role := models.Role(in.Role)
	if role != models.RoleStudent && role != models.RoleTeacher && role != models.RoleAdmin {
		httpx.Error(c, http.StatusBadRequest, "دور غير صالح")
		return
	}

	if len(in.Password) < minPasswordLength {
		httpx.Error(c, http.StatusBadRequest, "كلمة المرور يجب أن تتكون من 6 أحرف على الأقل")
		return
	}

	taken, err := h.userRepo.UsernameTaken(in.Username, "")
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, httpx.MsgServerError)
		return
	}
	if taken {
		httpx.Error(c, http.StatusConflict, "اسم المستخدم مستخدم بالفعل")
		return
	}

	hash, err := utils.HashPassword(in.Password)
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, httpx.MsgServerError)
		return
	}

	id := in.ID
	if id == "" {
		id = utils.NewID()
	}

	gender := in.Gender
	if gender == "" {
		gender = "ذكر"
	}

	user := &models.User{
		ID:                id,
		Name:              in.Name,
		Username:          in.Username,
		PasswordHash:      hash,
		TokenVersion:      1,
		Email:             in.Email,
		Phone:             in.Phone,
		Section:           in.Section,
		GuardianName:      in.GuardianName,
		GuardianPhone:     in.GuardianPhone,
		Gender:            gender,
		Subjects:          in.Subjects,
		Notes:             in.Notes,
		PhotoPath:         in.PhotoPath,
		SchoolName:        in.SchoolName,
		Bio:               in.Bio,
		LastNameChangeAt:  in.LastNameChangeAt,
		Role:              role,
		CanUploadLectures: in.CanUploadLectures,
		CreatedAt:         nowISO(),
	}

	if err := h.userRepo.Create(user); err != nil {
		httpx.Error(c, http.StatusInternalServerError, "تعذّر إنشاء الحساب")
		return
	}

	c.JSON(http.StatusCreated, user)
}

func (h *ApiHandler) GetUsers(c *gin.Context) {
	actor := currentUser(c)

	var (
		users []models.User
		err   error
	)
	if isAdmin(actor) || isTeacher(actor) {
		users, err = h.userRepo.List()
	} else {
		gender := actor.Gender
		users, err = h.userRepo.ListForStudentView(gender)
	}
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, httpx.MsgServerError)
		return
	}
	c.JSON(http.StatusOK, users)
}

func (h *ApiHandler) GetClassmates(c *gin.Context) {
	actor := currentUser(c)
	if actor == nil {
		httpx.Error(c, http.StatusUnauthorized, "يرجى تسجيل الدخول")
		return
	}

	var section *string
	if s := c.Query("section"); s != "" {
		section = &s
	}

	students, err := h.userRepo.Classmates(actor.Gender, section)
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, httpx.MsgServerError)
		return
	}
	c.JSON(http.StatusOK, students)
}

func (h *ApiHandler) UpdateUser(c *gin.Context) {
	id := c.Param("id")
	actor := currentUser(c)

	target, err := h.userRepo.GetByID(id)
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, httpx.MsgServerError)
		return
	}
	if target == nil {
		httpx.Error(c, http.StatusNotFound, httpx.MsgUserNotFound)
		return
	}

	isSelf := actor != nil && actor.ID == target.ID
	if !isSelf && !isAdmin(actor) {
		httpx.Error(c, http.StatusForbidden, httpx.MsgForbidden)
		return
	}

	var in userInput
	if err := c.ShouldBindJSON(&in); err != nil {
		httpx.Error(c, http.StatusBadRequest, httpx.MsgMissingFields)
		return
	}

	in.Username = strings.TrimSpace(in.Username)
	if len(in.Username) < 3 || len(in.Username) > 64 {
		httpx.Error(c, http.StatusBadRequest, "اسم المستخدم يجب أن يكون بين 3 و 64 حرفاً")
		return
	}
	if !validGender(in.Gender) {
		httpx.Error(c, http.StatusBadRequest, "قيمة الجنس غير صالحة")
		return
	}

	if in.Username != target.Username {
		taken, err := h.userRepo.UsernameTaken(in.Username, target.ID)
		if err != nil {
			httpx.Error(c, http.StatusInternalServerError, httpx.MsgServerError)
			return
		}
		if taken {
			httpx.Error(c, http.StatusConflict, "اسم المستخدم مستخدم بالفعل")
			return
		}
	}

	newRole := target.Role
	canUpload := target.CanUploadLectures
	if isAdmin(actor) {
		if requestedRole := models.Role(in.Role); requestedRole != "" {
			newRole = requestedRole
		}
		canUpload = in.CanUploadLectures
	}

	if newRole != target.Role {
		if !canChangeRole(actor, target, newRole) {
			httpx.Error(c, http.StatusForbidden, "غير مصرح لك بتغيير هذا الدور")
			return
		}
	}

	target.Name = in.Name
	target.Username = in.Username
	target.Email = in.Email
	target.Phone = in.Phone
	target.Section = in.Section
	target.GuardianName = in.GuardianName
	target.GuardianPhone = in.GuardianPhone
	if isAdmin(actor) && in.Gender != "" {
		target.Gender = in.Gender
	}
	target.Subjects = in.Subjects
	target.Notes = in.Notes
	target.PhotoPath = in.PhotoPath
	target.SchoolName = in.SchoolName
	target.Bio = in.Bio
	target.LastNameChangeAt = in.LastNameChangeAt
	target.Role = newRole
	target.CanUploadLectures = canUpload

	if err := h.userRepo.Update(target); err != nil {
		httpx.Error(c, http.StatusInternalServerError, "تعذّر تحديث الحساب")
		return
	}

	if in.Password != "" {
		if len(in.Password) < minPasswordLength {
			httpx.Error(c, http.StatusBadRequest, "كلمة المرور يجب أن تتكون من 6 أحرف على الأقل")
			return
		}
		if !isSelf && !canResetPassword(actor, target) {
			httpx.Error(c, http.StatusForbidden, "غير مصرح لك بتغيير كلمة المرور لهذا الحساب")
			return
		}
		hash, err := utils.HashPassword(in.Password)
		if err != nil {
			httpx.Error(c, http.StatusInternalServerError, "تعذّر تحديث كلمة المرور")
			return
		}
		if err := h.userRepo.UpdatePassword(target.ID, hash); err != nil {
			httpx.Error(c, http.StatusInternalServerError, "تعذّر تحديث كلمة المرور")
			return
		}
	}

	updated, err := h.userRepo.GetByID(target.ID)
	if err != nil || updated == nil {
		c.JSON(http.StatusOK, target)
		return
	}
	c.JSON(http.StatusOK, updated)
}

type resetPasswordRequest struct {
	NewPassword string `json:"newPassword" binding:"required,min=6"`
}

func (h *ApiHandler) ResetPassword(c *gin.Context) {
	actor := currentUser(c)
	target, err := h.userRepo.GetByID(c.Param("id"))
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, httpx.MsgServerError)
		return
	}
	if target == nil {
		httpx.Error(c, http.StatusNotFound, httpx.MsgUserNotFound)
		return
	}
	if !canResetPassword(actor, target) {
		httpx.Error(c, http.StatusForbidden, "غير مصرح لك بإعادة تعيين كلمة المرور لهذا الحساب")
		return
	}

	var req resetPasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		httpx.Error(c, http.StatusBadRequest, "كلمة المرور الجديدة مطلوبة (6 أحرف على الأقل)")
		return
	}

	hash, err := utils.HashPassword(req.NewPassword)
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, "تعذّر تحديث كلمة المرور")
		return
	}
	if err := h.userRepo.UpdatePassword(target.ID, hash); err != nil {
		httpx.Error(c, http.StatusInternalServerError, "تعذّر تحديث كلمة المرور")
		return
	}

	httpx.Message(c, http.StatusOK, "تم إعادة تعيين كلمة المرور بنجاح")
}

func (h *ApiHandler) DeleteUser(c *gin.Context) {
	actor := currentUser(c)
	target, err := h.userRepo.GetByID(c.Param("id"))
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, httpx.MsgServerError)
		return
	}
	if target == nil {
		httpx.Error(c, http.StatusNotFound, httpx.MsgUserNotFound)
		return
	}
	if !canDeleteUser(actor, target) {
		httpx.Error(c, http.StatusForbidden, "غير مصرح لك بحذف هذا الحساب")
		return
	}
	if err := h.userRepo.Delete(target.ID); err != nil {
		httpx.Error(c, http.StatusInternalServerError, "تعذّر حذف الحساب")
		return
	}
	httpx.Message(c, http.StatusOK, "تم حذف الحساب بنجاح")
}

type lectureInput struct {
	ID             string  `json:"id"`
	Title          string  `json:"title" binding:"required"`
	Description    string  `json:"description"`
	Subject        string  `json:"subject" binding:"required"`
	Section        string  `json:"section"`
	TeacherID      string  `json:"teacherId" binding:"required"`
	TeacherName    string  `json:"teacherName"`
	VideoPath      string  `json:"videoPath" binding:"required"`
	CoverImagePath *string `json:"coverImagePath"`
	Date           string  `json:"date"`
	PublishedAt    *string `json:"publishedAt"`
	Duration       *string `json:"duration"`
	FileSizeBytes  int64   `json:"fileSizeBytes"`
	IsPublished    bool    `json:"isPublished"`
}

func (h *ApiHandler) GetLectures(c *gin.Context) {
	lectures, err := h.lectureRepo.List()
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, httpx.MsgServerError)
		return
	}
	c.JSON(http.StatusOK, lectures)
}

func (h *ApiHandler) CreateLecture(c *gin.Context) {
	actor := currentUser(c)
	if !canUploadLectures(actor) {
		httpx.Error(c, http.StatusForbidden, "غير مصرح لك برفع المحاضرات")
		return
	}

	var in lectureInput
	if err := c.ShouldBindJSON(&in); err != nil {
		httpx.Error(c, http.StatusBadRequest, httpx.MsgMissingFields)
		return
	}

	id := in.ID
	if id == "" {
		id = utils.NewID()
	}
	section := in.Section
	if section == "" {
		section = "شعبة أ"
	}

	lecture := &models.Lecture{
		ID:             id,
		Title:          in.Title,
		Description:    in.Description,
		Subject:        in.Subject,
		Section:        section,
		TeacherID:      in.TeacherID,
		TeacherName:    in.TeacherName,
		VideoPath:      in.VideoPath,
		CoverImagePath: in.CoverImagePath,
		Date:           in.Date,
		PublishedAt:    in.PublishedAt,
		Duration:       in.Duration,
		FileSizeBytes:  in.FileSizeBytes,
		IsPublished:    in.IsPublished,
		CreatedAt:      nowISO(),
	}
	if lecture.Date == "" {
		lecture.Date = nowISO()
	}

	if err := h.lectureRepo.Create(lecture); err != nil {
		httpx.Error(c, http.StatusInternalServerError, "تعذّر إنشاء المحاضرة")
		return
	}
	h.notifier.LecturePublished(lecture)
	c.JSON(http.StatusCreated, lecture)
}

func (h *ApiHandler) UpdateLecture(c *gin.Context) {
	actor := currentUser(c)
	existing, err := h.lectureRepo.GetByID(c.Param("id"))
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, httpx.MsgServerError)
		return
	}
	if existing == nil {
		httpx.Error(c, http.StatusNotFound, "المحاضرة غير موجودة")
		return
	}
	if !canManageLecture(actor, existing) {
		httpx.Error(c, http.StatusForbidden, "غير مصرح لك بتعديل هذه المحاضرة")
		return
	}

	var in lectureInput
	if err := c.ShouldBindJSON(&in); err != nil {
		httpx.Error(c, http.StatusBadRequest, httpx.MsgMissingFields)
		return
	}

	// Snapshot the fields that decide whether this edit is worth a push.
	// The app also PUTs this endpoint purely to persist a video duration it
	// just resolved during playback, so notifying on *any* update would fire a
	// notification every time a student opens a lecture.
	wasPublished := existing.IsPublished
	prevTitle := existing.Title
	prevVideo := existing.VideoPath
	prevSubject := existing.Subject
	prevSection := existing.Section

	existing.Title = in.Title
	existing.Description = in.Description
	existing.Subject = in.Subject
	if in.Section != "" {
		existing.Section = in.Section
	}
	if in.TeacherID != "" {
		existing.TeacherID = in.TeacherID
	}
	if in.TeacherName != "" {
		existing.TeacherName = in.TeacherName
	}
	if in.VideoPath != "" {
		existing.VideoPath = in.VideoPath
	}
	if in.CoverImagePath != nil {
		existing.CoverImagePath = in.CoverImagePath
	}
	if in.Date != "" {
		existing.Date = in.Date
	}
	existing.PublishedAt = in.PublishedAt
	existing.Duration = in.Duration
	if in.FileSizeBytes > 0 {
		existing.FileSizeBytes = in.FileSizeBytes
	}
	existing.IsPublished = in.IsPublished

	if err := h.lectureRepo.Update(existing); err != nil {
		httpx.Error(c, http.StatusInternalServerError, "تعذّر تحديث المحاضرة")
		return
	}

	switch {
	case !wasPublished && existing.IsPublished:
		// Going live is the moment students care about, whether the lecture
		// was created as a draft or published straight away.
		h.notifier.LecturePublished(existing)
	case existing.IsPublished && materiallyChanged(
		prevTitle, existing.Title,
		prevVideo, existing.VideoPath,
		prevSubject, existing.Subject,
		prevSection, existing.Section,
	):
		h.notifier.LectureUpdated(existing, actorID(actor))
	}

	c.JSON(http.StatusOK, existing)
}

func (h *ApiHandler) DeleteLecture(c *gin.Context) {
	actor := currentUser(c)
	existing, err := h.lectureRepo.GetByID(c.Param("id"))
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, httpx.MsgServerError)
		return
	}
	if existing == nil {
		httpx.Error(c, http.StatusNotFound, "المحاضرة غير موجودة")
		return
	}
	if !canManageLecture(actor, existing) {
		httpx.Error(c, http.StatusForbidden, "غير مصرح لك بحذف هذه المحاضرة")
		return
	}
	if err := h.lectureRepo.Delete(existing.ID); err != nil {
		httpx.Error(c, http.StatusInternalServerError, "تعذّر حذف المحاضرة")
		return
	}
	httpx.Message(c, http.StatusOK, "تم حذف المحاضرة بنجاح")
}

type commentInput struct {
	ID            string  `json:"id"`
	LectureID     string  `json:"lectureId" binding:"required"`
	UserID        string  `json:"userId" binding:"required"`
	UserName      string  `json:"userName" binding:"required"`
	UserPhotoPath *string `json:"userPhotoPath"`
	Content       string  `json:"content" binding:"required"`
}

func (h *ApiHandler) GetComments(c *gin.Context) {
	comments, err := h.commentRepo.List()
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, httpx.MsgServerError)
		return
	}
	c.JSON(http.StatusOK, comments)
}

func (h *ApiHandler) CreateComment(c *gin.Context) {
	var in commentInput
	if err := c.ShouldBindJSON(&in); err != nil {
		httpx.Error(c, http.StatusBadRequest, httpx.MsgMissingFields)
		return
	}
	id := in.ID
	if id == "" {
		id = utils.NewID()
	}
	comment := &models.Comment{
		ID:            id,
		LectureID:     in.LectureID,
		UserID:        in.UserID,
		UserName:      in.UserName,
		UserPhotoPath: in.UserPhotoPath,
		Content:       in.Content,
		CreatedAt:     nowISO(),
	}
	if err := h.commentRepo.Create(comment); err != nil {
		httpx.Error(c, http.StatusInternalServerError, "تعذّر إضافة التعليق")
		return
	}
	c.JSON(http.StatusCreated, comment)
}

type updateCommentInput struct {
	Content string `json:"content" binding:"required"`
}

func (h *ApiHandler) UpdateComment(c *gin.Context) {
	actor := currentUser(c)

	comment, err := h.commentRepo.GetByID(c.Param("id"))
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, httpx.MsgServerError)
		return
	}
	if comment == nil {
		httpx.Error(c, http.StatusNotFound, "التعليق غير موجود")
		return
	}
	if !canEditOrDeleteComment(actor, comment, time.Now()) {
		httpx.Error(c, http.StatusForbidden, "غير مصرح لك بتعديل هذا التعليق")
		return
	}

	var in updateCommentInput
	if err := c.ShouldBindJSON(&in); err != nil {
		httpx.Error(c, http.StatusBadRequest, httpx.MsgMissingFields)
		return
	}

	updatedAt := nowISO()
	comment.Content = in.Content
	comment.UpdatedAt = &updatedAt
	comment.IsEdited = true

	if err := h.commentRepo.Update(comment); err != nil {
		httpx.Error(c, http.StatusInternalServerError, "تعذّر تعديل التعليق")
		return
	}
	c.JSON(http.StatusOK, comment)
}

func (h *ApiHandler) DeleteComment(c *gin.Context) {
	actor := currentUser(c)

	comment, err := h.commentRepo.GetByID(c.Param("id"))
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, httpx.MsgServerError)
		return
	}
	if comment == nil {
		httpx.Error(c, http.StatusNotFound, "التعليق غير موجود")
		return
	}
	if !canEditOrDeleteComment(actor, comment, time.Now()) {
		httpx.Error(c, http.StatusForbidden, "غير مصرح لك بحذف هذا التعليق")
		return
	}

	if err := h.commentRepo.Delete(comment.ID); err != nil {
		httpx.Error(c, http.StatusInternalServerError, "تعذّر حذف التعليق")
		return
	}
	httpx.Message(c, http.StatusOK, "تم حذف التعليق بنجاح")
}

type ratingInput struct {
	ID        string `json:"id"`
	LectureID string `json:"lectureId" binding:"required"`
	UserID    string `json:"userId" binding:"required"`
	Stars     int    `json:"stars" binding:"required,min=1,max=5"`
}

func (h *ApiHandler) GetRatings(c *gin.Context) {
	ratings, err := h.ratingRepo.List()
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, httpx.MsgServerError)
		return
	}
	c.JSON(http.StatusOK, ratings)
}

func (h *ApiHandler) CreateRating(c *gin.Context) {
	var in ratingInput
	if err := c.ShouldBindJSON(&in); err != nil {
		httpx.Error(c, http.StatusBadRequest, httpx.MsgMissingFields)
		return
	}
	id := in.ID
	if id == "" {
		id = utils.NewID()
	}
	rating := &models.LectureRating{
		ID:        id,
		LectureID: in.LectureID,
		UserID:    in.UserID,
		Stars:     in.Stars,
		CreatedAt: nowISO(),
	}
	if err := h.ratingRepo.Upsert(rating); err != nil {
		httpx.Error(c, http.StatusInternalServerError, "تعذّر حفظ التقييم")
		return
	}
	c.JSON(http.StatusCreated, rating)
}

type attendanceInput struct {
	ID             string  `json:"id"`
	StudentID      string  `json:"studentId" binding:"required"`
	StudentName    string  `json:"studentName" binding:"required"`
	Section        string  `json:"section" binding:"required"`
	Subject        *string `json:"subject"`
	Date           string  `json:"date" binding:"required"`
	Status         string  `json:"status" binding:"required"`
	RecordedBy     string  `json:"recordedBy" binding:"required"`
	RecordedByName string  `json:"recordedByName"`
}

func validAttendanceStatus(s string) (models.AttendanceStatus, bool) {
	status := models.AttendanceStatus(s)
	switch status {
	case models.AttendancePresent, models.AttendanceAbsent, models.AttendanceExcused:
		return status, true
	default:
		return "", false
	}
}

func (h *ApiHandler) GetAttendance(c *gin.Context) {
	records, err := h.attendanceRepo.List()
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, httpx.MsgServerError)
		return
	}
	c.JSON(http.StatusOK, records)
}

func (h *ApiHandler) CreateAttendance(c *gin.Context) {
	actor := currentUser(c)
	if !canManageAttendance(actor) {
		httpx.Error(c, http.StatusForbidden, httpx.MsgForbidden)
		return
	}

	var in attendanceInput
	if err := c.ShouldBindJSON(&in); err != nil {
		httpx.Error(c, http.StatusBadRequest, httpx.MsgMissingFields)
		return
	}
	status, ok := validAttendanceStatus(in.Status)
	if !ok {
		httpx.Error(c, http.StatusBadRequest, "حالة حضور غير صالحة")
		return
	}

	id := in.ID
	if id == "" {
		id = utils.NewID()
	}
	record := &models.AttendanceRecord{
		ID:             id,
		StudentID:      in.StudentID,
		StudentName:    in.StudentName,
		Section:        in.Section,
		Subject:        in.Subject,
		Date:           in.Date,
		Status:         status,
		RecordedBy:     in.RecordedBy,
		RecordedByName: in.RecordedByName,
		RecordedAt:     nowISO(),
	}
	if err := h.attendanceRepo.Create(record); err != nil {
		httpx.Error(c, http.StatusInternalServerError, "تعذّر تسجيل الحضور")
		return
	}
	// Only absences reach the student; a push for every "present" mark would
	// train people to swipe the channel away.
	h.notifier.AttendanceRecorded(record)
	c.JSON(http.StatusCreated, record)
}

func (h *ApiHandler) UpdateAttendance(c *gin.Context) {
	actor := currentUser(c)
	if !canManageAttendance(actor) {
		httpx.Error(c, http.StatusForbidden, httpx.MsgForbidden)
		return
	}

	existing, err := h.attendanceRepo.GetByID(c.Param("id"))
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, httpx.MsgServerError)
		return
	}
	if existing == nil {
		httpx.Error(c, http.StatusNotFound, "سجل الحضور غير موجود")
		return
	}

	var in attendanceInput
	if err := c.ShouldBindJSON(&in); err != nil {
		httpx.Error(c, http.StatusBadRequest, httpx.MsgMissingFields)
		return
	}
	status, ok := validAttendanceStatus(in.Status)
	if !ok {
		httpx.Error(c, http.StatusBadRequest, "حالة حضور غير صالحة")
		return
	}

	record := &models.AttendanceRecord{
		ID:             existing.ID,
		StudentID:      in.StudentID,
		StudentName:    in.StudentName,
		Section:        in.Section,
		Subject:        in.Subject,
		Date:           in.Date,
		Status:         status,
		RecordedBy:     in.RecordedBy,
		RecordedByName: in.RecordedByName,
		RecordedAt:     nowISO(),
	}
	if err := h.attendanceRepo.Update(record); err != nil {
		httpx.Error(c, http.StatusInternalServerError, "تعذّر تحديث سجل الحضور")
		return
	}
	c.JSON(http.StatusOK, record)
}

func (h *ApiHandler) DeleteAttendance(c *gin.Context) {
	actor := currentUser(c)
	if !canManageAttendance(actor) {
		httpx.Error(c, http.StatusForbidden, httpx.MsgForbidden)
		return
	}

	existing, err := h.attendanceRepo.GetByID(c.Param("id"))
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, httpx.MsgServerError)
		return
	}
	if existing == nil {
		httpx.Error(c, http.StatusNotFound, "سجل الحضور غير موجود")
		return
	}

	if err := h.attendanceRepo.Delete(existing.ID); err != nil {
		httpx.Error(c, http.StatusInternalServerError, "تعذّر حذف السجل")
		return
	}
	httpx.Message(c, http.StatusOK, "تم حذف السجل بنجاح")
}

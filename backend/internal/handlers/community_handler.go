package handlers

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/tareeqmajdapp/backend/internal/httpx"
	"github.com/tareeqmajdapp/backend/internal/models"
	"github.com/tareeqmajdapp/backend/internal/notifications"
	"github.com/tareeqmajdapp/backend/internal/repository"
	"github.com/tareeqmajdapp/backend/internal/utils"
)

type CommunityHandler struct {
	repo     *repository.CommunityRepository
	notifier *notifications.Notifier
}

func NewCommunityHandler(repo *repository.CommunityRepository, notifier *notifications.Notifier) *CommunityHandler {
	return &CommunityHandler{repo: repo, notifier: notifier}
}

type postInput struct {
	Title     *string `json:"title"`
	Content   string  `json:"content"`
	ImagePath *string `json:"imagePath"`
	VideoPath *string `json:"videoPath"`
}

func postHasBody(in postInput) bool {
	if strings.TrimSpace(in.Content) != "" {
		return true
	}
	if in.ImagePath != nil && strings.TrimSpace(*in.ImagePath) != "" {
		return true
	}
	if in.VideoPath != nil && strings.TrimSpace(*in.VideoPath) != "" {
		return true
	}
	return false
}

func (h *CommunityHandler) ListPosts(c *gin.Context) {
	actor := currentUser(c)
	var studentGender *string
	if actor != nil && actor.Role == models.RoleStudent {
		g := actor.Gender
		studentGender = &g
	}
	posts, err := h.repo.ListPosts(studentGender)
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, httpx.MsgServerError)
		return
	}
	c.JSON(http.StatusOK, posts)
}

func (h *CommunityHandler) CreatePost(c *gin.Context) {
	actor := currentUser(c)
	if actor == nil {
		httpx.Error(c, http.StatusUnauthorized, httpx.MsgLoginRequired)
		return
	}

	var in postInput
	if err := c.ShouldBindJSON(&in); err != nil {
		httpx.Error(c, http.StatusBadRequest, httpx.MsgInvalidRequest)
		return
	}
	if !postHasBody(in) {
		httpx.Error(c, http.StatusBadRequest, "أضف نصاً أو وسائط للمنشور")
		return
	}

	post := &models.CommunityPost{
		ID:            utils.NewID(),
		UserID:        actor.ID,
		UserName:      actor.Name,
		UserPhotoPath: actor.PhotoPath,
		Title:         in.Title,
		Content:       in.Content,
		ImagePath:     in.ImagePath,
		VideoPath:     in.VideoPath,
		CreatedAt:     nowISO(),
	}
	if err := h.repo.CreatePost(post); err != nil {
		httpx.Error(c, http.StatusInternalServerError, "تعذّر نشر المنشور")
		return
	}
	// Staff posting a file or video is how study material reaches students on
	// this platform, so that is the event that gets announced.
	h.notifier.MaterialShared(post, actor.Role, actor.ID)
	c.JSON(http.StatusCreated, post)
}

func (h *CommunityHandler) UpdatePost(c *gin.Context) {
	actor := currentUser(c)
	post, err := h.repo.GetPost(c.Param("id"))
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, httpx.MsgServerError)
		return
	}
	if post == nil {
		httpx.Error(c, http.StatusNotFound, "المنشور غير موجود")
		return
	}

	if actor == nil || (actor.ID != post.UserID && !isAdmin(actor)) {
		httpx.Error(c, http.StatusForbidden, "غير مصرح لك بتعديل هذا المنشور")
		return
	}

	var in postInput
	if err := c.ShouldBindJSON(&in); err != nil {
		httpx.Error(c, http.StatusBadRequest, httpx.MsgInvalidRequest)
		return
	}
	if !postHasBody(in) {
		httpx.Error(c, http.StatusBadRequest, "أضف نصاً أو وسائط للمنشور")
		return
	}
	post.Title = in.Title
	post.Content = in.Content
	post.ImagePath = in.ImagePath
	post.VideoPath = in.VideoPath
	updatedAt := nowISO()
	post.UpdatedAt = &updatedAt

	if err := h.repo.UpdatePost(post); err != nil {
		httpx.Error(c, http.StatusInternalServerError, "تعذّر تحديث المنشور")
		return
	}
	c.JSON(http.StatusOK, post)
}

func (h *CommunityHandler) DeletePost(c *gin.Context) {
	actor := currentUser(c)
	post, err := h.repo.GetPost(c.Param("id"))
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, httpx.MsgServerError)
		return
	}
	if post == nil {
		httpx.Error(c, http.StatusNotFound, "المنشور غير موجود")
		return
	}

	if actor == nil || (actor.ID != post.UserID && !isAdmin(actor)) {
		httpx.Error(c, http.StatusForbidden, "غير مصرح لك بحذف هذا المنشور")
		return
	}
	if err := h.repo.DeletePost(post.ID); err != nil {
		httpx.Error(c, http.StatusInternalServerError, "تعذّر حذف المنشور")
		return
	}
	httpx.Message(c, http.StatusOK, "تم حذف المنشور بنجاح")
}

func (h *CommunityHandler) TogglePin(c *gin.Context) {
	post, err := h.repo.GetPost(c.Param("id"))
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, httpx.MsgServerError)
		return
	}
	if post == nil {
		httpx.Error(c, http.StatusNotFound, "المنشور غير موجود")
		return
	}
	post.IsPinned = !post.IsPinned
	if err := h.repo.UpdatePost(post); err != nil {
		httpx.Error(c, http.StatusInternalServerError, "تعذّر تحديث المنشور")
		return
	}
	// Pinning is the act that turns a post into an institute announcement.
	// Unpinning is not an event anyone needs to hear about.
	if post.IsPinned {
		h.notifier.Announcement(post, actorID(currentUser(c)))
	}
	c.JSON(http.StatusOK, post)
}

type postCommentInput struct {
	Content string `json:"content" binding:"required"`
}

func (h *CommunityHandler) ListComments(c *gin.Context) {
	comments, err := h.repo.ListComments(c.Param("id"))
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, httpx.MsgServerError)
		return
	}
	c.JSON(http.StatusOK, comments)
}

func (h *CommunityHandler) CreateComment(c *gin.Context) {
	actor := currentUser(c)
	if actor == nil {
		httpx.Error(c, http.StatusUnauthorized, httpx.MsgLoginRequired)
		return
	}
	var in postCommentInput
	if err := c.ShouldBindJSON(&in); err != nil {
		httpx.Error(c, http.StatusBadRequest, "نص التعليق مطلوب")
		return
	}
	comment := &models.CommunityComment{
		ID:            utils.NewID(),
		PostID:        c.Param("id"),
		UserID:        actor.ID,
		UserName:      actor.Name,
		UserPhotoPath: actor.PhotoPath,
		Content:       in.Content,
		CreatedAt:     nowISO(),
	}
	if err := h.repo.CreateComment(comment); err != nil {
		httpx.Error(c, http.StatusInternalServerError, "تعذّر إضافة التعليق")
		return
	}
	c.JSON(http.StatusCreated, comment)
}

func (h *CommunityHandler) DeleteComment(c *gin.Context) {

	actor := currentUser(c)
	if !isAdmin(actor) {
		httpx.Error(c, http.StatusForbidden, "غير مصرح لك بحذف هذا التعليق")
		return
	}
	if err := h.repo.DeleteComment(c.Param("commentId")); err != nil {
		httpx.Error(c, http.StatusInternalServerError, "تعذّر حذف التعليق")
		return
	}
	httpx.Message(c, http.StatusOK, "تم حذف التعليق بنجاح")
}

type reportInput struct {
	Reason *string `json:"reason"`
}

func (h *CommunityHandler) CreateReport(c *gin.Context) {
	actor := currentUser(c)
	if actor == nil {
		httpx.Error(c, http.StatusUnauthorized, httpx.MsgLoginRequired)
		return
	}
	var in reportInput
	_ = c.ShouldBindJSON(&in)
	report := &models.CommunityReport{
		ID:         utils.NewID(),
		PostID:     c.Param("id"),
		ReportedBy: actor.ID,
		Reason:     in.Reason,
		Status:     models.ReportOpen,
		CreatedAt:  nowISO(),
	}
	if err := h.repo.CreateReport(report); err != nil {
		httpx.Error(c, http.StatusInternalServerError, "تعذّر إرسال البلاغ")
		return
	}
	httpx.Message(c, http.StatusCreated, "تم إرسال البلاغ، شكراً لك")
}

func (h *CommunityHandler) ListReports(c *gin.Context) {
	reports, err := h.repo.ListOpenReports()
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, httpx.MsgServerError)
		return
	}
	c.JSON(http.StatusOK, reports)
}

type resolveReportInput struct {
	Status string `json:"status" binding:"required"`
}

func (h *CommunityHandler) ResolveReport(c *gin.Context) {
	var in resolveReportInput
	if err := c.ShouldBindJSON(&in); err != nil {
		httpx.Error(c, http.StatusBadRequest, "الحالة مطلوبة")
		return
	}
	status := models.ReportStatus(in.Status)
	if status != models.ReportDismissed && status != models.ReportResolved {
		httpx.Error(c, http.StatusBadRequest, "حالة غير صالحة")
		return
	}
	if err := h.repo.UpdateReportStatus(c.Param("id"), status); err != nil {
		httpx.Error(c, http.StatusInternalServerError, "تعذّر تحديث حالة البلاغ")
		return
	}
	httpx.Message(c, http.StatusOK, "تم تحديث حالة البلاغ")
}

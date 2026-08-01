package handlers

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
	"github.com/tareeqmajdapp/backend/internal/httpx"
	"github.com/tareeqmajdapp/backend/internal/logger"
	"github.com/tareeqmajdapp/backend/internal/models"
	"github.com/tareeqmajdapp/backend/internal/realtime"
	"github.com/tareeqmajdapp/backend/internal/repository"
)

type RealtimeHandler struct {
	hub      *realtime.Hub
	progress *repository.ProgressRepository
	upgrader websocket.Upgrader
}

func NewRealtimeHandler(hub *realtime.Hub, progress *repository.ProgressRepository) *RealtimeHandler {
	return &RealtimeHandler{
		hub:      hub,
		progress: progress,
		upgrader: websocket.Upgrader{
			ReadBufferSize:   1024,
			WriteBufferSize:  4096,
			HandshakeTimeout: 10 * time.Second,
			CheckOrigin:      func(r *http.Request) bool { return true },
		},
	}
}

func (h *RealtimeHandler) Connect(c *gin.Context) {
	user := currentUser(c)
	if user == nil {
		httpx.Abort(c, http.StatusUnauthorized, httpx.MsgLoginRequired)
		return
	}

	monitor := user.Role == models.RoleAdmin || user.Role == models.RoleTeacher

	conn, err := h.upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		logger.Warn("realtime: upgrade failed for %s: %v", user.ID, err)
		return
	}

	section := ""
	if user.Section != nil {
		section = *user.Section
	}

	client := realtime.NewClient(
		h.hub, conn, user.ID, user.Name, section, string(user.Role), monitor,
	)
	client.Run()
}

func (h *RealtimeHandler) ListProgress(c *gin.Context) {
	if lectureID := c.Query("lectureId"); lectureID != "" {
		rows, err := h.progress.ListByLecture(lectureID)
		if err != nil {
			httpx.Error(c, http.StatusInternalServerError, httpx.MsgServerError)
			return
		}
		c.JSON(http.StatusOK, rows)
		return
	}

	if userID := c.Query("userId"); userID != "" {
		rows, err := h.progress.ListByUser(userID)
		if err != nil {
			httpx.Error(c, http.StatusInternalServerError, httpx.MsgServerError)
			return
		}
		c.JSON(http.StatusOK, rows)
		return
	}

	rows, err := h.progress.List()
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, httpx.MsgServerError)
		return
	}
	c.JSON(http.StatusOK, rows)
}

func (h *RealtimeHandler) MyProgress(c *gin.Context) {
	user := currentUser(c)
	if user == nil {
		httpx.Abort(c, http.StatusUnauthorized, httpx.MsgLoginRequired)
		return
	}
	rows, err := h.progress.ListByUser(user.ID)
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, httpx.MsgServerError)
		return
	}
	c.JSON(http.StatusOK, rows)
}

type progressInput struct {
	LectureID           string  `json:"lectureId" binding:"required"`
	PositionSeconds     float64 `json:"positionSeconds"`
	DurationSeconds     float64 `json:"durationSeconds"`
	WatchedDeltaSeconds float64 `json:"watchedDeltaSeconds"`
	Completed           bool    `json:"completed"`
}

func (h *RealtimeHandler) ReportProgress(c *gin.Context) {
	user := currentUser(c)
	if user == nil {
		httpx.Abort(c, http.StatusUnauthorized, httpx.MsgLoginRequired)
		return
	}

	var input progressInput
	if err := c.ShouldBindJSON(&input); err != nil {
		httpx.Error(c, http.StatusBadRequest, httpx.MsgInvalidRequest)
		return
	}

	err := h.progress.Upsert(models.ProgressUpdate{
		UserID:              user.ID,
		LectureID:           input.LectureID,
		LastPositionSeconds: input.PositionSeconds,
		WatchedDeltaSeconds: input.WatchedDeltaSeconds,
		DurationSeconds:     input.DurationSeconds,
		Completed:           input.Completed,
		OccurredAt:          time.Now().UTC().Format(time.RFC3339),
	})
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, httpx.MsgServerError)
		return
	}

	httpx.Message(c, http.StatusOK, "تم الحفظ")
}

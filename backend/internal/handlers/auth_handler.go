package handlers

import (
	"errors"
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/tareeqmajdapp/backend/internal/httpx"
	"github.com/tareeqmajdapp/backend/internal/logger"
	"github.com/tareeqmajdapp/backend/internal/models"
	"github.com/tareeqmajdapp/backend/internal/repository"
	"github.com/tareeqmajdapp/backend/internal/security"
	"github.com/tareeqmajdapp/backend/internal/services"
	"github.com/tareeqmajdapp/backend/internal/utils"
)

type AuthHandler struct {
	authService *services.AuthService
	userRepo    *repository.UserRepository
	lockout     *security.Lockout
}

func NewAuthHandler(authService *services.AuthService, userRepo *repository.UserRepository, lockout *security.Lockout) *AuthHandler {
	return &AuthHandler{authService: authService, userRepo: userRepo, lockout: lockout}
}

type loginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

func (h *AuthHandler) Login(c *gin.Context) {
	var req loginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		httpx.Error(c, http.StatusBadRequest, "اسم المستخدم وكلمة المرور مطلوبان")
		return
	}

	if remaining := h.lockout.LockedFor(req.Username); remaining > 0 {
		minutes := int(remaining.Minutes()) + 1
		logger.Warn("Login blocked for locked account %q from %s", req.Username, c.ClientIP())
		httpx.Error(c, http.StatusTooManyRequests,
			fmt.Sprintf("تم إيقاف تسجيل الدخول مؤقتاً بسبب محاولات فاشلة متكررة. حاول مجدداً بعد %d دقيقة", minutes))
		return
	}

	user, err := h.authService.Authenticate(req.Username, req.Password)
	if err != nil {
		if errors.Is(err, services.ErrInvalidCredentials) {
			if locked := h.lockout.RecordFailure(req.Username); locked > 0 {
				logger.Warn("Account %q locked for %s after repeated failed logins (last attempt from %s)",
					req.Username, locked, c.ClientIP())
			} else {
				logger.Warn("Failed login for %q from %s", req.Username, c.ClientIP())
			}
			httpx.Error(c, http.StatusUnauthorized, "اسم المستخدم أو كلمة المرور غير صحيحة")
			return
		}
		httpx.Error(c, http.StatusInternalServerError, "حدث خطأ أثناء تسجيل الدخول")
		return
	}

	token, err := h.authService.GenerateToken(user)
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, "تعذّر إنشاء جلسة الدخول")
		return
	}

	h.lockout.RecordSuccess(req.Username)
	logger.Info("Login succeeded for %q (role=%s) from %s", user.Username, user.Role, c.ClientIP())

	c.JSON(http.StatusOK, gin.H{"token": token, "user": user})
}

func (h *AuthHandler) Me(c *gin.Context) {
	user := c.MustGet("currentUser").(*models.User)
	c.JSON(http.StatusOK, user)
}

type changePasswordRequest struct {
	CurrentPassword string `json:"currentPassword" binding:"required"`
	NewPassword     string `json:"newPassword" binding:"required,min=6"`
}

func (h *AuthHandler) ChangePassword(c *gin.Context) {
	user := c.MustGet("currentUser").(*models.User)

	var req changePasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		httpx.Error(c, http.StatusBadRequest, httpx.MsgMissingFields)
		return
	}

	if !utils.VerifyPassword(user.PasswordHash, req.CurrentPassword) {
		httpx.Error(c, http.StatusUnauthorized, "كلمة المرور الحالية غير صحيحة")
		return
	}

	hash, err := utils.HashPassword(req.NewPassword)
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, "تعذّر تحديث كلمة المرور")
		return
	}
	if err := h.userRepo.UpdatePassword(user.ID, hash); err != nil {
		httpx.Error(c, http.StatusInternalServerError, "تعذّر تحديث كلمة المرور")
		return
	}

	httpx.Message(c, http.StatusOK, "تم تحديث كلمة المرور بنجاح")
}

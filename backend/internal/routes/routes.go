package routes

import (
	"io"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jmoiron/sqlx"
	"github.com/tareeqmajdapp/backend/internal/database"
	"github.com/tareeqmajdapp/backend/internal/handlers"
	"github.com/tareeqmajdapp/backend/internal/logger"
	"github.com/tareeqmajdapp/backend/internal/middleware"
	"github.com/tareeqmajdapp/backend/internal/repository"
)

const maxJSONBodyBytes = 5 * 1024 * 1024

const loginRateLimit = 15
const loginRateWindow = 5 * time.Minute

const globalRateLimit = 600
const globalRateWindow = time.Minute

type Handlers struct {
	Auth      *handlers.AuthHandler
	Api       *handlers.ApiHandler
	Upload    *handlers.UploadHandler
	Community *handlers.CommunityHandler
	Stream    *handlers.StreamHandler
	Realtime  *handlers.RealtimeHandler
}

type Security struct {
	JWTSecret      string
	Environment    string
	AllowedOrigins []string
	TrustedProxies []string
}

func SetupRouter(h *Handlers, db *sqlx.DB, userRepo *repository.UserRepository, uploadsDir string, sec Security) *gin.Engine {
	production := sec.Environment == "production"
	if production {
		gin.SetMode(gin.ReleaseMode)
	} else {
		gin.SetMode(gin.DebugMode)
	}

	gin.DefaultWriter = io.Discard
	gin.DefaultErrorWriter = io.Discard

	r := gin.New()

	if len(sec.TrustedProxies) > 0 {
		if err := r.SetTrustedProxies(sec.TrustedProxies); err != nil {
			logger.Fatal("Invalid TRUSTED_PROXIES value: %v", err)
		}
	} else {
		_ = r.SetTrustedProxies(nil)
	}

	r.Use(logger.GinRecovery())
	r.Use(logger.GinMiddleware())
	r.Use(middleware.SecurityHeaders(production))
	r.Use(middleware.CORS(sec.AllowedOrigins))
	r.Use(middleware.RateLimit(globalRateLimit, globalRateWindow))

	r.Static("/uploads", uploadsDir)

	r.GET("/health", func(c *gin.Context) {
		if err := database.HealthCheck(db); err != nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"status": "unhealthy", "error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	auth := middleware.AuthRequired(sec.JWTSecret, userRepo)
	adminOnly := middleware.RequireRole("admin")
	staffOnly := middleware.RequireRole("admin", "teacher")
	loginLimiter := middleware.RateLimit(loginRateLimit, loginRateWindow)
	bodyLimit := middleware.MaxBodyBytes(maxJSONBodyBytes)

	api := r.Group("/api")
	{
		authGroup := api.Group("/auth")
		authGroup.Use(bodyLimit)
		{
			authGroup.POST("/login", loginLimiter, h.Auth.Login)
			authGroup.GET("/me", auth, h.Auth.Me)
			authGroup.POST("/change-password", auth, h.Auth.ChangePassword)
		}

		api.POST("/users", bodyLimit, auth, adminOnly, h.Api.CreateUser)

		api.GET("/realtime", auth, h.Realtime.Connect)

		protected := api.Group("/")
		protected.Use(bodyLimit, auth)
		{

			protected.GET("/users", h.Api.GetUsers)
			protected.GET("/classmates", h.Api.GetClassmates)
			protected.PUT("/users/:id", h.Api.UpdateUser)
			protected.PUT("/users/:id/password", h.Api.ResetPassword)
			protected.DELETE("/users/:id", h.Api.DeleteUser)

			protected.GET("/stream", h.Stream.Resolve)

			protected.GET("/progress/me", h.Realtime.MyProgress)
			protected.POST("/progress", h.Realtime.ReportProgress)
			protected.GET("/monitoring/progress", staffOnly, h.Realtime.ListProgress)

			protected.GET("/lectures", h.Api.GetLectures)
			protected.POST("/lectures", h.Api.CreateLecture)
			protected.PUT("/lectures/:id", h.Api.UpdateLecture)
			protected.DELETE("/lectures/:id", h.Api.DeleteLecture)

			protected.GET("/comments", h.Api.GetComments)
			protected.POST("/comments", h.Api.CreateComment)
			protected.PUT("/comments/:id", h.Api.UpdateComment)
			protected.DELETE("/comments/:id", h.Api.DeleteComment)
			protected.GET("/ratings", h.Api.GetRatings)
			protected.POST("/ratings", h.Api.CreateRating)

			protected.GET("/attendance", h.Api.GetAttendance)
			protected.POST("/attendance", h.Api.CreateAttendance)
			protected.PUT("/attendance/:id", h.Api.UpdateAttendance)
			protected.DELETE("/attendance/:id", h.Api.DeleteAttendance)

			protected.GET("/community/posts", h.Community.ListPosts)
			protected.POST("/community/posts", h.Community.CreatePost)
			protected.PUT("/community/posts/:id", h.Community.UpdatePost)
			protected.DELETE("/community/posts/:id", h.Community.DeletePost)
			protected.POST("/community/posts/:id/pin", adminOnly, h.Community.TogglePin)
			protected.GET("/community/posts/:id/comments", h.Community.ListComments)
			protected.POST("/community/posts/:id/comments", h.Community.CreateComment)
			protected.DELETE("/community/posts/:id/comments/:commentId", h.Community.DeleteComment)
			protected.POST("/community/posts/:id/report", h.Community.CreateReport)
			protected.GET("/community/reports", adminOnly, h.Community.ListReports)
			protected.PUT("/community/reports/:id", adminOnly, h.Community.ResolveReport)
		}

		uploads := api.Group("/uploads")
		uploads.Use(auth)
		{
			uploads.POST("", h.Upload.Upload)
			uploads.POST("/chunked/init", h.Upload.InitiateChunkedUpload)
			uploads.POST("/chunked/:uploadId/chunk/:index", h.Upload.UploadChunk)
			uploads.GET("/chunked/:uploadId/status", h.Upload.GetChunkedUploadStatus)
			uploads.POST("/chunked/:uploadId/complete", h.Upload.CompleteChunkedUpload)
		}
	}

	return r
}

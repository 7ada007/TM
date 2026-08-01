package main

import (
	"context"
	"crypto/tls"
	"fmt"
	"mime"
	"net/http"
	"os"
	"os/signal"
	"path/filepath"
	"syscall"
	"time"

	"github.com/tareeqmajdapp/backend/internal/config"
	"github.com/tareeqmajdapp/backend/internal/database"
	"github.com/tareeqmajdapp/backend/internal/handlers"
	"github.com/tareeqmajdapp/backend/internal/logger"
	"github.com/tareeqmajdapp/backend/internal/models"
	"github.com/tareeqmajdapp/backend/internal/notifications"
	"github.com/tareeqmajdapp/backend/internal/realtime"
	"github.com/tareeqmajdapp/backend/internal/repository"
	"github.com/tareeqmajdapp/backend/internal/routes"
	"github.com/tareeqmajdapp/backend/internal/security"
	"github.com/tareeqmajdapp/backend/internal/services"
	"github.com/tareeqmajdapp/backend/internal/transcoder"
	"github.com/tareeqmajdapp/backend/internal/utils"
)

func setupLogging() *os.File {
	if err := os.MkdirAll("logs", 0755); err != nil {

		os.Stderr.WriteString("Failed to create logs directory: " + err.Error() + "\n")
		os.Exit(1)
	}
	logFile, err := os.OpenFile(filepath.Join("logs", "server.log"), os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err != nil {
		os.Stderr.WriteString("Failed to open log file: " + err.Error() + "\n")
		os.Exit(1)
	}
	logger.SetOutput(os.Stdout, logFile)
	return logFile
}

func main() {
	logFile := setupLogging()
	defer logFile.Close()

	cfg := config.LoadConfig()

	certPath := filepath.Join("certs", "cert.pem")
	keyPath := filepath.Join("certs", "key.pem")

	allowSelfSigned := cfg.Environment != "production"
	if err := utils.EnsureCertsExists(certPath, keyPath, cfg.TLSHost, allowSelfSigned); err != nil {
		logger.Fatal("TLS certificate error: %v", err)
	}

	uploadsDir := "uploads"
	for _, sub := range []string{"videos", "images", "documents", "tmp", "hls"} {
		if err := os.MkdirAll(filepath.Join(uploadsDir, sub), 0755); err != nil {
			logger.Fatal("Failed to create uploads directory: %v", err)
		}
	}

	_ = mime.AddExtensionType(".m3u8", "application/vnd.apple.mpegurl")
	_ = mime.AddExtensionType(".ts", "video/mp2t")

	db, err := database.Open(cfg.DBPath)
	if err != nil {
		logger.Fatal("Failed to open database: %v", err)
	}
	defer db.Close()

	userRepo := repository.NewUserRepository(db)
	lectureRepo := repository.NewLectureRepository(db)
	commentRepo := repository.NewCommentRepository(db)
	ratingRepo := repository.NewRatingRepository(db)
	attendanceRepo := repository.NewAttendanceRepository(db)
	communityRepo := repository.NewCommunityRepository(db)
	progressRepo := repository.NewProgressRepository(db)

	pushClient := notifications.NewClient(cfg.OneSignalAppID, cfg.OneSignalKey)
	notifier := notifications.NewNotifier(pushClient, notifications.NewRepoAudience(userRepo))

	authService := services.NewAuthService(userRepo, cfg.JWTSecret)

	tc := transcoder.New(uploadsDir)
	tc.Start()
	go tc.Reconcile()

	lockout := security.NewLockout()
	defer lockout.Stop()

	authHandler := handlers.NewAuthHandler(authService, userRepo, lockout)
	apiHandler := handlers.NewApiHandler(userRepo, lectureRepo, commentRepo, ratingRepo, attendanceRepo, notifier)
	uploadHandler := handlers.NewUploadHandler(uploadsDir, tc)
	communityHandler := handlers.NewCommunityHandler(communityRepo, notifier)
	streamHandler := handlers.NewStreamHandler(tc)

	if notifier.Enabled() {
		logger.Info("Push notifications enabled (OneSignal app %s)", cfg.OneSignalAppID)
	} else {
		logger.Warn("Push notifications disabled — academic events will not be delivered to devices")
	}

	hub := realtime.NewHub(progressRepo)
	go hub.Run()
	realtimeHandler := handlers.NewRealtimeHandler(hub, progressRepo)

	seedAdmins(userRepo, cfg.Environment == "production")

	r := routes.SetupRouter(&routes.Handlers{
		Auth:      authHandler,
		Api:       apiHandler,
		Upload:    uploadHandler,
		Community: communityHandler,
		Stream:    streamHandler,
		Realtime:  realtimeHandler,
	}, db, userRepo, uploadsDir, routes.Security{
		JWTSecret:      cfg.JWTSecret,
		Environment:    cfg.Environment,
		AllowedOrigins: cfg.AllowedOrigins,
		TrustedProxies: cfg.TrustedProxies,
	})

	go func() {
		ticker := time.NewTicker(1 * time.Hour)
		defer ticker.Stop()
		uploadHandler.CleanupStaleChunkedUploads()
		for range ticker.C {
			uploadHandler.CleanupStaleChunkedUploads()
		}
	}()

	srv := &http.Server{
		Addr:    ":" + cfg.Port,
		Handler: r,

		ReadTimeout:  10 * time.Minute,
		WriteTimeout: 10 * time.Minute,
		IdleTimeout:  2 * time.Minute,

		ReadHeaderTimeout: 20 * time.Second,
		MaxHeaderBytes:    1 << 20,

		TLSConfig: &tls.Config{
			MinVersion: tls.VersionTLS12,
			CurvePreferences: []tls.CurveID{
				tls.X25519,
				tls.CurveP256,
			},
			CipherSuites: []uint16{
				tls.TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,
				tls.TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,
				tls.TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,
				tls.TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,
				tls.TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,
				tls.TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,
			},
		},
	}

	go func() {
		logger.Info("Starting secure server on port %s (env=%s, db=%s)", cfg.Port, cfg.Environment, cfg.DBPath)
		if err := srv.ListenAndServeTLS(certPath, keyPath); err != nil && err != http.ErrServerClosed {
			logger.Fatal("Failed to start server: %v", err)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	logger.Info("Shutdown signal received, draining in-flight requests...")

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		logger.Fatal("Server forced to shutdown: %v", err)
	}
	hub.Stop()
	logger.Info("Server exited cleanly")
}

type adminSeed struct {
	id              string
	name            string
	username        string
	password        string
	legacyPasswords []string
}

func seedAdmins(userRepo *repository.UserRepository, production bool) {
	seeds := []adminSeed{
		{
			id:       "admin-1",
			name:     "جعفر منصور حمد",
			username: getEnvOr("ADMIN_1_USERNAME", "Jaffar"),
			password: os.Getenv("ADMIN_1_PASSWORD"),
		},
		{
			id:       "admin-2",
			name:     "حيدر منصور حمد",
			username: getEnvOr("ADMIN_2_USERNAME", "Hayder"),
			password: os.Getenv("ADMIN_2_PASSWORD"),
		},
	}

	for _, s := range seeds {
		if s.password == "" {
			if production {
				logger.Warn("Admin seed %q skipped: no password configured. Set its ADMIN_*_PASSWORD env var to provision or rotate this account.", s.id)
			}
			continue
		}
		if err := reconcileAdmin(userRepo, s); err != nil {

			logger.Error("Admin seed %q: %v", s.id, err)
		}
	}
}

func getEnvOr(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func reconcileAdmin(userRepo *repository.UserRepository, s adminSeed) error {
	existing, err := userRepo.GetByID(s.id)
	if err != nil {
		return fmt.Errorf("lookup by id: %w", err)
	}

	if existing == nil {
		taken, err := userRepo.UsernameTaken(s.username, s.id)
		if err != nil {
			return fmt.Errorf("username availability check: %w", err)
		}
		if taken {
			return fmt.Errorf("cannot create administrator: username %q already belongs to another account", s.username)
		}

		hash, err := utils.HashPassword(s.password)
		if err != nil {
			return fmt.Errorf("hash password: %w", err)
		}

		if err := userRepo.Create(&models.User{
			ID:                s.id,
			Name:              s.name,
			Username:          s.username,
			PasswordHash:      hash,
			TokenVersion:      1,
			Gender:            "ذكر",
			Subjects:          []string{},
			Role:              models.RoleAdmin,
			CanUploadLectures: true,
			CreatedAt:         time.Now().UTC().Format(time.RFC3339),
		}); err != nil {
			return fmt.Errorf("create: %w", err)
		}

		logger.Info("Seeded administrator account: %s (%s)", s.name, s.username)
		return nil
	}

	if existing.Username != s.username {
		taken, err := userRepo.UsernameTaken(s.username, s.id)
		if err != nil {
			return fmt.Errorf("username availability check: %w", err)
		}
		if taken {
			logger.Warn("Administrator %q keeps username %q — desired username %q is already used by another account",
				s.id, existing.Username, s.username)
		} else {
			previous := existing.Username
			existing.Username = s.username

			if err := userRepo.Update(existing); err != nil {
				return fmt.Errorf("rename %q -> %q: %w", previous, s.username, err)
			}
			logger.Info("Administrator %q renamed: %s -> %s", s.id, previous, s.username)
		}
	}

	if utils.VerifyPassword(existing.PasswordHash, s.password) {
		return nil
	}

	for _, legacy := range s.legacyPasswords {
		if !utils.VerifyPassword(existing.PasswordHash, legacy) {
			continue
		}
		hash, err := utils.HashPassword(s.password)
		if err != nil {
			return fmt.Errorf("hash rotated password: %w", err)
		}
		if err := userRepo.UpdatePassword(s.id, hash); err != nil {
			return fmt.Errorf("rotate password: %w", err)
		}
		logger.Info("Administrator %q password rotated from a previous default; existing sessions invalidated", s.username)
		return nil
	}

	return nil
}

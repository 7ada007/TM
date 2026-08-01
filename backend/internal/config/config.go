package config

import (
	"os"
	"strings"

	"github.com/joho/godotenv"
	"github.com/tareeqmajdapp/backend/internal/logger"
)

type Config struct {
	Port           string
	DBPath         string
	JWTSecret      string
	Environment    string
	TLSHost        string
	OneSignalAppID string
	OneSignalKey   string
	AllowedOrigins []string
	TrustedProxies []string
}

func LoadConfig() *Config {
	_ = godotenv.Load()

	env := getEnv("ENVIRONMENT", "development")
	secret := getEnv("JWT_SECRET", "")

	if secret == "" {
		if env == "production" {
			logger.Fatal("JWT_SECRET must be set in production — refusing to start with no secret configured")
		}
		secret = "dev_only_insecure_secret_do_not_use_in_production"
		logger.Warn("JWT_SECRET not set — using an insecure development default. Set JWT_SECRET before deploying.")
	}

	// The App ID identifies the app and is embedded in the client anyway, so it
	// carries a default. The REST key can send a notification to every user of
	// the platform, so it is never defaulted and never committed.
	oneSignalAppID := getEnv("ONESIGNAL_APP_ID", "07275e82-faf0-479e-8e68-9036649101ce")
	oneSignalKey := getEnv("ONESIGNAL_REST_API_KEY", "")
	if oneSignalKey == "" {
		logger.Warn("ONESIGNAL_REST_API_KEY not set — push notifications are disabled; academic events will not reach devices")
	}

	origins := splitList(getEnv("ALLOWED_ORIGINS", ""))
	if len(origins) == 0 {
		logger.Info("ALLOWED_ORIGINS not set — browser cross-origin requests are refused (native app traffic is unaffected)")
	} else {
		logger.Info("Browser cross-origin requests allowed from: %s", strings.Join(origins, ", "))
	}

	proxies := splitList(getEnv("TRUSTED_PROXIES", ""))

	return &Config{
		Port:           getEnv("PORT", "8443"),
		DBPath:         getEnv("DB_PATH", "data/app.db"),
		JWTSecret:      secret,
		Environment:    env,
		TLSHost:        getEnv("TLS_HOST", "api.tareeqalmajd.best"),
		OneSignalAppID: oneSignalAppID,
		OneSignalKey:   oneSignalKey,
		AllowedOrigins: origins,
		TrustedProxies: proxies,
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func splitList(raw string) []string {
	if strings.TrimSpace(raw) == "" {
		return nil
	}
	parts := strings.Split(raw, ",")
	out := make([]string, 0, len(parts))
	for _, p := range parts {
		if trimmed := strings.TrimSpace(p); trimmed != "" {
			out = append(out, trimmed)
		}
	}
	return out
}

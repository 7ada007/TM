package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

const hstsValue = "max-age=63072000; includeSubDomains; preload"

const apiContentSecurityPolicy = "default-src 'none'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'"

const permissionsPolicy = "accelerometer=(), autoplay=(), camera=(), display-capture=(), encrypted-media=(), " +
	"fullscreen=(), geolocation=(), gyroscope=(), magnetometer=(), microphone=(), midi=(), payment=(), " +
	"picture-in-picture=(), publickey-credentials-get=(), screen-wake-lock=(), usb=(), xr-spatial-tracking=()"

func SecurityHeaders(enableHSTS bool) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("X-Content-Type-Options", "nosniff")
		c.Header("X-Frame-Options", "DENY")
		c.Header("Referrer-Policy", "no-referrer")
		c.Header("Content-Security-Policy", apiContentSecurityPolicy)
		c.Header("Permissions-Policy", permissionsPolicy)
		c.Header("Cross-Origin-Opener-Policy", "same-origin")
		c.Header("Cross-Origin-Resource-Policy", "same-site")
		c.Header("X-Permitted-Cross-Domain-Policies", "none")
		c.Header("Cache-Control", "no-store")

		if enableHSTS {
			c.Header("Strict-Transport-Security", hstsValue)
		}

		c.Next()
	}
}

func MaxBodyBytes(max int64) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, max)
		c.Next()
	}
}

func CORS(allowedOrigins []string) gin.HandlerFunc {
	allowed := make(map[string]bool, len(allowedOrigins))
	for _, origin := range allowedOrigins {
		origin = strings.TrimSpace(origin)
		if origin != "" {
			allowed[strings.ToLower(origin)] = true
		}
	}

	return func(c *gin.Context) {
		origin := c.GetHeader("Origin")

		if origin != "" && allowed[strings.ToLower(origin)] {
			c.Header("Access-Control-Allow-Origin", origin)
			c.Header("Access-Control-Allow-Credentials", "true")
			c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
			c.Header("Access-Control-Allow-Headers", "Authorization, Content-Type")
			c.Header("Access-Control-Max-Age", "600")
			c.Header("Vary", "Origin")
		} else if origin != "" {
			c.Header("Vary", "Origin")
			if c.Request.Method == http.MethodOptions {
				c.AbortWithStatus(http.StatusForbidden)
				return
			}
		}

		if c.Request.Method == http.MethodOptions {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}

		c.Next()
	}
}

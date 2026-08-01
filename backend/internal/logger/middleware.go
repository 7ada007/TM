package logger

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

func GinMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path
		if raw := c.Request.URL.RawQuery; raw != "" {
			path += "?" + raw
		}

		c.Next()

		Request(c.Request.Method, path, c.Writer.Status(), time.Since(start), c.ClientIP())
	}
}

func GinRecovery() gin.HandlerFunc {
	return func(c *gin.Context) {
		defer func() {
			if r := recover(); r != nil {
				Error("panic recovered: %v [%s %s]", r, c.Request.Method, c.Request.URL.Path)
				c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{"error": "حدث خطأ غير متوقع في الخادم"})
			}
		}()
		c.Next()
	}
}

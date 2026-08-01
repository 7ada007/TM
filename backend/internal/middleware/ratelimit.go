package middleware

import (
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/tareeqmajdapp/backend/internal/httpx"
)

func RateLimit(max int, window time.Duration) gin.HandlerFunc {
	type entry struct {
		count     int
		windowEnd time.Time
	}

	var (
		mu      sync.Mutex
		clients = make(map[string]*entry)
	)

	go func() {
		ticker := time.NewTicker(10 * time.Minute)
		defer ticker.Stop()
		for range ticker.C {
			mu.Lock()
			now := time.Now()
			for ip, e := range clients {
				if now.After(e.windowEnd) {
					delete(clients, ip)
				}
			}
			mu.Unlock()
		}
	}()

	return func(c *gin.Context) {
		ip := c.ClientIP()
		now := time.Now()

		mu.Lock()
		e, ok := clients[ip]
		if !ok || now.After(e.windowEnd) {
			e = &entry{count: 0, windowEnd: now.Add(window)}
			clients[ip] = e
		}
		e.count++
		blocked := e.count > max
		mu.Unlock()

		if blocked {
			httpx.Abort(c, http.StatusTooManyRequests, "عدد كبير جداً من المحاولات، يرجى الانتظار قليلاً قبل إعادة المحاولة")
			return
		}
		c.Next()
	}
}

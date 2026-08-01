package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/tareeqmajdapp/backend/internal/httpx"
	"github.com/tareeqmajdapp/backend/internal/repository"
	"github.com/tareeqmajdapp/backend/internal/services"
)

func parseBearerToken(c *gin.Context, jwtSecret string) (*services.Claims, bool) {
	authHeader := c.GetHeader("Authorization")
	if authHeader == "" {
		return nil, false
	}
	parts := strings.SplitN(authHeader, " ", 2)
	if len(parts) != 2 || !strings.EqualFold(parts[0], "bearer") {
		return nil, false
	}

	claims := &services.Claims{}
	token, err := jwt.ParseWithClaims(parts[1], claims, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, jwt.ErrTokenSignatureInvalid
		}
		return []byte(jwtSecret), nil
	})
	if err != nil || !token.Valid {
		return nil, false
	}
	return claims, true
}

func AuthRequired(jwtSecret string, userRepo *repository.UserRepository) gin.HandlerFunc {
	return func(c *gin.Context) {
		claims, ok := parseBearerToken(c, jwtSecret)
		if !ok {
			httpx.Abort(c, http.StatusUnauthorized, "جلسة غير صالحة أو منتهية الصلاحية، يرجى تسجيل الدخول مجدداً")
			return
		}

		user, err := userRepo.GetByID(claims.UserID)
		if err != nil {
			httpx.Abort(c, http.StatusInternalServerError, "تعذّر التحقق من الجلسة")
			return
		}
		if user == nil || user.TokenVersion != claims.TokenVersion {
			httpx.Abort(c, http.StatusUnauthorized, "انتهت صلاحية الجلسة، يرجى تسجيل الدخول مجدداً")
			return
		}

		c.Set("userID", user.ID)
		c.Set("userRole", string(user.Role))
		c.Set("userGender", user.Gender)
		c.Set("currentUser", user)
		c.Next()
	}
}

func RequireRole(roles ...string) gin.HandlerFunc {
	allowed := make(map[string]bool, len(roles))
	for _, r := range roles {
		allowed[r] = true
	}
	return func(c *gin.Context) {
		role, _ := c.Get("userRole")
		roleStr, _ := role.(string)
		if !allowed[roleStr] {
			httpx.Abort(c, http.StatusForbidden, httpx.MsgForbidden)
			return
		}
		c.Next()
	}
}

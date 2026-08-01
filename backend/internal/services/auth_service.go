package services

import (
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/tareeqmajdapp/backend/internal/models"
	"github.com/tareeqmajdapp/backend/internal/repository"
	"github.com/tareeqmajdapp/backend/internal/utils"
)

const tokenTTL = 90 * 24 * time.Hour

var ErrInvalidCredentials = errors.New("invalid username or password")

type AuthService struct {
	userRepo  *repository.UserRepository
	jwtSecret string
}

func NewAuthService(userRepo *repository.UserRepository, jwtSecret string) *AuthService {
	return &AuthService{userRepo: userRepo, jwtSecret: jwtSecret}
}

type Claims struct {
	UserID       string `json:"sub"`
	Role         string `json:"role"`
	Gender       string `json:"gender"`
	TokenVersion int    `json:"tokenVersion"`
	jwt.RegisteredClaims
}

func (s *AuthService) Authenticate(username, password string) (*models.User, error) {
	user, err := s.userRepo.GetByUsername(username)
	if err != nil {
		return nil, err
	}
	if user == nil {

		utils.VerifyPassword("$2a$12$invalidinvalidinvalidinvalidinvalidinvalidinvalidinvalid", password)
		return nil, ErrInvalidCredentials
	}
	if !utils.VerifyPassword(user.PasswordHash, password) {
		return nil, ErrInvalidCredentials
	}
	return user, nil
}

func (s *AuthService) GenerateToken(user *models.User) (string, error) {
	claims := Claims{
		UserID:       user.ID,
		Role:         string(user.Role),
		Gender:       user.Gender,
		TokenVersion: user.TokenVersion,
		RegisteredClaims: jwt.RegisteredClaims{
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(tokenTTL)),
			Subject:   user.ID,
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(s.jwtSecret))
}

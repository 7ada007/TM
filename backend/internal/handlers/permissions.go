package handlers

import (
	"time"

	"github.com/tareeqmajdapp/backend/internal/models"
)

const commentEditWindow = 14 * time.Minute

const superAdminID = "admin-1"

func isAdmin(u *models.User) bool { return u != nil && u.Role == models.RoleAdmin }

func isTeacher(u *models.User) bool { return u != nil && u.Role == models.RoleTeacher }

func isSuperAdmin(u *models.User) bool {
	return u != nil && u.ID == superAdminID && u.Role == models.RoleAdmin
}

func canUploadLectures(u *models.User) bool {
	if u == nil {
		return false
	}
	return isAdmin(u) || (isTeacher(u) && u.CanUploadLectures)
}

func canManageLecture(actor *models.User, lecture *models.Lecture) bool {
	if actor == nil || lecture == nil {
		return false
	}
	if isAdmin(actor) {
		return true
	}
	return isTeacher(actor) && actor.ID == lecture.TeacherID
}

func canDeleteUser(actor *models.User, target *models.User) bool {
	if !isAdmin(actor) {
		return false
	}
	if isSuperAdmin(actor) {
		return actor.ID != target.ID
	}
	if isSuperAdmin(target) {
		return false
	}
	if target.Role == models.RoleAdmin {
		return false
	}
	return true
}

func canChangeRole(actor *models.User, target *models.User, newRole models.Role) bool {
	if !isAdmin(actor) {
		return false
	}
	if target.Role == models.RoleAdmin && target.ID != actor.ID {
		return false
	}
	if newRole == models.RoleAdmin && target.Role != models.RoleAdmin {
		return true
	}
	if target.Role == models.RoleAdmin {
		return false
	}
	return true
}

func canResetPassword(actor *models.User, target *models.User) bool {
	if !isAdmin(actor) {
		return false
	}
	if isSuperAdmin(target) {
		return actor.ID == target.ID
	}
	return true
}

func canEditOrDeleteComment(actor *models.User, comment *models.Comment, now time.Time) bool {
	if isAdmin(actor) {
		return true
	}
	if actor == nil || comment == nil || actor.ID != comment.UserID {
		return false
	}
	created, err := time.Parse(time.RFC3339, comment.CreatedAt)
	if err != nil {
		return false
	}
	return now.Sub(created) < commentEditWindow
}

func canManageAttendance(u *models.User) bool {
	return isAdmin(u) || isTeacher(u)
}

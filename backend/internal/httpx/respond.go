package httpx

import "github.com/gin-gonic/gin"

func Error(c *gin.Context, status int, message string) {
	c.JSON(status, gin.H{"error": message})
}

func Abort(c *gin.Context, status int, message string) {
	c.AbortWithStatusJSON(status, gin.H{"error": message})
}

func Message(c *gin.Context, status int, message string) {
	c.JSON(status, gin.H{"message": message})
}

const (
	MsgServerError    = "حدث خطأ في الخادم"
	MsgMissingFields  = "الحقول المطلوبة غير مكتملة"
	MsgForbidden      = "غير مصرح لك بتنفيذ هذا الإجراء"
	MsgLoginRequired  = "يرجى تسجيل الدخول"
	MsgUserNotFound   = "المستخدم غير موجود"
	MsgInvalidRequest = "بيانات الطلب غير صالحة"
)

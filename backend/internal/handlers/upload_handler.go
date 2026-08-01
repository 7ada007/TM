package handlers

import (
	"bytes"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"image"
	_ "image/gif"
	_ "image/jpeg"
	_ "image/png"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/gen2brain/webp"
	"github.com/gin-gonic/gin"
	"github.com/tareeqmajdapp/backend/internal/httpx"
	"github.com/tareeqmajdapp/backend/internal/logger"
	"github.com/tareeqmajdapp/backend/internal/transcoder"
)

func randomFileToken() string {
	buf := make([]byte, 8)
	_, _ = rand.Read(buf)
	return fmt.Sprintf("%d-%s", time.Now().UnixNano(), hex.EncodeToString(buf))
}

type UploadHandler struct {
	uploadsDir string
	maxBytes   int64
	tc         *transcoder.Transcoder
}

func NewUploadHandler(uploadsDir string, tc *transcoder.Transcoder) *UploadHandler {
	return &UploadHandler{
		uploadsDir: uploadsDir,
		maxBytes:   512 * 1024 * 1024,
		tc:         tc,
	}
}

var allowedUploadExtensions = map[string][]string{
	"videos":    {".mp4", ".mov", ".m4v", ".webm"},
	"images":    {".jpg", ".jpeg", ".png", ".webp", ".gif"},
	"documents": {".pdf"},
}

func kindForExtension(ext string) (string, bool) {
	ext = strings.ToLower(ext)
	for kind, exts := range allowedUploadExtensions {
		for _, allowed := range exts {
			if ext == allowed {
				return kind, true
			}
		}
	}
	return "", false
}

const webpQuality = 80
const webpMethod = 4

func isWebpConvertible(ext string) bool {
	switch strings.ToLower(ext) {
	case ".jpg", ".jpeg", ".png":
		return true
	default:
		return false
	}
}

func convertImageToWebP(absPath, relPath string) (string, string) {
	ext := filepath.Ext(absPath)
	if !isWebpConvertible(ext) {
		return absPath, relPath
	}

	src, err := os.Open(absPath)
	if err != nil {
		logger.Warn("webp: open %s: %v", absPath, err)
		return absPath, relPath
	}
	img, _, decErr := image.Decode(src)
	src.Close()
	if decErr != nil {
		logger.Warn("webp: decode %s: %v", absPath, decErr)
		return absPath, relPath
	}

	var buf bytes.Buffer
	if err := webp.Encode(&buf, img, webp.Options{Quality: webpQuality, Method: webpMethod}); err != nil {
		logger.Warn("webp: encode %s: %v", absPath, err)
		return absPath, relPath
	}

	newAbs := strings.TrimSuffix(absPath, ext) + ".webp"
	if err := os.WriteFile(newAbs, buf.Bytes(), 0644); err != nil {
		logger.Warn("webp: write %s: %v", newAbs, err)
		return absPath, relPath
	}
	if newAbs != absPath {
		_ = os.Remove(absPath)
	}
	newRel := strings.TrimSuffix(relPath, ext) + ".webp"
	return newAbs, newRel
}

func sniffContentMismatch(f io.ReadSeeker, kind string) error {
	buf := make([]byte, 512)
	n, err := f.Read(buf)
	if err != nil && err != io.EOF {
		return err
	}
	if _, err := f.Seek(0, io.SeekStart); err != nil {
		return err
	}

	sniffed := http.DetectContentType(buf[:n])

	switch kind {
	case "images":
		if !strings.HasPrefix(sniffed, "image/") {
			return fmt.Errorf("expected an image, detected %q", sniffed)
		}
	case "documents":
		if sniffed != "application/pdf" {
			return fmt.Errorf("expected a PDF, detected %q", sniffed)
		}
	default:
		if strings.HasPrefix(sniffed, "text/") {
			return fmt.Errorf("unexpected content type %q for a video upload", sniffed)
		}
	}
	return nil
}

func (h *UploadHandler) Upload(c *gin.Context) {
	if err := c.Request.ParseMultipartForm(h.maxBytes); err != nil {
		httpx.Error(c, http.StatusBadRequest, "الملف كبير جداً أو تالف")
		return
	}

	fileHeader, err := c.FormFile("file")
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "لم يتم إرفاق أي ملف")
		return
	}

	if fileHeader.Size > h.maxBytes {
		httpx.Error(c, http.StatusRequestEntityTooLarge, "حجم الملف يتجاوز الحد المسموح")
		return
	}
	if fileHeader.Size == 0 {
		httpx.Error(c, http.StatusBadRequest, "الملف فارغ")
		return
	}

	ext := filepath.Ext(fileHeader.Filename)
	kind, ok := kindForExtension(ext)
	if !ok {
		httpx.Error(c, http.StatusBadRequest, "نوع الملف غير مدعوم")
		return
	}

	if opened, openErr := fileHeader.Open(); openErr == nil {
		mismatchErr := sniffContentMismatch(opened, kind)
		opened.Close()
		if mismatchErr != nil {
			httpx.Error(c, http.StatusBadRequest, "محتوى الملف لا يطابق نوعه المعلن")
			return
		}
	}

	filename := fmt.Sprintf("%s%s", randomFileToken(), ext)
	destRelative := filepath.Join(kind, filename)
	destAbsolute := filepath.Join(h.uploadsDir, destRelative)

	if err := c.SaveUploadedFile(fileHeader, destAbsolute); err != nil {
		httpx.Error(c, http.StatusInternalServerError, "تعذّر حفظ الملف")
		return
	}

	if kind == "images" {
		_, destRelative = convertImageToWebP(destAbsolute, destRelative)
	} else if kind == "videos" && h.tc != nil {
		h.tc.Enqueue(destAbsolute)
	}

	urlPath := "/uploads/" + filepath.ToSlash(destRelative)

	c.JSON(http.StatusCreated, gin.H{
		"url":      urlPath,
		"kind":     kind,
		"fileName": fileHeader.Filename,
		"size":     fileHeader.Size,
	})
}

var uploadIDPattern = regexp.MustCompile(`^[0-9a-fA-F-]{8,128}$`)

const chunkedUploadTTL = 24 * time.Hour
const maxChunkBytes = 16 * 1024 * 1024

type chunkedUploadMeta struct {
	FileName    string    `json:"fileName"`
	Extension   string    `json:"extension"`
	Kind        string    `json:"kind"`
	FileSize    int64     `json:"fileSize"`
	TotalChunks int       `json:"totalChunks"`
	CreatedAt   time.Time `json:"createdAt"`
}

type initChunkedUploadRequest struct {
	FileName    string `json:"fileName" binding:"required"`
	FileSize    int64  `json:"fileSize" binding:"required"`
	TotalChunks int    `json:"totalChunks" binding:"required"`
}

func (h *UploadHandler) tmpDir(uploadID string) string {
	return filepath.Join(h.uploadsDir, "tmp", uploadID)
}

func (h *UploadHandler) InitiateChunkedUpload(c *gin.Context) {
	var req initChunkedUploadRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		httpx.Error(c, http.StatusBadRequest, httpx.MsgInvalidRequest)
		return
	}

	if req.FileSize <= 0 || req.FileSize > h.maxBytes {
		httpx.Error(c, http.StatusBadRequest, "حجم الملف غير صالح أو يتجاوز الحد المسموح")
		return
	}
	if req.TotalChunks <= 0 || req.TotalChunks > 100000 {
		httpx.Error(c, http.StatusBadRequest, "عدد الأجزاء غير صالح")
		return
	}

	ext := filepath.Ext(req.FileName)
	kind, ok := kindForExtension(ext)
	if !ok {
		httpx.Error(c, http.StatusBadRequest, "نوع الملف غير مدعوم")
		return
	}

	uploadID := randomFileToken()
	dir := h.tmpDir(uploadID)
	if err := os.MkdirAll(dir, 0755); err != nil {
		httpx.Error(c, http.StatusInternalServerError, "تعذّر بدء جلسة الرفع")
		return
	}

	meta := chunkedUploadMeta{
		FileName:    req.FileName,
		Extension:   ext,
		Kind:        kind,
		FileSize:    req.FileSize,
		TotalChunks: req.TotalChunks,
		CreatedAt:   time.Now().UTC(),
	}
	metaBytes, err := json.Marshal(meta)
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, "تعذّر بدء جلسة الرفع")
		return
	}
	if err := os.WriteFile(filepath.Join(dir, "meta.json"), metaBytes, 0644); err != nil {
		httpx.Error(c, http.StatusInternalServerError, "تعذّر بدء جلسة الرفع")
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"uploadId":    uploadID,
		"totalChunks": req.TotalChunks,
	})
}

func (h *UploadHandler) loadMeta(uploadID string) (*chunkedUploadMeta, error) {
	data, err := os.ReadFile(filepath.Join(h.tmpDir(uploadID), "meta.json"))
	if err != nil {
		return nil, err
	}
	var meta chunkedUploadMeta
	if err := json.Unmarshal(data, &meta); err != nil {
		return nil, err
	}
	return &meta, nil
}

func (h *UploadHandler) UploadChunk(c *gin.Context) {
	uploadID := c.Param("uploadId")
	if !uploadIDPattern.MatchString(uploadID) {
		httpx.Error(c, http.StatusBadRequest, "معرّف رفع غير صالح")
		return
	}

	index, err := strconv.Atoi(c.Param("index"))
	if err != nil || index < 0 {
		httpx.Error(c, http.StatusBadRequest, "رقم الجزء غير صالح")
		return
	}

	meta, err := h.loadMeta(uploadID)
	if err != nil {
		httpx.Error(c, http.StatusNotFound, "جلسة الرفع غير موجودة أو انتهت صلاحيتها")
		return
	}
	if index >= meta.TotalChunks {
		httpx.Error(c, http.StatusBadRequest, "رقم الجزء خارج النطاق")
		return
	}

	if err := c.Request.ParseMultipartForm(maxChunkBytes); err != nil {
		httpx.Error(c, http.StatusBadRequest, "جزء الرفع تالف أو كبير جداً")
		return
	}

	fileHeader, err := c.FormFile("chunk")
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "لم يتم إرفاق جزء الملف")
		return
	}

	if index == 0 {
		if opened, openErr := fileHeader.Open(); openErr == nil {
			mismatchErr := sniffContentMismatch(opened, meta.Kind)
			opened.Close()
			if mismatchErr != nil {
				httpx.Error(c, http.StatusBadRequest, "محتوى الملف لا يطابق نوعه المعلن")
				return
			}
		}
	}

	destAbsolute := filepath.Join(h.tmpDir(uploadID), fmt.Sprintf("%d.part", index))
	if err := c.SaveUploadedFile(fileHeader, destAbsolute); err != nil {
		httpx.Error(c, http.StatusInternalServerError, "تعذّر حفظ جزء الملف")
		return
	}

	c.JSON(http.StatusOK, gin.H{"index": index, "received": true})
}

func receivedChunkIndices(dir string) []int {
	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil
	}
	indices := make([]int, 0, len(entries))
	for _, e := range entries {
		if e.IsDir() {
			continue
		}
		name := e.Name()
		if !strings.HasSuffix(name, ".part") {
			continue
		}
		idxStr := strings.TrimSuffix(name, ".part")
		if idx, err := strconv.Atoi(idxStr); err == nil {
			indices = append(indices, idx)
		}
	}
	sort.Ints(indices)
	return indices
}

func (h *UploadHandler) GetChunkedUploadStatus(c *gin.Context) {
	uploadID := c.Param("uploadId")
	if !uploadIDPattern.MatchString(uploadID) {
		httpx.Error(c, http.StatusBadRequest, "معرّف رفع غير صالح")
		return
	}

	meta, err := h.loadMeta(uploadID)
	if err != nil {
		httpx.Error(c, http.StatusNotFound, "جلسة الرفع غير موجودة أو انتهت صلاحيتها")
		return
	}

	received := receivedChunkIndices(h.tmpDir(uploadID))
	c.JSON(http.StatusOK, gin.H{
		"uploadId":       uploadID,
		"totalChunks":    meta.TotalChunks,
		"receivedChunks": received,
		"complete":       len(received) == meta.TotalChunks,
	})
}

func (h *UploadHandler) CompleteChunkedUpload(c *gin.Context) {
	uploadID := c.Param("uploadId")
	if !uploadIDPattern.MatchString(uploadID) {
		httpx.Error(c, http.StatusBadRequest, "معرّف رفع غير صالح")
		return
	}

	meta, err := h.loadMeta(uploadID)
	if err != nil {
		httpx.Error(c, http.StatusNotFound, "جلسة الرفع غير موجودة أو انتهت صلاحيتها")
		return
	}

	dir := h.tmpDir(uploadID)
	received := receivedChunkIndices(dir)
	if len(received) != meta.TotalChunks {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":          "لم يتم استلام جميع الأجزاء بعد",
			"receivedChunks": received,
			"totalChunks":    meta.TotalChunks,
		})
		return
	}

	filename := fmt.Sprintf("%s%s", randomFileToken(), meta.Extension)
	destRelative := filepath.Join(meta.Kind, filename)
	destAbsolute := filepath.Join(h.uploadsDir, destRelative)

	out, err := os.Create(destAbsolute)
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, "تعذّر تجميع الملف المرفوع")
		return
	}

	var totalWritten int64
	for i := 0; i < meta.TotalChunks; i++ {
		partPath := filepath.Join(dir, fmt.Sprintf("%d.part", i))
		in, err := os.Open(partPath)
		if err != nil {
			out.Close()
			_ = os.Remove(destAbsolute)
			httpx.Error(c, http.StatusInternalServerError, "أحد الأجزاء مفقود على الخادم، يرجى إعادة المحاولة")
			return
		}
		written, copyErr := io.Copy(out, in)
		in.Close()
		if copyErr != nil {
			out.Close()
			_ = os.Remove(destAbsolute)
			httpx.Error(c, http.StatusInternalServerError, "تعذّر تجميع الملف المرفوع")
			return
		}
		totalWritten += written
	}
	out.Close()

	if totalWritten != meta.FileSize {
		_ = os.Remove(destAbsolute)
		httpx.Error(c, http.StatusBadRequest, "حجم الملف المجمّع لا يطابق الحجم المعلن، يرجى إعادة المحاولة")
		return
	}

	_ = os.RemoveAll(dir)

	if meta.Kind == "images" {
		_, destRelative = convertImageToWebP(destAbsolute, destRelative)
	} else if meta.Kind == "videos" && h.tc != nil {
		h.tc.Enqueue(destAbsolute)
	}

	urlPath := "/uploads/" + filepath.ToSlash(destRelative)
	c.JSON(http.StatusCreated, gin.H{
		"url":      urlPath,
		"kind":     meta.Kind,
		"fileName": meta.FileName,
		"size":     totalWritten,
	})
}

func (h *UploadHandler) CleanupStaleChunkedUploads() {
	root := filepath.Join(h.uploadsDir, "tmp")
	entries, err := os.ReadDir(root)
	if err != nil {
		return
	}
	cutoff := time.Now().Add(-chunkedUploadTTL)
	for _, e := range entries {
		if !e.IsDir() {
			continue
		}
		dir := filepath.Join(root, e.Name())
		meta, metaErr := h.loadMeta(e.Name())
		stale := metaErr != nil || meta.CreatedAt.Before(cutoff)
		if stale {
			_ = os.RemoveAll(dir)
		}
	}
}

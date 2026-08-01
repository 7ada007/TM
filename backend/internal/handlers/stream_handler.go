package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/tareeqmajdapp/backend/internal/httpx"
	"github.com/tareeqmajdapp/backend/internal/transcoder"
)

type StreamHandler struct {
	tc *transcoder.Transcoder
}

func NewStreamHandler(tc *transcoder.Transcoder) *StreamHandler {
	return &StreamHandler{tc: tc}
}

func (h *StreamHandler) Resolve(c *gin.Context) {
	src := c.Query("src")
	if src == "" {
		httpx.Error(c, http.StatusBadRequest, httpx.MsgInvalidRequest)
		return
	}

	st := h.tc.StatusFor(src)
	play := src
	if st.State == transcoder.StateReady && st.HLS != "" {
		play = st.HLS
	}

	c.JSON(http.StatusOK, gin.H{
		"state":       st.State,
		"progressive": src,
		"hls":         st.HLS,
		"play":        play,
		"variants":    st.Variants,
		"adaptive":    st.State == transcoder.StateReady,
	})
}

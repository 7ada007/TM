package logger

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"sync"
	"time"
)

type Level int

const (
	LevelInfo Level = iota
	LevelWarn
	LevelError
	LevelFatal
)

func (l Level) label() string {
	switch l {
	case LevelWarn:
		return "WARN "
	case LevelError:
		return "ERROR"
	case LevelFatal:
		return "FATAL"
	default:
		return "INFO "
	}
}

const (
	colorReset  = "\x1b[0m"
	colorGray   = "\x1b[90m"
	colorGreen  = "\x1b[32m"
	colorYellow = "\x1b[33m"
	colorRed    = "\x1b[31m"
	colorBold   = "\x1b[1m"
)

func (l Level) color() string {
	switch l {
	case LevelWarn:
		return colorYellow
	case LevelError, LevelFatal:
		return colorRed
	default:
		return colorGreen
	}
}

type Logger struct {
	mu       sync.Mutex
	term     io.Writer
	file     io.Writer
	useColor bool
}

var std = New(os.Stdout, io.Discard)

func New(term io.Writer, file io.Writer) *Logger {
	useColor := false
	if f, ok := term.(*os.File); ok {
		info, err := f.Stat()
		if err == nil && (info.Mode()&os.ModeCharDevice) != 0 {
			useColor = true
		}
	}
	return &Logger{term: term, file: file, useColor: useColor}
}

func SetOutput(term io.Writer, file io.Writer) {
	std = New(term, file)
}

func (lg *Logger) log(level Level, msg string) {
	now := time.Now().Format("15:04:05")

	lg.mu.Lock()
	defer lg.mu.Unlock()

	if lg.file != nil {
		fmt.Fprintf(lg.file, "%s %s %s\n", now, level.label(), msg)
	}

	if lg.term != nil {
		if lg.useColor {
			fmt.Fprintf(lg.term, "%s%s%s %s%s%s %s\n", colorGray, now, colorReset, level.color(), level.label(), colorReset, msg)
		} else {
			fmt.Fprintf(lg.term, "%s %s %s\n", now, level.label(), msg)
		}
	}
}

func (lg *Logger) Info(format string, args ...any)  { lg.log(LevelInfo, fmt.Sprintf(format, args...)) }
func (lg *Logger) Warn(format string, args ...any)  { lg.log(LevelWarn, fmt.Sprintf(format, args...)) }
func (lg *Logger) Error(format string, args ...any) { lg.log(LevelError, fmt.Sprintf(format, args...)) }

func (lg *Logger) Fatal(format string, args ...any) {
	lg.log(LevelFatal, fmt.Sprintf(format, args...))
	os.Exit(1)
}

func Info(format string, args ...any)  { std.Info(format, args...) }
func Warn(format string, args ...any)  { std.Warn(format, args...) }
func Error(format string, args ...any) { std.Error(format, args...) }
func Fatal(format string, args ...any) { std.Fatal(format, args...) }

func (lg *Logger) Request(method, path string, status int, latency time.Duration, clientIP string) {
	now := time.Now().Format("15:04:05")
	lat := formatLatency(latency)

	lg.mu.Lock()
	defer lg.mu.Unlock()

	if lg.file != nil {
		fmt.Fprintf(lg.file, "%s %-6s %3d %8s  %-42s %s\n", now, method, status, lat, path, clientIP)
	}
	if lg.term != nil {
		if lg.useColor {
			fmt.Fprintf(lg.term, "%s%s%s %s%-6s%s %s%3d%s %8s  %-42s %s%s%s\n",
				colorGray, now, colorReset,
				colorBold, method, colorReset,
				statusColor(status), status, colorReset,
				lat, path,
				colorGray, clientIP, colorReset)
		} else {
			fmt.Fprintf(lg.term, "%s %-6s %3d %8s  %-42s %s\n", now, method, status, lat, path, clientIP)
		}
	}
}

func Request(method, path string, status int, latency time.Duration, clientIP string) {
	std.Request(method, path, status, latency, clientIP)
}

func statusColor(status int) string {
	switch {
	case status >= http.StatusInternalServerError:
		return colorRed
	case status >= http.StatusBadRequest:
		return colorYellow
	default:
		return colorGreen
	}
}

func formatLatency(d time.Duration) string {
	switch {
	case d < time.Millisecond:
		return fmt.Sprintf("%dµs", d.Microseconds())
	case d < time.Second:
		return fmt.Sprintf("%.1fms", float64(d.Microseconds())/1000)
	default:
		return d.Round(time.Millisecond).String()
	}
}

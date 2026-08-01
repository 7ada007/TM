package security

import (
	"strings"
	"sync"
	"time"
)

const (
	MaxFailedAttempts = 8
	LockoutDuration   = 15 * time.Minute
	FailureWindow     = 30 * time.Minute
	cleanupInterval   = 10 * time.Minute
)

type attempt struct {
	failures    int
	firstFailAt time.Time
	lockedUntil time.Time
}

type Lockout struct {
	mu       sync.Mutex
	accounts map[string]*attempt
	stop     chan struct{}
}

func NewLockout() *Lockout {
	l := &Lockout{
		accounts: make(map[string]*attempt),
		stop:     make(chan struct{}),
	}
	go l.reap()
	return l
}

func (l *Lockout) Stop() {
	close(l.stop)
}

func normalize(username string) string {
	return strings.ToLower(strings.TrimSpace(username))
}

func (l *Lockout) LockedFor(username string) time.Duration {
	key := normalize(username)
	if key == "" {
		return 0
	}

	l.mu.Lock()
	defer l.mu.Unlock()

	a, ok := l.accounts[key]
	if !ok {
		return 0
	}

	remaining := time.Until(a.lockedUntil)
	if remaining <= 0 {
		return 0
	}
	return remaining
}

func (l *Lockout) RecordFailure(username string) time.Duration {
	key := normalize(username)
	if key == "" {
		return 0
	}

	l.mu.Lock()
	defer l.mu.Unlock()

	now := time.Now()
	a, ok := l.accounts[key]
	if !ok || now.Sub(a.firstFailAt) > FailureWindow {
		a = &attempt{firstFailAt: now}
		l.accounts[key] = a
	}

	a.failures++
	if a.failures >= MaxFailedAttempts {
		a.lockedUntil = now.Add(LockoutDuration)
		a.failures = 0
		a.firstFailAt = now
		return LockoutDuration
	}
	return 0
}

func (l *Lockout) RecordSuccess(username string) {
	key := normalize(username)
	if key == "" {
		return
	}

	l.mu.Lock()
	defer l.mu.Unlock()
	delete(l.accounts, key)
}

func (l *Lockout) reap() {
	ticker := time.NewTicker(cleanupInterval)
	defer ticker.Stop()

	for {
		select {
		case <-l.stop:
			return
		case now := <-ticker.C:
			l.mu.Lock()
			for key, a := range l.accounts {
				if now.After(a.lockedUntil) && now.Sub(a.firstFailAt) > FailureWindow {
					delete(l.accounts, key)
				}
			}
			l.mu.Unlock()
		}
	}
}

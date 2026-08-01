package security

import (
	"sync"
	"testing"
	"time"
)

func TestLockoutTriggersAfterThreshold(t *testing.T) {
	l := NewLockout()
	t.Cleanup(l.Stop)

	for i := 1; i < MaxFailedAttempts; i++ {
		if locked := l.RecordFailure("student"); locked != 0 {
			t.Fatalf("locked too early at attempt %d", i)
		}
		if remaining := l.LockedFor("student"); remaining != 0 {
			t.Fatalf("account must stay open at attempt %d", i)
		}
	}

	if locked := l.RecordFailure("student"); locked != LockoutDuration {
		t.Fatalf("expected lockout of %s, got %s", LockoutDuration, locked)
	}
	if remaining := l.LockedFor("student"); remaining <= 0 {
		t.Fatal("account should report as locked")
	}
}

func TestLockoutIsCaseInsensitive(t *testing.T) {
	l := NewLockout()
	t.Cleanup(l.Stop)

	for range MaxFailedAttempts {
		l.RecordFailure("Student")
	}

	if remaining := l.LockedFor("  sTuDeNt "); remaining <= 0 {
		t.Fatal("lockout must not be bypassable by changing case or padding")
	}
}

func TestSuccessfulLoginClearsFailures(t *testing.T) {
	l := NewLockout()
	t.Cleanup(l.Stop)

	for range MaxFailedAttempts - 1 {
		l.RecordFailure("teacher")
	}
	l.RecordSuccess("teacher")

	for i := 1; i < MaxFailedAttempts; i++ {
		if locked := l.RecordFailure("teacher"); locked != 0 {
			t.Fatalf("counter was not reset; locked at attempt %d", i)
		}
	}
}

func TestLockoutIsPerAccount(t *testing.T) {
	l := NewLockout()
	t.Cleanup(l.Stop)

	for range MaxFailedAttempts {
		l.RecordFailure("victim")
	}

	if l.LockedFor("victim") <= 0 {
		t.Fatal("targeted account should be locked")
	}
	if l.LockedFor("bystander") != 0 {
		t.Fatal("unrelated accounts must not be affected")
	}
}

func TestEmptyUsernameIsIgnored(t *testing.T) {
	l := NewLockout()
	t.Cleanup(l.Stop)

	if locked := l.RecordFailure("   "); locked != 0 {
		t.Fatal("blank usernames must not create lockout entries")
	}
	if remaining := l.LockedFor(""); remaining != 0 {
		t.Fatal("blank usernames must never report as locked")
	}
}

func TestLockoutIsRaceFree(t *testing.T) {
	l := NewLockout()
	t.Cleanup(l.Stop)

	var wg sync.WaitGroup
	for range 50 {
		wg.Add(1)
		go func() {
			defer wg.Done()
			l.RecordFailure("concurrent")
			l.LockedFor("concurrent")
		}()
	}
	wg.Wait()

	if l.LockedFor("concurrent") <= 0 {
		t.Fatal("50 concurrent failures should have locked the account")
	}
}

func TestStaleFailuresExpire(t *testing.T) {
	l := NewLockout()
	t.Cleanup(l.Stop)

	l.mu.Lock()
	l.accounts["stale"] = &attempt{
		failures:    MaxFailedAttempts - 1,
		firstFailAt: time.Now().Add(-FailureWindow - time.Minute),
	}
	l.mu.Unlock()

	if locked := l.RecordFailure("stale"); locked != 0 {
		t.Fatal("failures older than the window must not count toward a lockout")
	}
}

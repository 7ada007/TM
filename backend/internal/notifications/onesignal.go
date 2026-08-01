// Package notifications delivers push notifications to the mobile app.
//
// The transport is OneSignal's REST API. Audiences are always expressed as
// explicit app user IDs (OneSignal "external IDs") rather than tag filters:
// the server already knows exactly who should hear about an event, and a tag
// can be stale for as long as a device stays offline.
package notifications

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/tareeqmajdapp/backend/internal/logger"
)

const (
	apiEndpoint = "https://api.onesignal.com/notifications"

	// OneSignal rejects a request addressed to more than 2000 aliases, so a
	// large audience is split across several calls.
	maxAliasesPerRequest = 2000

	requestTimeout = 15 * time.Second
)

// Message is one notification, already addressed and worded.
type Message struct {
	// Recipients are app user IDs. An empty slice is a no-op, never a
	// broadcast — accidentally paging the whole institute should not be one
	// missing filter away.
	Recipients []string

	Title string
	Body  string

	// Route is the in-app destination opened when the notification is tapped,
	// e.g. "/lecture/abc123". Delivered as custom data; the app validates it
	// before navigating.
	Route string

	// Group collapses related notifications on the device so a burst of
	// lecture uploads does not become a wall of banners.
	Group string
}

// Client sends messages to OneSignal.
//
// A zero-value or unconfigured Client is safe to use and simply drops
// messages, so the rest of the server does not need to branch on whether push
// is set up in this environment.
type Client struct {
	appID  string
	apiKey string
	http   *http.Client

	// endpoint is overridable so tests can point the client at a local stub
	// instead of reaching the real provider.
	endpoint string
}

// NewClient builds a sender. Push is disabled when either credential is
// missing, which is the normal state in local development.
func NewClient(appID, apiKey string) *Client {
	return &Client{
		appID:    strings.TrimSpace(appID),
		apiKey:   strings.TrimSpace(apiKey),
		http:     &http.Client{Timeout: requestTimeout},
		endpoint: apiEndpoint,
	}
}

// Enabled reports whether the client can actually deliver anything.
func (c *Client) Enabled() bool {
	return c != nil && c.appID != "" && c.apiKey != ""
}

// Send delivers a message, splitting oversized audiences across requests.
//
// Errors are returned for the caller to log; they are never fatal. A push that
// fails to send must not fail the request that triggered it.
func (c *Client) Send(ctx context.Context, msg Message) error {
	if !c.Enabled() {
		return nil
	}
	recipients := dedupe(msg.Recipients)
	if len(recipients) == 0 {
		return nil
	}
	if msg.Title == "" || msg.Body == "" {
		return fmt.Errorf("notifications: refusing to send a message with an empty title or body")
	}

	for start := 0; start < len(recipients); start += maxAliasesPerRequest {
		end := min(start+maxAliasesPerRequest, len(recipients))
		if err := c.sendBatch(ctx, msg, recipients[start:end]); err != nil {
			return err
		}
	}
	return nil
}

func (c *Client) sendBatch(ctx context.Context, msg Message, recipients []string) error {
	payload := map[string]any{
		"app_id":         c.appID,
		"target_channel": "push",
		"include_aliases": map[string][]string{
			"external_id": recipients,
		},
		// Arabic is the app's only content language; "en" is the key OneSignal
		// requires for the default localisation, not a claim about the text.
		"headings": map[string]string{"en": msg.Title},
		"contents": map[string]string{"en": msg.Body},
	}

	if msg.Route != "" {
		payload["data"] = map[string]string{"route": msg.Route}
	}
	if msg.Group != "" {
		// Android groups by key; iOS uses thread-id for the same effect.
		payload["android_group"] = msg.Group
		payload["thread_id"] = msg.Group
	}

	body, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("notifications: encode payload: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.endpoint, bytes.NewReader(body))
	if err != nil {
		return fmt.Errorf("notifications: build request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json; charset=utf-8")
	req.Header.Set("Authorization", "Key "+c.apiKey)

	resp, err := c.http.Do(req)
	if err != nil {
		return fmt.Errorf("notifications: request failed: %w", err)
	}
	defer resp.Body.Close()

	// Read a bounded amount: enough to explain a failure, not enough for a
	// hostile or broken response to balloon memory.
	respBody, _ := io.ReadAll(io.LimitReader(resp.Body, 8*1024))

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("notifications: OneSignal returned %d: %s", resp.StatusCode, strings.TrimSpace(string(respBody)))
	}
	return nil
}

// SendAsync delivers a message on its own goroutine.
//
// Used from HTTP handlers so a slow or unreachable push provider cannot add
// latency to — or fail — the user's request. The context is deliberately not
// inherited from the request: the request's context is cancelled the moment
// the response is written, which would abort the send it just triggered.
func (c *Client) SendAsync(msg Message, describe string) {
	if !c.Enabled() || len(msg.Recipients) == 0 {
		return
	}
	go func() {
		ctx, cancel := context.WithTimeout(context.Background(), requestTimeout)
		defer cancel()
		if err := c.Send(ctx, msg); err != nil {
			logger.Warn("Push notification (%s) failed: %v", describe, err)
			return
		}
		logger.Info("Push notification (%s) sent to %d recipient(s)", describe, len(dedupe(msg.Recipients)))
	}()
}

func dedupe(ids []string) []string {
	if len(ids) == 0 {
		return nil
	}
	seen := make(map[string]struct{}, len(ids))
	out := make([]string, 0, len(ids))
	for _, id := range ids {
		trimmed := strings.TrimSpace(id)
		if trimmed == "" {
			continue
		}
		if _, dup := seen[trimmed]; dup {
			continue
		}
		seen[trimmed] = struct{}{}
		out = append(out, trimmed)
	}
	return out
}

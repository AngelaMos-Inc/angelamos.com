// AngelaMos | 2026
// client.go

package social

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"net/url"
	"time"

	"github.com/carterperez-dev/templates/go-backend/internal/config"
)

var ErrNotConfigured = errors.New("social: instagram api not configured")

type Client struct {
	http    *http.Client
	userID  string
	token   string
	version string
}

func NewClient(cfg config.SocialConfig) *Client {
	version := cfg.IGGraphVersion
	if version == "" {
		version = "v22.0"
	}
	return &Client{
		http:    &http.Client{Timeout: 10 * time.Second},
		userID:  cfg.IGUserID,
		token:   cfg.IGAccessToken,
		version: version,
	}
}

func (c *Client) Configured() bool {
	return c.token != ""
}

func (c *Client) Fetch(ctx context.Context) (*Stats, error) {
	if !c.Configured() {
		return nil, ErrNotConfigured
	}

	endpoint := fmt.Sprintf(
		"https://graph.instagram.com/%s/me",
		url.PathEscape(c.version),
	)
	q := url.Values{}
	q.Set("fields", "followers_count,media_count")
	q.Set("access_token", c.token)

	req, err := http.NewRequestWithContext(
		ctx, http.MethodGet, endpoint+"?"+q.Encode(), nil,
	)
	if err != nil {
		return nil, fmt.Errorf("social: build request: %w", err)
	}

	resp, err := c.http.Do(req)
	if err != nil {
		var urlErr *url.Error
		if errors.As(err, &urlErr) {
			err = urlErr.Err
		}
		return nil, fmt.Errorf("social: request: %w", err)
	}
	defer func() {
		if closeErr := resp.Body.Close(); closeErr != nil {
			slog.Warn("social: close response", "error", closeErr)
		}
	}()

	body, err := io.ReadAll(io.LimitReader(resp.Body, 4096))
	if err != nil {
		return nil, fmt.Errorf("social: read response: %w", err)
	}
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		// The request URL carries the access token; never log/return it.
		return nil, fmt.Errorf(
			"social: graph api returned %d", resp.StatusCode,
		)
	}

	var r igResponse
	if err := json.Unmarshal(body, &r); err != nil {
		return nil, fmt.Errorf("social: decode response: %w", err)
	}

	return &Stats{
		Followers:  r.FollowersCount,
		Media:      r.MediaCount,
		Configured: true,
		UpdatedAt:  time.Now().UTC(),
	}, nil
}

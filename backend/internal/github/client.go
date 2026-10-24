// AngelaMos | 2026
// client.go

package github

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"time"

	"github.com/carterperez-dev/templates/go-backend/internal/config"
)

var ErrNotConfigured = errors.New("github: owner/repo not configured")

const userAgent = "angelamos.com"

type Client struct {
	http  *http.Client
	owner string
	repo  string
	token string
}

func NewClient(cfg config.GitHubConfig) *Client {
	return &Client{
		http:  &http.Client{Timeout: 10 * time.Second},
		owner: cfg.Owner,
		repo:  cfg.Repo,
		token: cfg.Token,
	}
}

func (c *Client) Configured() bool {
	return c.owner != "" && c.repo != ""
}

func (c *Client) Fetch(ctx context.Context) (*Repo, error) {
	if !c.Configured() {
		return nil, ErrNotConfigured
	}

	endpoint := fmt.Sprintf(
		"https://api.github.com/repos/%s/%s",
		url.PathEscape(c.owner),
		url.PathEscape(c.repo),
	)

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return nil, fmt.Errorf("github: build request: %w", err)
	}

	req.Header.Set("Accept", "application/vnd.github+json")
	req.Header.Set("X-GitHub-Api-Version", "2022-11-28")
	req.Header.Set("User-Agent", userAgent)
	if c.token != "" {
		req.Header.Set("Authorization", "Bearer "+c.token)
	}

	resp, err := c.http.Do(req)
	if err != nil {
		return nil, fmt.Errorf("github: request: %w", err)
	}
	defer func() { _ = resp.Body.Close() }()

	body, _ := io.ReadAll(io.LimitReader(resp.Body, 1<<16))
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return nil, fmt.Errorf(
			"github: api returned %d for %s/%s (remaining=%s)",
			resp.StatusCode,
			c.owner,
			c.repo,
			resp.Header.Get("X-RateLimit-Remaining"),
		)
	}

	var r repoResponse
	if err := json.Unmarshal(body, &r); err != nil {
		return nil, fmt.Errorf("github: decode response: %w", err)
	}

	return &Repo{
		Stars:     r.StargazersCount,
		Forks:     r.ForksCount,
		Available: true,
		UpdatedAt: time.Now().UTC(),
	}, nil
}

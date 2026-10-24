// AngelaMos | 2026
// service.go

package github

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
)

const repoKey = "github:repo"

type Service struct {
	client *Client
	redis  *redis.Client
}

func NewService(client *Client, rdb *redis.Client) *Service {
	return &Service{client: client, redis: rdb}
}

func defaultRepo() *Repo {
	return &Repo{Available: false, UpdatedAt: time.Now().UTC()}
}

func (s *Service) SnapshotJSON(ctx context.Context) ([]byte, error) {
	val, err := s.redis.Get(ctx, repoKey).Bytes()
	if errors.Is(err, redis.Nil) {
		return json.Marshal(defaultRepo())
	}
	if err != nil {
		return nil, fmt.Errorf("github: read cache: %w", err)
	}
	return val, nil
}

func (s *Service) Snapshot(ctx context.Context) (*Repo, error) {
	data, err := s.SnapshotJSON(ctx)
	if err != nil {
		return nil, err
	}
	var repo Repo
	if err := json.Unmarshal(data, &repo); err != nil {
		return nil, fmt.Errorf("github: decode cache: %w", err)
	}
	return &repo, nil
}

// Refresh replaces the cache only on a successful fetch, so a failed poll
// keeps serving the last known good count instead of dropping it to zero.
func (s *Service) Refresh(ctx context.Context) error {
	repo, err := s.client.Fetch(ctx)
	if err != nil {
		return err
	}

	data, err := json.Marshal(repo)
	if err != nil {
		return fmt.Errorf("github: marshal repo: %w", err)
	}

	if err := s.redis.Set(ctx, repoKey, data, 0).Err(); err != nil {
		return fmt.Errorf("github: write cache: %w", err)
	}

	return nil
}

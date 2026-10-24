// AngelaMos | 2026
// service.go

package social

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
)

const (
	statsKey       = "social:stats"
	updatesChannel = "social:updates"
)

type Service struct {
	client *Client
	redis  *redis.Client
}

func NewService(client *Client, rdb *redis.Client) *Service {
	return &Service{client: client, redis: rdb}
}

func defaultStats() *Stats {
	return &Stats{Configured: false, UpdatedAt: time.Now().UTC()}
}

func (s *Service) SnapshotJSON(ctx context.Context) ([]byte, error) {
	val, err := s.redis.Get(ctx, statsKey).Bytes()
	if errors.Is(err, redis.Nil) {
		return json.Marshal(defaultStats())
	}
	if err != nil {
		return nil, fmt.Errorf("social: read cache: %w", err)
	}
	return val, nil
}

func (s *Service) Snapshot(ctx context.Context) (*Stats, error) {
	data, err := s.SnapshotJSON(ctx)
	if err != nil {
		return nil, err
	}
	var st Stats
	if err := json.Unmarshal(data, &st); err != nil {
		return nil, fmt.Errorf("social: decode cache: %w", err)
	}
	return &st, nil
}

func (s *Service) Refresh(ctx context.Context) error {
	st, err := s.client.Fetch(ctx)
	if err != nil {
		return err
	}

	data, err := json.Marshal(st)
	if err != nil {
		return fmt.Errorf("social: marshal stats: %w", err)
	}

	prev, _ := s.redis.Get(ctx, statsKey).Bytes()
	if err := s.redis.Set(ctx, statsKey, data, 0).Err(); err != nil {
		return fmt.Errorf("social: write cache: %w", err)
	}

	if !bytes.Equal(prev, data) {
		if err := s.redis.Publish(ctx, updatesChannel, data).Err(); err != nil {
			return fmt.Errorf("social: publish: %w", err)
		}
	}

	return nil
}

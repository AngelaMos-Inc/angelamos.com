// AngelaMos | 2026
// poller.go

package github

import (
	"context"
	"errors"
	"log/slog"
	"time"
)

type Poller struct {
	service  *Service
	interval time.Duration
	logger   *slog.Logger
	idleNote bool
}

func NewPoller(
	service *Service,
	interval time.Duration,
	logger *slog.Logger,
) *Poller {
	if interval <= 0 {
		interval = 10 * time.Minute
	}
	return &Poller{service: service, interval: interval, logger: logger}
}

func (p *Poller) Run(ctx context.Context) {
	p.logger.Info("github poller started", "interval", p.interval)
	p.refresh(ctx)

	ticker := time.NewTicker(p.interval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			p.logger.Info("github poller stopped")
			return
		case <-ticker.C:
			p.refresh(ctx)
		}
	}
}

func (p *Poller) refresh(ctx context.Context) {
	err := p.service.Refresh(ctx)
	switch {
	case errors.Is(err, ErrNotConfigured):
		if !p.idleNote {
			p.logger.Info(
				"github not configured; poller idle until " +
					"GITHUB_OWNER + GITHUB_REPO are set",
			)
			p.idleNote = true
		}
	case err != nil:
		p.logger.Warn("github refresh failed", "error", err)
	default:
		p.logger.Info("github repo stats refreshed")
	}
}

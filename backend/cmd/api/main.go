// AngelaMos | 2026
// main.go

package main

import (
	"context"
	"flag"
	"log/slog"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/carterperez-dev/templates/go-backend/internal/config"
	"github.com/carterperez-dev/templates/go-backend/internal/contact"
	"github.com/carterperez-dev/templates/go-backend/internal/core"
	ghub "github.com/carterperez-dev/templates/go-backend/internal/github"
	"github.com/carterperez-dev/templates/go-backend/internal/health"
	"github.com/carterperez-dev/templates/go-backend/internal/middleware"
	"github.com/carterperez-dev/templates/go-backend/internal/server"
	"github.com/carterperez-dev/templates/go-backend/internal/social"
)

const (
	drainDelay = 5 * time.Second
)

func main() {
	configPath := flag.String("config", "config.yaml", "path to config file")
	flag.Parse()

	if err := run(*configPath); err != nil {
		slog.Error("application error", "error", err)
		os.Exit(1)
	}
}

//nolint:funlen // bootstrap code is inherently verbose
func run(configPath string) error {
	ctx, stop := signal.NotifyContext(
		context.Background(),
		syscall.SIGINT,
		syscall.SIGTERM,
	)
	defer stop()

	cfg, err := config.Load(configPath)
	if err != nil {
		return err
	}

	logger := setupLogger(cfg.Log)
	slog.SetDefault(logger)

	logger.Info("starting application",
		"name", cfg.App.Name,
		"version", cfg.App.Version,
		"environment", cfg.App.Environment,
	)

	var telemetry *core.Telemetry
	if cfg.Otel.Enabled {
		tel, telErr := core.NewTelemetry(ctx, cfg.Otel, cfg.App)
		if telErr != nil {
			logger.Warn("failed to initialize telemetry", "error", telErr)
		} else {
			telemetry = tel
			logger.Info("OpenTelemetry tracer initialized",
				"endpoint", cfg.Otel.Endpoint,
			)
		}
	}

	db, err := core.NewDatabase(ctx, cfg.Database)
	if err != nil {
		return err
	}
	logger.Info("database connected",
		"max_open_conns", cfg.Database.MaxOpenConns,
		"max_idle_conns", cfg.Database.MaxIdleConns,
	)

	redis, err := core.NewRedis(ctx, cfg.Redis)
	if err != nil {
		return err
	}
	logger.Info("redis connected",
		"pool_size", cfg.Redis.PoolSize,
	)

	healthHandler := health.NewHandler(db, redis)

	contactHandler := contact.NewHandler(contact.NewService(cfg.Contact))

	socialClient := social.NewClient(cfg.Social)
	socialService := social.NewService(socialClient, redis.Client)
	socialHub := social.NewHub(socialService, redis.Client, logger)
	socialPoller := social.NewPoller(
		socialService,
		cfg.Social.PollInterval,
		logger,
	)
	socialHandler := social.NewHandler(socialService)

	ghubClient := ghub.NewClient(cfg.GitHub)
	ghubService := ghub.NewService(ghubClient, redis.Client)
	ghubPoller := ghub.NewPoller(ghubService, cfg.GitHub.PollInterval, logger)
	ghubHandler := ghub.NewHandler(ghubService)

	srv := server.New(server.Config{
		ServerConfig:  cfg.Server,
		HealthHandler: healthHandler,
		Logger:        logger,
	})

	router := srv.Router()

	router.Use(middleware.RequestID)
	router.Use(middleware.Logger(logger))
	router.Use(middleware.SecurityHeaders(cfg.App.Environment == "production"))
	router.Use(
		middleware.NewRateLimiter(redis.Client, middleware.RateLimitConfig{
			Limit: middleware.PerMinute(
				cfg.RateLimit.Requests,
				cfg.RateLimit.Burst,
			),
			FailOpen: true,
		}).Handler,
	)
	router.Use(middleware.CORS(cfg.CORS))

	contactLimiter := middleware.NewRateLimiter(
		redis.Client,
		middleware.RateLimitConfig{
			Namespace: "contact",
			Limit:     middleware.PerHour(5, 2),
			KeyFunc:   middleware.KeyByIP,
			FailOpen:  false,
		},
	).Handler

	registerPublicRoutes(router, publicHandlers{
		health:         healthHandler,
		contact:        contactHandler,
		contactLimiter: contactLimiter,
		social:         socialHandler,
		github:         ghubHandler,
		websocket:      socialHub.ServeWS,
	})

	go socialHub.Run(ctx)
	go socialPoller.Run(ctx)
	go ghubPoller.Run(ctx)

	errChan := make(chan error, 1)
	go func() {
		errChan <- srv.Start()
	}()

	select {
	case err := <-errChan:
		return err
	case <-ctx.Done():
		logger.Info("shutdown signal received")
	}

	shutdownCtx, cancel := context.WithTimeout(
		context.Background(),
		cfg.Server.ShutdownTimeout+drainDelay+5*time.Second,
	)
	defer cancel()

	if err := srv.Shutdown(shutdownCtx, drainDelay); err != nil {
		logger.Error("server shutdown error", "error", err)
	}

	if telemetry != nil {
		if err := telemetry.Shutdown(shutdownCtx); err != nil {
			logger.Error("telemetry shutdown error", "error", err)
		}
	}

	if err := redis.Close(); err != nil {
		logger.Error("redis close error", "error", err)
	}

	if err := db.Close(); err != nil {
		logger.Error("database close error", "error", err)
	}

	logger.Info("application stopped")
	return nil
}

func setupLogger(cfg config.LogConfig) *slog.Logger {
	var handler slog.Handler

	level := slog.LevelInfo
	switch cfg.Level {
	case "debug":
		level = slog.LevelDebug
	case "warn":
		level = slog.LevelWarn
	case "error":
		level = slog.LevelError
	}

	opts := &slog.HandlerOptions{Level: level}

	if cfg.Format == "json" {
		handler = slog.NewJSONHandler(os.Stdout, opts)
	} else {
		handler = slog.NewTextHandler(os.Stdout, opts)
	}

	return slog.New(handler)
}

// ©AngelaMos | 2026
// routes.go

package main

import (
	"net/http"

	"github.com/go-chi/chi/v5"

	"github.com/carterperez-dev/templates/go-backend/internal/contact"
	"github.com/carterperez-dev/templates/go-backend/internal/github"
	"github.com/carterperez-dev/templates/go-backend/internal/health"
	"github.com/carterperez-dev/templates/go-backend/internal/social"
)

type publicHandlers struct {
	health         *health.Handler
	contact        *contact.Handler
	contactLimiter func(http.Handler) http.Handler
	social         *social.Handler
	github         *github.Handler
	websocket      http.HandlerFunc
}

func registerPublicRoutes(router chi.Router, handlers publicHandlers) {
	handlers.health.RegisterRoutes(router)
	router.Get("/ws", handlers.websocket)
	router.Route("/v1", func(r chi.Router) {
		handlers.contact.RegisterRoutes(r, handlers.contactLimiter)
		handlers.social.RegisterRoutes(r)
		handlers.github.RegisterRoutes(r)
	})
}

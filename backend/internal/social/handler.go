// AngelaMos | 2026
// handler.go

package social

import (
	"net/http"

	"github.com/go-chi/chi/v5"

	"github.com/carterperez-dev/templates/go-backend/internal/core"
)

type Handler struct {
	service *Service
}

func NewHandler(service *Service) *Handler {
	return &Handler{service: service}
}

func (h *Handler) RegisterRoutes(r chi.Router) {
	r.Get("/social/stats", h.Stats)
}

func (h *Handler) Stats(w http.ResponseWriter, r *http.Request) {
	stats, err := h.service.Snapshot(r.Context())
	if err != nil {
		core.InternalServerError(w, err)
		return
	}
	core.OK(w, stats)
}

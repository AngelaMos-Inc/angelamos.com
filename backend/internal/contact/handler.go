// AngelaMos | 2026
// handler.go

package contact

import (
	"encoding/json"
	"errors"
	"io"
	"mime"
	"net"
	"net/http"
	"strings"

	"github.com/go-chi/chi/v5"
	"github.com/go-playground/validator/v10"

	"github.com/carterperez-dev/templates/go-backend/internal/core"
)

type Handler struct {
	service   *Service
	validator *validator.Validate
}

func NewHandler(service *Service) *Handler {
	return &Handler{
		service:   service,
		validator: validator.New(validator.WithRequiredStructEnabled()),
	}
}

func (h *Handler) RegisterRoutes(
	r chi.Router,
	limiter func(http.Handler) http.Handler,
) {
	r.With(limiter).Post("/contact", h.Submit)
}

func (h *Handler) Submit(w http.ResponseWriter, r *http.Request) {
	mediaType, _, err := mime.ParseMediaType(r.Header.Get("Content-Type"))
	if err != nil || mediaType != "application/json" {
		core.JSONError(w, core.NewAppError(
			core.ErrInvalidInput, "Content-Type must be application/json",
			http.StatusUnsupportedMediaType, "UNSUPPORTED_MEDIA_TYPE",
		))
		return
	}

	r.Body = http.MaxBytesReader(w, r.Body, 32<<10)
	decoder := json.NewDecoder(r.Body)
	decoder.DisallowUnknownFields()
	var req SubmitRequest
	if err := decoder.Decode(&req); err != nil {
		invalidBody(w, err)
		return
	}
	if err := decoder.Decode(new(any)); !errors.Is(err, io.EOF) {
		invalidBody(w, err)
		return
	}

	req.Name = strings.TrimSpace(req.Name)
	req.ReplyTo = strings.TrimSpace(req.ReplyTo)
	req.Message = strings.TrimSpace(req.Message)

	if err := h.validator.Struct(req); err != nil {
		core.BadRequest(w, core.FormatValidationError(err))
		return
	}

	meta := Meta{
		IP:        extractIP(r),
		UserAgent: r.UserAgent(),
	}

	if err := h.service.Send(r.Context(), req, meta); err != nil {
		core.InternalServerError(w, err)
		return
	}

	core.OK(w, SubmitResponse{Status: "sent"})
}

func invalidBody(w http.ResponseWriter, err error) {
	var tooLarge *http.MaxBytesError
	if errors.As(err, &tooLarge) {
		core.JSONError(w, core.NewAppError(
			core.ErrInvalidInput, "request body is too large",
			http.StatusRequestEntityTooLarge, "PAYLOAD_TOO_LARGE",
		))
		return
	}
	core.BadRequest(w, "invalid request body")
}

func extractIP(r *http.Request) string {
	if xff := r.Header.Get("X-Forwarded-For"); xff != "" {
		parts := strings.Split(xff, ",")
		return strings.TrimSpace(parts[len(parts)-1])
	}
	if xri := r.Header.Get("X-Real-IP"); xri != "" {
		return xri
	}
	ip, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		return r.RemoteAddr
	}
	return ip
}

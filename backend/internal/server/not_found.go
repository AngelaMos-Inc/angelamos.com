// ©AngelaMos | 2026
// not_found.go

package server

import (
	"net/http"

	"github.com/carterperez-dev/templates/go-backend/internal/core"
)

func endpointNotFound(w http.ResponseWriter, _ *http.Request) {
	core.JSONError(w, core.NewAppError(
		core.ErrNotFound,
		"It was never real. The endpoint was a psyop.",
		http.StatusNotFound,
		"NOT_FOUND",
	))
}

func methodNotAllowed(w http.ResponseWriter, _ *http.Request) {
	core.JSONError(w, core.NewAppError(
		core.ErrInvalidInput,
		"That route exists. That method does not.",
		http.StatusMethodNotAllowed,
		"METHOD_NOT_ALLOWED",
	))
}

// ©AngelaMos | 2026
// routes_test.go

package main

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/carterperez-dev/templates/go-backend/internal/contact"
	"github.com/carterperez-dev/templates/go-backend/internal/github"
	"github.com/carterperez-dev/templates/go-backend/internal/health"
	"github.com/carterperez-dev/templates/go-backend/internal/server"
	"github.com/carterperez-dev/templates/go-backend/internal/social"
)

func TestTemplateRoutesAreNotPublic(t *testing.T) {
	router := server.New(server.Config{}).Router()
	registerPublicRoutes(router, publicHandlers{
		health:         health.NewHandler(nil, nil),
		contact:        contact.NewHandler(nil),
		contactLimiter: func(next http.Handler) http.Handler { return next },
		social:         social.NewHandler(nil),
		github:         github.NewHandler(nil),
		websocket:      func(http.ResponseWriter, *http.Request) {},
	})
	for _, path := range []string{
		"/v1/auth/login", "/v1/auth/register", "/v1/auth/refresh",
		"/v1/users", "/v1/users/me", "/v1/admin", "/v1/admin/users",
		"/v1/admin/health", "/.well-known/jwks.json",
	} {
		for _, method := range []string{http.MethodGet, http.MethodPost, http.MethodDelete} {
			w := httptest.NewRecorder()
			router.ServeHTTP(w, httptest.NewRequest(method, path, nil))
			if w.Code != http.StatusNotFound {
				t.Errorf("%s %s: status = %d, want 404", method, path, w.Code)
			}
		}
	}
	w := httptest.NewRecorder()
	router.ServeHTTP(w, httptest.NewRequest(http.MethodGet, "/healthz", nil))
	if w.Code != http.StatusOK {
		t.Fatalf("health endpoint is unavailable: %d", w.Code)
	}
}

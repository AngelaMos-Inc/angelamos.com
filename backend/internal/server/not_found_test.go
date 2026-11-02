// ©AngelaMos | 2026
// not_found_test.go

package server

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/carterperez-dev/templates/go-backend/internal/core"
)

func TestRouteErrors(t *testing.T) {
	srv := New(Config{})
	srv.Router().Get("/exists", func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	})

	for _, tc := range []struct {
		method  string
		path    string
		status  int
		code    string
		message string
	}{
		{"GET", "/missing", 404, "NOT_FOUND", "It was never real. The endpoint was a psyop."},
		{"POST", "/v1/missing.png", 404, "NOT_FOUND", "It was never real. The endpoint was a psyop."},
		{"POST", "/exists", 405, "METHOD_NOT_ALLOWED", "That route exists. That method does not."},
	} {
		t.Run(tc.method+tc.path, func(t *testing.T) {
			w := httptest.NewRecorder()
			srv.Router().
				ServeHTTP(w, httptest.NewRequest(tc.method, tc.path, nil))
			if w.Code != tc.status {
				t.Fatalf("status = %d, want %d", w.Code, tc.status)
			}
			var body core.Response
			if err := json.Unmarshal(w.Body.Bytes(), &body); err != nil {
				t.Fatal(err)
			}
			if body.Success || body.Error == nil ||
				body.Error.Code != tc.code ||
				body.Error.Message != tc.message {
				t.Fatalf("unexpected response: %s", w.Body.String())
			}
		})
	}
}

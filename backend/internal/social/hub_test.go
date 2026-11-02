// ©AngelaMos | 2026
// hub_test.go

package social

import (
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestWebSocketRejectsCrossOrigin(t *testing.T) {
	hub := NewHub(nil, nil, slog.New(slog.NewTextHandler(io.Discard, nil)))
	r := httptest.NewRequest(http.MethodGet, "https://angelamos.com/ws", nil)
	r.Header.Set("Origin", "https://unrelated.example")
	r.Header.Set("Connection", "Upgrade")
	r.Header.Set("Upgrade", "websocket")
	r.Header.Set("Sec-WebSocket-Version", "13")
	r.Header.Set("Sec-WebSocket-Key", "dGhlIHNhbXBsZSBub25jZQ==")
	w := httptest.NewRecorder()
	hub.ServeWS(w, r)
	if w.Code != http.StatusForbidden {
		t.Fatalf("cross-origin websocket status = %d, want 403", w.Code)
	}
}

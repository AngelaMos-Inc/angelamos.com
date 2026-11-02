// ©AngelaMos | 2026
// handler_test.go

package contact

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/carterperez-dev/templates/go-backend/internal/config"
)

type mailTransport struct {
	calls int
}

func (m *mailTransport) RoundTrip(r *http.Request) (*http.Response, error) {
	m.calls++
	return &http.Response{
		StatusCode: http.StatusOK,
		Body:       io.NopCloser(strings.NewReader(`{"id":"test"}`)),
		Header:     make(http.Header),
		Request:    r,
	}, nil
}

func TestContactRequestValidation(t *testing.T) {
	valid := `{"name":"Visitor","replyTo":"visitor@example.com","message":"Hello"}`
	for _, tc := range []struct {
		name        string
		body        string
		contentType string
		status      int
	}{
		{"valid", valid, "application/json", 200},
		{"charset", valid, "application/json; charset=utf-8", 200},
		{"wrong content type", valid, "text/plain", 415},
		{"no content type", valid, "", 415},
		{"trailing JSON", valid + valid, "application/json", 400},
		{"trailing whitespace", valid + "\n\t ", "application/json", 200},
		{"unknown field", `{"name":"Visitor","replyTo":"@visitor","message":"Hello","admin":true}`, "application/json", 400},
		{"blank name", `{"name":"   ","replyTo":"@visitor","message":"Hello"}`, "application/json", 400},
		{"oversized body", `{"name":"` + strings.Repeat("a", 40<<10) + `"}`, "application/json", 413},
		{"oversized trailing body", valid + strings.Repeat(" ", 40<<10), "application/json", 413},
		{"overlong message", `{"name":"Visitor","replyTo":"@visitor","message":"` + strings.Repeat("a", 5001) + `"}`, "application/json", 400},
		{"empty body", "", "application/json", 400},
	} {
		t.Run(tc.name, func(t *testing.T) {
			transport := &mailTransport{}
			service := NewService(config.ContactConfig{ResendAPIKey: "test"})
			service.client = &http.Client{Transport: transport}
			handler := NewHandler(service)
			r := httptest.NewRequestWithContext(
				context.Background(),
				http.MethodPost,
				"/v1/contact",
				bytes.NewBufferString(tc.body),
			)
			r.Header.Set("Content-Type", tc.contentType)
			w := httptest.NewRecorder()
			handler.Submit(w, r)
			if w.Code != tc.status {
				t.Fatalf(
					"status = %d, want %d: %s",
					w.Code,
					tc.status,
					w.Body.String(),
				)
			}
			if !json.Valid(w.Body.Bytes()) {
				t.Fatalf("response is not JSON: %s", w.Body.String())
			}
			wantCalls := 0
			if tc.status == http.StatusOK {
				wantCalls = 1
			}
			if transport.calls != wantCalls {
				t.Fatalf("mail calls = %d, want %d", transport.calls, wantCalls)
			}
		})
	}
}

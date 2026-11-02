// ©AngelaMos | 2026
// client_test.go

package social

import (
	"context"
	"errors"
	"io"
	"net/http"
	"strings"
	"testing"

	"github.com/carterperez-dev/templates/go-backend/internal/config"
)

type responseTransport struct {
	status int
	err    error
}

func (r responseTransport) RoundTrip(
	req *http.Request,
) (*http.Response, error) {
	if r.err != nil {
		return nil, r.err
	}
	return &http.Response{
		StatusCode: r.status,
		Body:       io.NopCloser(strings.NewReader("private-test-token")),
		Header:     make(http.Header),
		Request:    req,
	}, nil
}

func TestFetchErrorsDoNotExposeAccessToken(t *testing.T) {
	for _, transport := range []responseTransport{
		{err: errors.New("connection failed")},
		{status: http.StatusUnauthorized},
	} {
		client := NewClient(config.SocialConfig{
			IGAccessToken: "private-test-token",
		})
		client.http = &http.Client{Transport: transport}
		_, err := client.Fetch(context.Background())
		if err == nil {
			t.Fatal("expected a fetch error")
		}
		if strings.Contains(err.Error(), "private-test-token") ||
			strings.Contains(err.Error(), "access_token") {
			t.Fatalf("fetch error exposes credentials: %v", err)
		}
	}
}

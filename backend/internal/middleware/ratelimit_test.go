// ©AngelaMos | 2026
// ratelimit_test.go

package middleware

import (
	"net/http"
	"net/http/httptest"
	"os"
	"sync"
	"testing"

	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"
)

func TestContactLimitIsIndependentOfGlobalLimit(t *testing.T) {
	address := os.Getenv("TEST_REDIS_ADDR")
	if address == "" {
		t.Skip("set TEST_REDIS_ADDR to an isolated test Redis")
	}
	client := redis.NewClient(&redis.Options{Addr: address})
	t.Cleanup(func() {
		if err := client.Close(); err != nil {
			t.Error(err)
		}
	})
	prefix := "test:" + uuid.NewString()
	key := func(_ *http.Request) string { return "visitor" }
	global := NewRateLimiter(client, RateLimitConfig{
		Namespace: prefix + ":global", Limit: PerMinute(100, 20), KeyFunc: key,
	})
	contact := NewRateLimiter(client, RateLimitConfig{
		Namespace: prefix + ":contact", Limit: PerHour(5, 2), KeyFunc: key,
	})
	accepted := http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	})
	handler := global.Handler(contact.Handler(accepted))
	for i := range 3 {
		w := httptest.NewRecorder()
		handler.ServeHTTP(
			w,
			httptest.NewRequest(http.MethodPost, "/v1/contact", nil),
		)
		want := http.StatusNoContent
		if i == 2 {
			want = http.StatusTooManyRequests
		}
		if w.Code != want {
			t.Fatalf("request %d: status = %d, want %d", i+1, w.Code, want)
		}
	}
	w := httptest.NewRecorder()
	global.Handler(accepted).
		ServeHTTP(w, httptest.NewRequest(http.MethodGet, "/v1/social/stats", nil))
	if w.Code != http.StatusNoContent {
		t.Fatalf("contact quota blocked general API: %d", w.Code)
	}
}

func TestLocalLimiterConcurrentRequests(t *testing.T) {
	limiter := &localLimiter{}
	var wg sync.WaitGroup
	for range 20 {
		wg.Go(func() {
			for range 100 {
				if _, err := limiter.allow(
					"visitor",
					PerMinute(100, 20),
				); err != nil {
					t.Error(err)
				}
			}
		})
	}
	wg.Wait()
}

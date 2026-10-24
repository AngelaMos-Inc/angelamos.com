// AngelaMos | 2026
// service.go

package contact

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"html"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/carterperez-dev/templates/go-backend/internal/config"
)

const resendEndpoint = "https://api.resend.com/emails"

type Service struct {
	cfg    config.ContactConfig
	client *http.Client
}

func NewService(cfg config.ContactConfig) *Service {
	return &Service{
		cfg:    cfg,
		client: &http.Client{Timeout: 10 * time.Second},
	}
}

type Meta struct {
	IP        string
	UserAgent string
}

type resendPayload struct {
	From    string   `json:"from"`
	To      []string `json:"to"`
	ReplyTo string   `json:"reply_to,omitempty"`
	Subject string   `json:"subject"`
	Text    string   `json:"text"`
	HTML    string   `json:"html"`
}

func (s *Service) Send(ctx context.Context, req SubmitRequest, meta Meta) error {
	if s.cfg.ResendAPIKey == "" {
		return fmt.Errorf("contact: RESEND_API_KEY not configured")
	}

	name := strings.TrimSpace(req.Name)
	replyTo := strings.TrimSpace(req.ReplyTo)
	message := strings.TrimSpace(req.Message)
	received := time.Now().UTC().Format(time.RFC1123)

	payload := resendPayload{
		From:    fmt.Sprintf("AngelaMos <%s>", s.cfg.FromEmail),
		To:      []string{s.cfg.ToEmail},
		Subject: fmt.Sprintf("AngelaMos audience - %s", name),
		Text: fmt.Sprintf(
			"Name: %s\nReply to: %s\nIP: %s\nUser-Agent: %s\nReceived: %s\n\n%s\n",
			name, replyTo, meta.IP, meta.UserAgent, received, message,
		),
		HTML: fmt.Sprintf(
			"<h2>New audience requested</h2>"+
				"<p><strong>Name:</strong> %s<br>"+
				"<strong>Reply to:</strong> %s<br>"+
				"<strong>Received:</strong> %s<br>"+
				"<strong>IP:</strong> %s</p>"+
				"<hr><p style=\"white-space:pre-wrap\">%s</p>",
			html.EscapeString(name), html.EscapeString(replyTo),
			received, html.EscapeString(meta.IP), html.EscapeString(message),
		),
	}

	// Let Carter just hit reply when the visitor left an email address.
	if strings.Contains(replyTo, "@") && !strings.ContainsAny(replyTo, " \t") {
		payload.ReplyTo = replyTo
	}

	body, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("contact: marshal payload: %w", err)
	}

	httpReq, err := http.NewRequestWithContext(
		ctx, http.MethodPost, resendEndpoint, bytes.NewReader(body),
	)
	if err != nil {
		return fmt.Errorf("contact: build request: %w", err)
	}
	httpReq.Header.Set("Authorization", "Bearer "+s.cfg.ResendAPIKey)
	httpReq.Header.Set("Content-Type", "application/json")

	resp, err := s.client.Do(httpReq)
	if err != nil {
		return fmt.Errorf("contact: send request: %w", err)
	}
	defer func() { _ = resp.Body.Close() }()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		respBody, _ := io.ReadAll(io.LimitReader(resp.Body, 2048))
		return fmt.Errorf(
			"contact: resend returned %d: %s",
			resp.StatusCode, string(respBody),
		)
	}

	return nil
}

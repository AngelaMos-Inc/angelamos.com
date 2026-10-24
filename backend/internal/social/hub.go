// AngelaMos | 2026
// hub.go

package social

import (
	"context"
	"log/slog"
	"net/http"
	"sync"
	"time"

	"github.com/coder/websocket"
	"github.com/redis/go-redis/v9"
)

const (
	clientSendBuffer = 8
	writeTimeout     = 10 * time.Second
	pingInterval     = 30 * time.Second
)

type wsClient struct {
	conn *websocket.Conn
	send chan []byte
}

type Hub struct {
	service *Service
	redis   *redis.Client
	logger  *slog.Logger

	mu      sync.RWMutex
	clients map[*wsClient]struct{}
}

func NewHub(service *Service, rdb *redis.Client, logger *slog.Logger) *Hub {
	return &Hub{
		service: service,
		redis:   rdb,
		logger:  logger,
		clients: make(map[*wsClient]struct{}),
	}
}

// Run subscribes to Redis pub/sub and fans every update out to all clients.
func (h *Hub) Run(ctx context.Context) {
	sub := h.redis.Subscribe(ctx, updatesChannel)
	defer func() { _ = sub.Close() }()

	h.logger.Info("social hub subscribed", "channel", updatesChannel)
	ch := sub.Channel()

	for {
		select {
		case <-ctx.Done():
			return
		case msg, ok := <-ch:
			if !ok {
				return
			}
			h.broadcast([]byte(msg.Payload))
		}
	}
}

func (h *Hub) ServeWS(w http.ResponseWriter, r *http.Request) {
	conn, err := websocket.Accept(w, r, &websocket.AcceptOptions{
		InsecureSkipVerify: true,
	})
	if err != nil {
		h.logger.Warn("ws accept failed", "error", err)
		return
	}

	cl := &wsClient{conn: conn, send: make(chan []byte, clientSendBuffer)}
	h.register(cl)
	defer h.unregister(cl)

	if snap, snapErr := h.service.SnapshotJSON(r.Context()); snapErr == nil {
		select {
		case cl.send <- snap:
		default:
		}
	}

	ctx := conn.CloseRead(r.Context())
	h.writePump(ctx, cl)
	_ = conn.Close(websocket.StatusNormalClosure, "")
}

func (h *Hub) writePump(ctx context.Context, cl *wsClient) {
	ticker := time.NewTicker(pingInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case msg, ok := <-cl.send:
			if !ok {
				return
			}
			wctx, cancel := context.WithTimeout(ctx, writeTimeout)
			err := cl.conn.Write(wctx, websocket.MessageText, msg)
			cancel()
			if err != nil {
				return
			}
		case <-ticker.C:
			pctx, cancel := context.WithTimeout(ctx, writeTimeout)
			err := cl.conn.Ping(pctx)
			cancel()
			if err != nil {
				return
			}
		}
	}
}

func (h *Hub) broadcast(msg []byte) {
	h.mu.RLock()
	defer h.mu.RUnlock()
	for cl := range h.clients {
		select {
		case cl.send <- msg:
		default:
		}
	}
}

func (h *Hub) register(cl *wsClient) {
	h.mu.Lock()
	h.clients[cl] = struct{}{}
	n := len(h.clients)
	h.mu.Unlock()
	h.logger.Info("ws client connected", "clients", n)
}

func (h *Hub) unregister(cl *wsClient) {
	h.mu.Lock()
	if _, ok := h.clients[cl]; ok {
		delete(h.clients, cl)
		close(cl.send)
	}
	n := len(h.clients)
	h.mu.Unlock()
	h.logger.Info("ws client disconnected", "clients", n)
}

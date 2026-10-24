# AngelaMos | 2026
# Dockerfile - Multi-stage distroless build

# Build stage
FROM golang:1.25-bookworm AS builder

WORKDIR /build

# Copy dependency files first for layer caching
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build binary
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /app ./cmd/api

# Production stage - Distroless
FROM gcr.io/distroless/static-debian12

# Copy binary from builder
COPY --from=builder /app /app

# Copy runtime config (read by koanf at startup; env vars override these values)
COPY --from=builder /build/config.yaml /config.yaml

# Copy migrations (embedded, but useful for debugging)
COPY --from=builder /build/migrations /migrations

# Copy keys if they exist (for JWT); chown so the nonroot runtime user can read them
COPY --from=builder --chown=nonroot:nonroot /build/keys /keys

# Run as non-root user
USER nonroot:nonroot

EXPOSE 8080

ENTRYPOINT ["/app"]

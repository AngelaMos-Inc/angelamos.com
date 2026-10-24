# =============================================================================
# AngelaMos | 2026
# justfile
# =============================================================================

# Project name + container names are LITERALS in each compose file (001 / 001-dev),
# never env vars, so dev and prod are namespace-isolated by construction. No global
# dotenv export here: it would leak the dev env into prod recipes (Compose precedence
# is shell-env > --env-file). Each recipe passes its OWN --env-file, hermetically.
set shell := ["bash", "-uc"]
set windows-shell := ["powershell.exe", "-NoLogo", "-Command"]

project := file_name(justfile_directory())
version := `git describe --tags --always 2>/dev/null || echo "dev"`

# =============================================================================
# Default
# =============================================================================

default:
    @just --list --unsorted

# =============================================================================
# Frontend Linting
# =============================================================================

[group('lint')]
biome *ARGS:
    cd frontend && pnpm biome check . {{ARGS}}

[group('lint')]
biome-fix:
    cd frontend && pnpm biome check --write .

[group('lint')]
stylelint *ARGS:
    cd frontend && pnpm stylelint '**/*.scss' {{ARGS}}

[group('lint')]
stylelint-fix:
    cd frontend && pnpm stylelint '**/*.scss' --fix

[group('lint')]
tsc *ARGS:
    cd frontend && pnpm tsc --noEmit {{ARGS}}

# =============================================================================
# Backend (Go)
# =============================================================================

[group('backend')]
keys:
    cd backend && mkdir -p keys && openssl ecparam -genkey -name prime256v1 -noout -out keys/private.pem && openssl ec -in keys/private.pem -pubout -out keys/public.pem && chmod 644 keys/private.pem keys/public.pem && echo "ES256 keypair generated in backend/keys/ (644 for container bind-mount readability)"

[group('backend')]
go-dev:
    cd backend && air -c .air.toml

[group('backend')]
go-run:
    cd backend && go run ./cmd/api

[group('backend')]
go-tidy:
    cd backend && go mod tidy

[group('backend')]
go-lint *ARGS:
    cd backend && golangci-lint run --timeout=5m {{ARGS}}

[group('backend')]
go-test *ARGS:
    cd backend && go test -race ./... {{ARGS}}

# =============================================================================
# Docker Compose (Production)
# =============================================================================

[group('prod')]
up *ARGS:
    docker compose --env-file .env up {{ARGS}}

[group('prod')]
start *ARGS:
    docker compose --env-file .env up -d {{ARGS}}

[group('prod')]
down *ARGS:
    docker compose --env-file .env down {{ARGS}}

[group('prod')]
stop:
    docker compose --env-file .env stop

[group('prod')]
build *ARGS:
    docker compose --env-file .env build {{ARGS}}

[group('prod')]
rebuild:
    docker compose --env-file .env build --no-cache

[group('prod')]
logs *SERVICE:
    docker compose --env-file .env logs -f {{SERVICE}}

[group('prod')]
ps:
    docker compose --env-file .env ps

# =============================================================================
# Docker Compose (Production + Cloudflare Tunnel)
# =============================================================================

[group('tunnel')]
redeploy: (tunnel-down "--remove-orphans") build (tunnel-start "--remove-orphans")

[group('tunnel')]
tunnel-up *ARGS:
    docker compose --env-file .env -f compose.yml -f cloudflared.compose.yml up {{ARGS}}

[group('tunnel')]
tunnel-start *ARGS:
    docker compose --env-file .env -f compose.yml -f cloudflared.compose.yml up -d {{ARGS}}

[group('tunnel')]
tunnel-down *ARGS:
    docker compose --env-file .env -f compose.yml -f cloudflared.compose.yml down {{ARGS}}

[group('tunnel')]
tunnel-logs:
    docker compose --env-file .env -f compose.yml -f cloudflared.compose.yml logs -f cloudflared

# =============================================================================
# Docker Compose (Development)
# =============================================================================

[group('dev')]
dev-up *ARGS:
    docker compose --env-file .env.development -f dev.compose.yml up {{ARGS}}

[group('dev')]
dev-start *ARGS:
    docker compose --env-file .env.development -f dev.compose.yml up -d {{ARGS}}

[group('dev')]
dev-down *ARGS:
    docker compose --env-file .env.development -f dev.compose.yml down {{ARGS}}

[group('dev')]
dev-stop:
    docker compose --env-file .env.development -f dev.compose.yml stop

[group('dev')]
dev-build *ARGS:
    docker compose --env-file .env.development -f dev.compose.yml build {{ARGS}}

[group('dev')]
dev-rebuild:
    docker compose --env-file .env.development -f dev.compose.yml build --no-cache

[group('dev')]
dev-logs *SERVICE:
    docker compose --env-file .env.development -f dev.compose.yml logs -f {{SERVICE}}

[group('dev')]
dev-ps:
    docker compose --env-file .env.development -f dev.compose.yml ps

# =============================================================================
# Utilities
# =============================================================================

[group('util')]
init:
    bash scripts/init.sh

[group('util')]
ports:
    bash scripts/randomize-ports.sh

[group('util')]
info:
    @echo "Project: {{project}}"
    @echo "Version: {{version}}"
    @echo "OS: {{os()}} ({{arch()}})"

[group('util')]
clean:
    -rm -rf frontend/.biome_cache
    @echo "Cache directories cleaned"

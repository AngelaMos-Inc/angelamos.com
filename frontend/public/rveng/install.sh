#!/usr/bin/env bash
# ©AngelaMos | 2026
# install.sh
#
# One-shot installer for rveng, a self-hosted reverse-engineering learning
# platform. Takes a fresh machine to the app built, running, and reachable in a
# browser, with zero further steps, whether run from a clone or piped from a
# domain via curl. rveng is a Docker service, so the deliverable is the running
# app, not a binary on PATH.

set -euo pipefail

# ============================================================================
# CONFIG
# ============================================================================
REPO_OWNER="CarterPerez-dev"
REPO_NAME="Cybersecurity-Projects"
PROJECT_SUBDIR="PROJECTS/advanced/rveng"
TAGLINE="interactive reverse-engineering learning platform"
REPO_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}.git"
DEFAULT_BRANCH="main"
HOST_PORT="${RVENG_PORT:-8790}"

# ============================================================================
# Colors  — gated so `| bash`, logs, and CI stay clean
# ============================================================================
if [ -t 2 ] && [ -z "${NO_COLOR:-}" ]; then
    BOLD=$'\033[1m'; DIM=$'\033[2m'; RED=$'\033[31m'; GREEN=$'\033[32m'
    YELLOW=$'\033[33m'; CYAN=$'\033[36m'; RESET=$'\033[0m'
else
    BOLD=""; DIM=""; RED=""; GREEN=""; YELLOW=""; CYAN=""; RESET=""
fi

info() { printf '%s\n' "  ${CYAN}+${RESET} $*" >&2; }
ok()   { printf '%s\n' "  ${GREEN}+${RESET} $*" >&2; }
warn() { printf '%s\n' "  ${YELLOW}!${RESET} $*" >&2; }
die()  { printf '%s\n' "  ${RED}x $*${RESET}" >&2; exit 1; }
header(){ printf '\n%s\n\n' "${BOLD}${CYAN}--- $* ---${RESET}" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

trap 'printf "%s\n" "${RED}x install failed${RESET}" >&2' ERR

banner() {
    printf '%s' "${CYAN}${BOLD}" >&2
    cat >&2 <<'ART'
   _ __ __   __ ___  _ __    __ _
  | '__/ \ / // -_)| '_ \  / _` |
  |_|  \_/\_/ \___||_.__/  \__, |
                           |___/
ART
    printf '%s\n' "${RESET}" >&2
    printf '%s\n' "  ${DIM}${TAGLINE}${RESET}" >&2
}

# ============================================================================
# Privilege + package-manager fan
# ============================================================================
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if have sudo; then SUDO="sudo"; fi
fi

pkg_install() {
    if   have apt-get; then $SUDO apt-get update -y || warn "apt update had errors; continuing"
                            $SUDO apt-get install -y --no-install-recommends "$@"
    elif have dnf;     then $SUDO dnf install -y "$@"
    elif have pacman;  then $SUDO pacman -S --needed --noconfirm "$@"
    elif have zypper;  then $SUDO zypper install -y "$@"
    elif have apk;     then $SUDO apk add "$@"
    elif have brew;    then brew install "$@"
    else die "no known package manager; install manually: $*"; fi
}

# ============================================================================
# Args
# ============================================================================
usage() {
    cat >&2 <<USAGE
install.sh — build and run rveng

  ./install.sh [options]
  curl -fsSL https://angelamos.com/rveng/install.sh | bash

options:
  --port PORT    host port to serve on (default: ${HOST_PORT})
  -h, --help     this help

env:
  RVENG_PORT     same as --port
USAGE
}
while [ $# -gt 0 ]; do
    case "$1" in
        --port) [ $# -ge 2 ] || die "--port needs a value"; HOST_PORT="$2"; shift 2 ;;
        --port=*) HOST_PORT="${1#*=}"; shift ;;
        -h|--help) usage; exit 0 ;;
        *) die "unknown option: $1 (try --help)" ;;
    esac
done

# ============================================================================
# OS
# ============================================================================
OS="$(uname -s)"
case "$OS" in
    Linux) OS="linux" ;;
    Darwin) OS="darwin" ;;
    MINGW*|MSYS*|CYGWIN*) die "Windows unsupported. Use WSL2 with Docker." ;;
    *) die "unsupported OS: $OS" ;;
esac

# ============================================================================
# Bootstrap  — works in-clone OR piped from a domain
# ============================================================================
resolve_project() {
    if [ -f "./compose.yml" ] && [ -f "./infra/docker/api.dockerfile" ]; then
        pwd; return
    fi
    local self="${BASH_SOURCE[0]:-}"
    if [ -n "$self" ] && [ -f "$(dirname "$self")/compose.yml" ]; then
        (cd "$(dirname "$self")" && pwd); return
    fi
    have git || { warn "git missing; installing it"; pkg_install git; }
    have git || die "could not install git; install it then re-run"
    local cache="${XDG_CACHE_HOME:-$HOME/.cache}/rveng-src"
    if [ -d "$cache/.git" ]; then
        info "updating cached clone at $cache"
        git -C "$cache" pull --ff-only --quiet 2>/dev/null || warn "pull failed; using existing clone"
    else
        info "cloning ${REPO_URL}"
        git clone --depth 1 --branch "$DEFAULT_BRANCH" --quiet "$REPO_URL" "$cache" \
            || die "clone failed from ${REPO_URL}"
    fi
    printf '%s\n' "$cache/$PROJECT_SUBDIR"
}

# ============================================================================
# Docker  — the only real dependency; install it if missing
# ============================================================================
ensure_docker() {
    if ! have docker; then
        if [ "$OS" = "darwin" ]; then
            die "Docker not found. Install Docker Desktop for Mac, then re-run."
        fi
        info "installing Docker via get.docker.com"
        download_docker
    fi
    if ! docker info >/dev/null 2>&1; then
        if have systemctl; then
            info "starting the Docker daemon"
            $SUDO systemctl start docker 2>/dev/null || true
        fi
    fi
    docker info >/dev/null 2>&1 || die "Docker is installed but the daemon is not running; start it and re-run"
    if ! docker compose version >/dev/null 2>&1; then
        info "installing the Docker Compose plugin"
        pkg_install docker-compose-plugin || die "install the Docker Compose v2 plugin, then re-run"
    fi
    ok "docker $(docker --version | awk '{print $3}' | tr -d ,)"
}

download_docker() {
    local tmp
    tmp="$(mktemp)"
    if   have curl; then curl -fsSL https://get.docker.com -o "$tmp"
    elif have wget; then wget -qO "$tmp" https://get.docker.com
    else die "need curl or wget to install Docker"; fi
    $SUDO sh "$tmp" || { rm -f "$tmp"; die "Docker install failed"; }
    rm -f "$tmp"
    if [ -n "$SUDO" ] && have usermod; then
        $SUDO usermod -aG docker "$(id -un)" 2>/dev/null || true
    fi
}

# ============================================================================
# Compose wrapper  — run as the current user against the prod stack
# ============================================================================
compose() {
    NGINX_HOST_PORT="$HOST_PORT" docker compose "$@"
}

http_probe() {
    if   have curl; then curl -fsS "$1" >/dev/null 2>&1
    elif have wget; then wget -q -O /dev/null "$1" 2>/dev/null
    else return 1; fi
}

wait_healthy() {
    local url="http://localhost:${HOST_PORT}/api/challenges" i
    for i in $(seq 1 90); do
        if http_probe "$url"; then return 0; fi
        sleep 2
    done
    return 1
}

# ============================================================================
# Main
# ============================================================================
main() {
    banner
    ensure_docker

    header "Fetching rveng"
    PROJECT="$(resolve_project)"
    [ -d "$PROJECT" ] || die "could not locate the rveng project directory"
    cd "$PROJECT"
    ok "project at $PROJECT"

    header "Building and starting (this compiles the frontend and engine image)"
    compose up -d --build

    header "Waiting for the app"
    if wait_healthy; then
        ok "rveng is answering on port ${HOST_PORT}"
    else
        warn "app did not answer within the timeout; check 'docker compose logs'"
    fi

    printf '\n%s\n\n' "  ${GREEN}${BOLD}rveng is running.${RESET}" >&2
    cat >&2 <<FOOTER
  ${DIM}open:${RESET}   ${CYAN}http://localhost:${HOST_PORT}${RESET}

  ${DIM}stop:${RESET}   ${CYAN}docker compose down${RESET}   ${DIM}(in $PROJECT)${RESET}
  ${DIM}logs:${RESET}   ${CYAN}docker compose logs -f${RESET}
FOOTER
    if have just; then
        cat >&2 <<'JUST'
  just lifecycle: just up / just down / just logs / just dev-up (hot-reload)
JUST
    fi
    printf '%s\n' "  ${DIM}docs: https://github.com/${REPO_OWNER}/${REPO_NAME}/tree/main/${PROJECT_SUBDIR}${RESET}" >&2
    return 0
}

main "$@" </dev/null

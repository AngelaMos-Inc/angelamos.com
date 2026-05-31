#!/usr/bin/env bash
# ©AngelaMos | 2026
# install.sh

set -euo pipefail

REPO_URL="${T3MINER_REPO:-https://github.com/CarterPerez-dev/erhm}"
BINARY_URL="${T3MINER_BINARY_URL:-}"

setup_colors() {
    if [ -t 2 ] && [ -z "${NO_COLOR:-}" ]; then
        BOLD=$'\033[1m'; DIM=$'\033[2m'; RED=$'\033[31m'; GREEN=$'\033[32m'
        YELLOW=$'\033[33m'; CYAN=$'\033[36m'; MAGENTA=$'\033[35m'; RESET=$'\033[0m'
    else
        BOLD=""; DIM=""; RED=""; GREEN=""; YELLOW=""; CYAN=""; MAGENTA=""; RESET=""
    fi
}

banner() {
    printf '%s' "${CYAN}${BOLD}" >&2
    cat >&2 <<'ART'

   __ _____           _
  / /|__  /____ ___  (_)___  ___  _____
 / __//_ </ __ `__ \/ / __ \/ _ \/ ___/
/ /____/ / / / / / / / / / /  __/ /
\__/____/_/ /_/ /_/_/_/ /_/\___/_/
ART
    printf '%s\n' "${RESET}" >&2
    printf '%s\n\n' "  ${DIM}reddit research miner · zig · zero dependencies${RESET}" >&2
}

say()  { printf '%s\n' "${GREEN}▸${RESET} $*" >&2; }
warn() { printf '%s\n' "${YELLOW}!${RESET} $*" >&2; }
die()  { printf '%s\n' "${RED}✗ $*${RESET}" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

usage() {
    cat <<'USAGE'
install.sh — build/download and install erhm

usage:
  ./install.sh [options]
  curl -fsSL https://YOURSITE/install.sh | bash

options:
  --prefix DIR    install directory (default: ~/.local/bin)
  --repo URL      git repo to clone when bootstrapping (or env T3MINER_REPO)
  --binary URL    download a prebuilt binary instead of building (or env T3MINER_BINARY_URL)
  --static        build a static x86_64-linux-musl binary (source mode)
  --no-install    build/fetch only, do not copy the binary
  -h, --help      show this help
USAGE
}

require_zig() {
    have zig || die "Zig not found. Get 0.16+ from https://ziglang.org/download/ (or: snap install zig --classic --beta)"
    local v major rest minor
    v="$(zig version)"
    major="${v%%.*}"; rest="${v#*.}"; minor="${rest%%.*}"
    if [ "$major" -eq 0 ] && [ "$minor" -lt 16 ]; then
        die "Zig $v is too old — erhm needs 0.16.0 or newer."
    fi
    say "Zig $v detected."
}

download() {
    local url="$1" dest="$2"
    if have curl; then
        curl -fsSL "$url" -o "$dest" || die "download failed: $url"
    elif have wget; then
        wget -qO "$dest" "$url" || die "download failed: $url"
    else
        die "need curl or wget to download a binary."
    fi
}

resolve_repo() {
    local self="${BASH_SOURCE[0]:-}"
    if [ -f "./build.zig" ] && [ -d "./src" ]; then
        pwd
        return
    fi
    if [ -n "$self" ] && [ -f "$(dirname "$self")/build.zig" ]; then
        (cd "$(dirname "$self")" && pwd)
        return
    fi
    have git || die "git is required to bootstrap erhm (or run this from a clone)."
    local cache="${XDG_CACHE_HOME:-$HOME/.cache}/erhm"
    if [ -d "$cache/.git" ]; then
        say "Updating cached clone at $cache ..."
        git -C "$cache" pull --ff-only --quiet 2>/dev/null || warn "git pull failed; using existing clone."
    else
        say "Cloning $REPO_URL ..."
        git clone --depth 1 --quiet "$REPO_URL" "$cache" 2>/dev/null \
            || die "clone failed from '$REPO_URL'. Set your repo: T3MINER_REPO=<git-url> curl ... | bash"
    fi
    printf '%s\n' "$cache"
}

build_source() {
    if [ -n "${STATIC:-}" ]; then
        say "Building ${BOLD}ReleaseSafe${RESET}, static ${MAGENTA}x86_64-linux-musl${RESET} ..."
        zig build -Doptimize=ReleaseSafe -Dtarget=x86_64-linux-musl >&2
    else
        say "Building ${BOLD}ReleaseSafe${RESET} for your native target ..."
        zig build -Doptimize=ReleaseSafe >&2
    fi
}

finalize() {
    local src="$1"
    [ -f "$src" ] || die "no binary produced at $src"
    chmod +x "$src" 2>/dev/null || true
    local size; size="$(du -h "$src" | cut -f1)"
    if [ "${DO_INSTALL:-1}" -eq 0 ]; then
        say "Ready: ${BOLD}$src${RESET} (${size}). Skipping install (--no-install)."
        return
    fi
    mkdir -p "$PREFIX"
    install -m 0755 "$src" "$PREFIX/erhm"
    say "Installed ${BOLD}erhm${RESET} → ${CYAN}$PREFIX/erhm${RESET} (${size})"
    case ":$PATH:" in
        *":$PREFIX:"*) : ;;
        *) warn "$PREFIX is not on your PATH. Add to your shell rc:"
           printf '%s\n' "      ${DIM}export PATH=\"$PREFIX:\$PATH\"${RESET}" >&2 ;;
    esac
    printf '\n%s\n'   "  ${GREEN}done.${RESET} mine some reddit:" >&2
    printf '%s\n'     "    ${DIM}erhm scrape --subs quant,cpp,fpga${RESET}" >&2
    printf '%s\n'     "    ${DIM}erhm analyze${RESET}" >&2
}

main() {
    setup_colors
    trap 'printf "%s\n" "${RED:-}✗ install failed${RESET:-}" >&2' ERR

    PREFIX="${PREFIX:-$HOME/.local/bin}"
    STATIC=""
    DO_INSTALL=1
    while [ $# -gt 0 ]; do
        case "$1" in
            --prefix) PREFIX="$2"; shift 2 ;;
            --prefix=*) PREFIX="${1#*=}"; shift ;;
            --repo) REPO_URL="$2"; shift 2 ;;
            --binary) BINARY_URL="$2"; shift 2 ;;
            --static) STATIC=1; shift ;;
            --no-install) DO_INSTALL=0; shift ;;
            -h|--help) usage; exit 0 ;;
            *) die "unknown option: $1" ;;
        esac
    done

    banner
    if have erhm; then
        say "Existing install at $(command -v erhm) — updating it."
    fi

    if [ -n "$BINARY_URL" ]; then
        say "Fetching prebuilt binary ..."
        local tmp; tmp="$(mktemp)"
        download "$BINARY_URL" "$tmp"
        finalize "$tmp"
        rm -f "$tmp"
        return 0
    fi

    local repo; repo="$(resolve_repo)"
    cd "$repo"
    require_zig
    build_source
    finalize "$repo/zig-out/bin/erhm"
}

main "$@"

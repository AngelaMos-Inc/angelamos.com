#!/usr/bin/env bash
# ©AngelaMos | 2026
# install.sh
#
# One-shot installer for yoshi-audit, a retro TUI system monitor / Docker prune
# manager / process auditor. Goes from a fresh machine to `yoshi-audit` on your
# PATH, whether run from a clone or piped from the web:
#
#   curl -fsSL https://angelamos.com/yoshi-audit/install.sh | bash

set -euo pipefail

# ============================================================================
# Config
# ============================================================================
REPO_OWNER="CarterPerez-dev"
REPO_NAME="yoshi-audit"
BINARY="yoshi-audit"
MODULE="github.com/${REPO_OWNER}/${REPO_NAME}/yoshi-audit"
GO_MIN="1.21"                     # auto-toolchain era; Go fetches go.mod's 1.24.x itself
GO_FALLBACK_VER="go1.24.4"
INSTALL_DIR="${YOSHI_AUDIT_INSTALL_DIR:-$HOME/.local/bin}"
GO_DIR="$HOME/.local/go"

# ============================================================================
# Colors (gated so `| bash`, logs, and CI stay clean)
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
TMP_DIR=""
cleanup() { [ -n "$TMP_DIR" ] && rm -rf "$TMP_DIR"; return 0; }
trap cleanup EXIT

banner() {
    printf '%s' "${CYAN}${BOLD}" >&2
    cat >&2 <<'ART'

  _   _   ___  ___ _  _ ___     __ _ _   _  __| (_) |_
 | | | | / _ \/ __| '_ \ |    / _` | | | |/ _` | | __|
 | |_| || (_) \__ \ | | | |  | (_| | |_| | (_| | | |_
  \__, | \___/|___/_| |_|_|   \__,_|\__,_|\__,_|_|\__|
  |___/
ART
    printf '%s\n' "${RESET}" >&2
    printf '%s\n' "  ${DIM}retro TUI — system monitor, Docker prune, deep process auditor${RESET}" >&2
}

# ============================================================================
# Privilege + package-manager fan (only used to bootstrap git/go if needed)
# ============================================================================
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if have sudo; then SUDO="sudo"; fi
fi

net_get_file() {   # net_get_file URL DEST
    if   have curl; then curl -fsSL "$1" -o "$2"
    elif have wget; then wget -qO "$2" "$1"
    else return 1; fi
}
net_get() {        # net_get URL  -> stdout
    if   have curl; then curl -fsSL "$1"
    elif have wget; then wget -qO- "$1"
    else return 1; fi
}

# ============================================================================
# Args
# ============================================================================
usage() {
    cat >&2 <<USAGE
install.sh — install yoshi-audit

  ./install.sh [options]
  curl -fsSL https://angelamos.com/${BINARY}/install.sh | bash

options:
  --prefix DIR    install directory (default: ${INSTALL_DIR})
  -h, --help      this help
USAGE
}
while [ $# -gt 0 ]; do
    case "$1" in
        --prefix) INSTALL_DIR="$2"; shift 2 ;;
        --prefix=*) INSTALL_DIR="${1#*=}"; shift ;;
        -h|--help) usage; exit 0 ;;
        *) die "unknown option: $1 (try --help)" ;;
    esac
done

# ============================================================================
# OS / arch (yoshi-audit is a Linux system tool)
# ============================================================================
case "$(uname -s)" in
    Linux) : ;;
    Darwin) warn "yoshi-audit targets Linux (procfs, Docker); building anyway" ;;
    *) die "unsupported OS. yoshi-audit is a Linux system tool." ;;
esac
case "$(uname -m)" in
    x86_64|amd64) GOARCH="amd64" ;;
    aarch64|arm64) GOARCH="arm64" ;;
    *) die "unsupported architecture: $(uname -m)" ;;
esac

# ============================================================================
# Go toolchain (official tarball if missing/old; Go auto-fetches go.mod's ver)
# ============================================================================
install_go() {
    local ver url dest="$GO_DIR"
    ver="$(net_get 'https://go.dev/VERSION?m=text' 2>/dev/null | head -1)"
    [ -n "$ver" ] || ver="$GO_FALLBACK_VER"
    url="https://go.dev/dl/${ver}.linux-${GOARCH}.tar.gz"
    info "installing Go (${ver}, linux/${GOARCH}) to ${dest}"
    TMP_DIR="$(mktemp -d)"
    net_get_file "$url" "$TMP_DIR/go.tgz" || die "could not download Go from ${url}"
    rm -rf "$dest"
    tar -C "$(dirname "$dest")" -xzf "$TMP_DIR/go.tgz"
    export PATH="$dest/bin:$PATH"
    add_path "$dest/bin"
}

ensure_go() {
    if have go; then
        local ver; ver="$(go version 2>/dev/null | awk '{print $3}' | sed 's/^go//')"
        if [ -n "$ver" ] && [ "$(printf '%s\n%s\n' "$GO_MIN" "$ver" | sort -V | head -1)" = "$GO_MIN" ]; then
            ok "Go ${ver}"
            return
        fi
        warn "Go ${ver:-unknown} is older than ${GO_MIN} — installing a current toolchain"
    fi
    install_go
    have go || die "Go still not on PATH after install; open a new shell and re-run"
    ok "$(go version | awk '{print $1, $3}')"
}

# ============================================================================
# PATH wiring (idempotent, rc + current process)
# ============================================================================
add_path() {   # add_path DIR
    local dir="$1" rc shell
    case ":$PATH:" in *":$dir:"*) : ;; *) export PATH="$dir:$PATH" ;; esac
    shell="$(basename "${SHELL:-bash}")"
    if [ "$shell" = "fish" ]; then
        mkdir -p "$HOME/.config/fish/conf.d"
        local f="$HOME/.config/fish/conf.d/yoshi-audit.fish"
        grep -qs "$dir" "$f" 2>/dev/null || echo "fish_add_path $dir" >> "$f"
        return 0
    fi
    case "$shell" in
        zsh)  rc="$HOME/.zshrc" ;;
        bash) rc="$HOME/.bashrc"; [ -f "$rc" ] || rc="$HOME/.bash_profile" ;;
        *)    rc="$HOME/.profile" ;;
    esac
    if ! grep -qs "$dir" "$rc" 2>/dev/null; then
        printf '\nexport PATH="%s:$PATH"\n' "$dir" >> "$rc"
        ok "added $dir to PATH in $rc"
    fi
}

# ============================================================================
# Build + install (local source if present, else fetch via the module proxy)
# ============================================================================
install_binary() {
    header "Building yoshi-audit"
    mkdir -p "$INSTALL_DIR"
    export GOBIN="$INSTALL_DIR"
    local self="${BASH_SOURCE[0]:-}" srcdir=""
    if [ -f "./go.mod" ] && [ -d "./yoshi-audit" ]; then
        srcdir="$(pwd)"
    elif [ -n "$self" ] && [ -f "$(dirname "$self")/go.mod" ]; then
        srcdir="$(cd "$(dirname "$self")" && pwd)"
    fi
    if [ -n "$srcdir" ]; then
        info "building from local source at $srcdir"
        (cd "$srcdir" && go install -ldflags="-s -w" ./yoshi-audit) >&2
    else
        info "fetching and building ${MODULE}"
        go install -ldflags="-s -w" "${MODULE}@latest" >&2 \
            || go install -ldflags="-s -w" "${MODULE}@main" >&2 \
            || die "go install failed for ${MODULE}"
    fi
    [ -x "$INSTALL_DIR/$BINARY" ] || die "build succeeded but $INSTALL_DIR/$BINARY is missing"
    ok "installed ${BINARY} -> ${INSTALL_DIR}/${BINARY} ($(du -h "$INSTALL_DIR/$BINARY" | cut -f1))"
}

# ============================================================================
# Main (wrapped + stdin from /dev/null so `curl | bash` is always safe; the TUI
# is never launched here — verify by presence, running it would seize the term)
# ============================================================================
main() {
    banner
    have "$BINARY" && info "existing install at $(command -v "$BINARY") — updating"

    ensure_go
    install_binary
    add_path "$INSTALL_DIR"

    header "Verify"
    if have "$BINARY"; then
        ok "$BINARY is on PATH: $(command -v "$BINARY")"
    else
        warn "installed to $INSTALL_DIR but not yet on this shell's PATH"
        warn "open a new terminal, or: export PATH=\"$INSTALL_DIR:\$PATH\""
    fi

    printf '\n%s\n\n' "  ${GREEN}${BOLD}yoshi-audit is ready.${RESET}" >&2
    cat >&2 <<FOOTER
  ${DIM}launch the TUI:${RESET}   ${CYAN}${BINARY}${RESET}
  ${DIM}inside:${RESET}           dashboard ${DIM}·${RESET} system audit ${DIM}·${RESET} Docker prune (press ${CYAN}?${RESET} for keys)
  ${DIM}config lives in:${RESET}  ~/.config/yoshi-audit/
FOOTER
    have just && [ -f "./Justfile" ] && printf '%s\n' "  ${DIM}dev commands:${RESET}    ${CYAN}just${RESET}" >&2
    printf '%s\n' "  ${DIM}docs: https://github.com/${REPO_OWNER}/${REPO_NAME}${RESET}" >&2
    return 0
}

main "$@" </dev/null

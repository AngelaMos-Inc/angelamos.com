#!/usr/bin/env bash
# ©AngelaMos | 2026
# install.sh
#
# One-shot installer for docksec, a Docker security audit tool (CIS Docker
# Benchmark scanner). Goes from a fresh machine to `docksec` on your PATH,
# whether run from a clone or piped from the web:
#
#   curl -fsSL https://angelamos.com/docksec/install.sh | bash

set -euo pipefail

# ============================================================================
# Config
# ============================================================================
REPO_OWNER="CarterPerez-dev"
REPO_NAME="docksec"
BINARY="docksec"
MODULE="github.com/${REPO_OWNER}/${REPO_NAME}/cmd/docksec"
GO_MIN="1.21"                     # auto-toolchain era; Go fetches go.mod's 1.24.x itself
GO_FALLBACK_VER="go1.24.4"
INSTALL_DIR="${DOCKSEC_INSTALL_DIR:-$HOME/.local/bin}"
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

   __| | ___   ___| | _____  ___  ___
  / _` |/ _ \ / __| |/ / __|/ _ \/ __|
 | (_| | (_) | (__|   <\__ \  __/ (__
  \__,_|\___/ \___|_|\_\___/\___|\___|
ART
    printf '%s\n' "${RESET}" >&2
    printf '%s\n' "  ${DIM}Docker security audit — CIS Docker Benchmark scanner${RESET}" >&2
}

# ============================================================================
# Privilege + download helpers (only used to bootstrap go if needed)
# ============================================================================
net_get_file() {   # net_get_file URL DEST
    if   have curl; then curl -fsSL "$1" -o "$2"
    elif have wget; then wget -qO "$2" "$1"
    else return 1; fi
}
net_get() {        # net_get URL -> stdout
    if   have curl; then curl -fsSL "$1"
    elif have wget; then wget -qO- "$1"
    else return 1; fi
}

# ============================================================================
# Args
# ============================================================================
usage() {
    cat >&2 <<USAGE
install.sh — install docksec

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
# OS / arch
# ============================================================================
case "$(uname -s)" in
    Linux) : ;;
    Darwin) : ;;
    MINGW*|MSYS*|CYGWIN*) die "Windows is not supported. Use WSL2." ;;
    *) die "unsupported OS: $(uname -s)" ;;
esac
case "$(uname -m)" in
    x86_64|amd64) GOARCH="amd64" ;;
    aarch64|arm64) GOARCH="arm64" ;;
    *) die "unsupported architecture: $(uname -m)" ;;
esac
GOOS_DL="$( [ "$(uname -s)" = "Darwin" ] && echo darwin || echo linux )"

# ============================================================================
# Go toolchain (official tarball if missing/old; Go auto-fetches go.mod's ver)
# ============================================================================
install_go() {
    local ver url dest="$GO_DIR"
    ver="$(net_get 'https://go.dev/VERSION?m=text' 2>/dev/null | head -1)"
    [ -n "$ver" ] || ver="$GO_FALLBACK_VER"
    url="https://go.dev/dl/${ver}.${GOOS_DL}-${GOARCH}.tar.gz"
    info "installing Go (${ver}, ${GOOS_DL}/${GOARCH}) to ${dest}"
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
        local f="$HOME/.config/fish/conf.d/docksec.fish"
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
    header "Building docksec"
    mkdir -p "$INSTALL_DIR"
    export GOBIN="$INSTALL_DIR"
    local self="${BASH_SOURCE[0]:-}" srcdir=""
    if [ -f "./go.mod" ] && [ -d "./cmd/docksec" ]; then
        srcdir="$(pwd)"
    elif [ -n "$self" ] && [ -f "$(dirname "$self")/go.mod" ] && [ -d "$(dirname "$self")/cmd/docksec" ]; then
        srcdir="$(cd "$(dirname "$self")" && pwd)"
    fi
    if [ -n "$srcdir" ]; then
        local ver; ver="$(cd "$srcdir" && git describe --tags --always --dirty 2>/dev/null || echo dev)"
        info "building from local source at $srcdir (version ${ver})"
        (cd "$srcdir" && go install -ldflags="-s -w -X main.version=${ver}" ./cmd/docksec) >&2
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
# Main (wrapped + stdin from /dev/null so `curl | bash` is always safe)
# ============================================================================
main() {
    banner
    have "$BINARY" && info "existing install at $(command -v "$BINARY") — updating"

    ensure_go
    install_binary
    add_path "$INSTALL_DIR"

    header "Verify"
    if have "$BINARY" && "$BINARY" version >/dev/null 2>&1; then
        ok "$("$BINARY" version 2>/dev/null | head -1)"
    else
        warn "installed to $INSTALL_DIR but not yet on this shell's PATH"
        warn "open a new terminal, or: export PATH=\"$INSTALL_DIR:\$PATH\""
    fi

    printf '\n%s\n\n' "  ${GREEN}${BOLD}docksec is ready.${RESET}" >&2
    cat >&2 <<FOOTER
  ${DIM}list CIS controls (no Docker needed):${RESET}  ${CYAN}${BINARY} benchmark list${RESET}
  ${DIM}scan a Dockerfile (no daemon needed):${RESET}  ${CYAN}${BINARY} scan -f Dockerfile${RESET}
  ${DIM}scan the live environment:${RESET}             ${CYAN}${BINARY} scan${RESET}
  ${DIM}json / sarif report:${RESET}                   ${CYAN}${BINARY} scan -o sarif --output-file report.sarif${RESET}
  ${DIM}every option:${RESET}                          ${CYAN}${BINARY} --help${RESET}
FOOTER
    printf '%s\n' "  ${DIM}note:${RESET} scanning the live daemon needs Docker access (the ${CYAN}docker${RESET} group, or run under sudo)" >&2
    printf '%s\n' "  ${DIM}docs: https://github.com/${REPO_OWNER}/${REPO_NAME}${RESET}" >&2
    return 0
}

main "$@" </dev/null

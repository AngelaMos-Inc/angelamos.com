#!/usr/bin/env bash
# ©AngelaMos | 2026
# install.sh
#
# One-shot installer for cre (Credential Rotation Enforcer). Goes from a fresh
# machine to `cre` on your PATH, whether run from a clone or piped from the web:
#
#   curl -fsSL https://angelamos.com/cre/install.sh | bash

set -euo pipefail

# ============================================================================
# Config
# ============================================================================
REPO_OWNER="CarterPerez-dev"
REPO_NAME="Cybersecurity-Projects"
SUBDIR="PROJECTS/intermediate/credential-rotation-enforcer"
BINARY="cre"
REPO_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}.git"
DEFAULT_BRANCH="main"
MIN_CRYSTAL="1.20.0"

INSTALL_DIR="${CRE_INSTALL_DIR:-$HOME/.local/bin}"

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

banner() {
    printf '%s' "${CYAN}${BOLD}" >&2
    cat >&2 <<'ART'

   ___ _ __ ___
  / __| '__/ _ \
 | (__| | |  __/
  \___|_|  \___|
ART
    printf '%s\n' "${RESET}" >&2
    printf '%s\n' "  ${DIM}Credential Rotation Enforcer — policy enforcement across vaults and secret managers${RESET}" >&2
}

# ============================================================================
# Privilege + package-manager fan
# ============================================================================
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if have sudo; then SUDO="sudo"; fi
fi

pkg_install() {
    if   have apt-get; then $SUDO apt-get update -y >/dev/null 2>&1 || warn "apt update had errors (often unrelated repos); continuing"
                            $SUDO apt-get install -y --no-install-recommends "$@"
    elif have dnf;     then $SUDO dnf install -y "$@"
    elif have pacman;  then $SUDO pacman -S --needed --noconfirm "$@"
    elif have zypper;  then $SUDO zypper install -y "$@"
    elif have apk;     then $SUDO apk add "$@"
    elif have brew;    then brew install "$@"
    else return 1; fi
}

# ============================================================================
# Args
# ============================================================================
usage() {
    cat >&2 <<USAGE
install.sh — install cre

  ./scripts/install.sh [options]
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
OS="$(uname -s)"; ARCH="$(uname -m)"
case "$OS" in
    Linux) OS="linux" ;;
    Darwin) OS="darwin" ;;
    MINGW*|MSYS*|CYGWIN*) die "Windows is not supported. Use WSL2." ;;
    *) die "unsupported OS: $OS" ;;
esac
case "$ARCH" in
    x86_64|amd64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) die "unsupported architecture: $ARCH" ;;
esac

# ============================================================================
# Bootstrap: locate the project (run from root, from scripts/, or cloned)
# ============================================================================
resolve_project() {
    if [ -f "./shard.yml" ] && [ -f "./src/cre.cr" ]; then pwd; return; fi
    local self="${BASH_SOURCE[0]:-}" d
    if [ -n "$self" ]; then
        d="$(cd "$(dirname "$self")" && pwd)"
        [ -f "$d/shard.yml" ] && { printf '%s\n' "$d"; return; }
        [ -f "$d/../shard.yml" ] && { (cd "$d/.." && pwd); return; }
    fi
    have git || { warn "git not found — installing it"; pkg_install git || die "could not install git; install it then re-run"; }
    have git || die "git is required to bootstrap cre"
    local cache="${XDG_CACHE_HOME:-$HOME/.cache}/cre-src"
    if [ -d "$cache/.git" ]; then
        info "updating cached clone at $cache"
        git -C "$cache" pull --ff-only --quiet 2>/dev/null || warn "pull failed; using existing clone"
    else
        info "cloning ${REPO_NAME}"
        git clone --depth 1 --branch "$DEFAULT_BRANCH" --filter=blob:none --quiet "$REPO_URL" "$cache" \
            || die "clone failed from ${REPO_URL}"
    fi
    printf '%s\n' "$cache/$SUBDIR"
}

# ============================================================================
# Crystal toolchain
# ============================================================================
install_crystal() {
    info "installing Crystal"
    if have apt-get || have dnf || have zypper; then
        if   have curl; then curl -fsSL https://crystal-lang.org/install.sh | $SUDO bash
        elif have wget; then wget -qO- https://crystal-lang.org/install.sh | $SUDO bash
        else die "need curl or wget to install Crystal (or see https://crystal-lang.org/install/)"; fi
    elif have pacman; then pkg_install crystal shards
    elif have brew;   then pkg_install crystal
    else die "could not auto-install Crystal; see https://crystal-lang.org/install/"; fi
}

ensure_crystal() {
    if have crystal; then
        local ver; ver="$(crystal version 2>/dev/null | head -1 | awk '{print $2}')"
        if [ -n "$ver" ] && [ "$(printf '%s\n%s\n' "$MIN_CRYSTAL" "$ver" | sort -V | head -1)" != "$MIN_CRYSTAL" ]; then
            warn "Crystal $ver is older than $MIN_CRYSTAL — upgrading"
            install_crystal
        else
            ok "Crystal ${ver:-detected}"
        fi
    else
        install_crystal
    fi
    have crystal || die "Crystal still not on PATH after install; open a new shell and re-run"
    have shards  || die "shards (Crystal's dependency manager) not found after install"
}

# ============================================================================
# System build libraries (sqlite3 + Crystal's compile/runtime libs)
# ============================================================================
ensure_build_deps() {
    if [ -e /usr/include/sqlite3.h ] || [ -e /opt/homebrew/include/sqlite3.h ] || [ -e /usr/local/include/sqlite3.h ]; then
        return
    fi
    info "installing build libraries (sqlite3 + ssl/pcre2/gmp/event)"
    if   have apt-get; then pkg_install libsqlite3-dev libssl-dev libpcre2-dev libgmp-dev libevent-dev zlib1g-dev libyaml-dev pkg-config build-essential
    elif have dnf;     then pkg_install sqlite-devel openssl-devel pcre2-devel gmp-devel libevent-devel zlib-devel libyaml-devel gcc make
    elif have pacman;  then pkg_install sqlite openssl pcre2 gmp libevent libyaml pkgconf
    elif have zypper;  then pkg_install sqlite3-devel libopenssl-devel pcre2-devel gmp-devel libevent-devel zlib-devel libyaml-devel gcc make
    elif have apk;     then pkg_install sqlite-dev openssl-dev pcre2-dev gmp-dev libevent-dev zlib-dev yaml-dev build-base
    elif have brew;    then pkg_install sqlite
    else warn "unknown package manager — ensure sqlite3 + Crystal build libraries are installed"; fi
}

# ============================================================================
# Build + install onto PATH
# ============================================================================
build_and_install() {
    header "Building cre (release)"
    info "resolving shard dependencies"
    shards install >&2
    info "compiling the release binary"
    shards build cre --release --no-debug >&2
    [ -x bin/cre ] || die "build produced no bin/cre"
    strip -s bin/cre 2>/dev/null || true
    mkdir -p "$INSTALL_DIR"
    install -m 0755 bin/cre "$INSTALL_DIR/cre"
    ok "installed cre -> ${INSTALL_DIR}/cre ($(du -h "$INSTALL_DIR/cre" | cut -f1))"
}

wire_path() {
    case ":$PATH:" in *":$INSTALL_DIR:"*) ok "$INSTALL_DIR already on PATH"; return ;; esac
    local shell rc=""
    shell="$(basename "${SHELL:-bash}")"
    case "$shell" in
        zsh)  rc="$HOME/.zshrc" ;;
        fish) mkdir -p "$HOME/.config/fish/conf.d"
              echo "fish_add_path $INSTALL_DIR" > "$HOME/.config/fish/conf.d/cre.fish"
              ok "added $INSTALL_DIR to PATH (fish)" ;;
        bash) rc="$HOME/.bashrc"; [ -f "$rc" ] || rc="$HOME/.bash_profile" ;;
        *)    rc="$HOME/.profile" ;;
    esac
    if [ -n "$rc" ] && ! grep -q "$INSTALL_DIR" "$rc" 2>/dev/null; then
        printf '\nexport PATH="%s:$PATH"\n' "$INSTALL_DIR" >> "$rc"
        ok "added $INSTALL_DIR to PATH in $rc"
    fi
    export PATH="$INSTALL_DIR:$PATH"
}

# ============================================================================
# Main
# ============================================================================
# Wrapped in main() and called with stdin from /dev/null so a child process can
# never eat the script when this is run as `curl ... | bash` (the script is
# bash's stdin); main runs only after bash has read the whole file.
main() {
    banner
    have "$BINARY" && info "existing install at $(command -v "$BINARY") — updating"

    PROJECT="$(resolve_project)"
    cd "$PROJECT"
    ensure_crystal
    ensure_build_deps
    build_and_install
    wire_path

    header "Verify"
    if have "$BINARY"; then
        ok "$($BINARY version 2>/dev/null || echo "$BINARY installed")"
    else
        warn "installed to $INSTALL_DIR but not yet on this shell's PATH"
        warn "open a new terminal, or: export PATH=\"$INSTALL_DIR:\$PATH\""
    fi

    printf '\n%s\n\n' "  ${GREEN}${BOLD}cre is ready.${RESET}" >&2
    cat >&2 <<FOOTER
  ${DIM}zero-deps demo:${RESET}      ${CYAN}${BINARY} demo${RESET}
  ${DIM}run the enforcer:${RESET}    ${CYAN}${BINARY} run --db sqlite:cre.db${RESET}
  ${DIM}every command:${RESET}       ${CYAN}${BINARY} --help${RESET}
FOOTER
    have just && [ -f "$PROJECT/justfile" ] && printf '%s\n' "  ${DIM}dev commands:${RESET}        ${CYAN}just${RESET}" >&2
    printf '%s\n' "  ${DIM}docs: learn/00-OVERVIEW.md  ·  https://github.com/${REPO_OWNER}/${REPO_NAME}${RESET}" >&2
    return 0
}

main "$@" </dev/null

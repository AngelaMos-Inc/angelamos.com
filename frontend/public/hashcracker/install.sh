#!/usr/bin/env bash
# ©AngelaMos | 2026
# install.sh
#
# One-shot installer for hashcracker. Goes from a fresh machine to `hashcracker`
# on your PATH with the bundled wordlists installed, whether run from a clone or
# piped from the web:
#
#   curl -fsSL https://angelamos.com/hashcracker/install.sh | bash

set -euo pipefail

# ============================================================================
# Config
# ============================================================================
REPO_OWNER="CarterPerez-dev"
REPO_NAME="Cybersecurity-Projects"
SUBDIR="PROJECTS/beginner/hash-cracker"
BINARY="hashcracker"
REPO_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}.git"
DEFAULT_BRANCH="main"

INSTALL_DIR="${HASHCRACKER_INSTALL_DIR:-$HOME/.local/bin}"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/hashcracker"
WORDLIST_DIR="$DATA_DIR/wordlists"

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

  _               _                          _
 | |__   __ _ ___| |__   ___ _ __ __ _  ___| | _____ _ __
 | '_ \ / _` / __| '_ \ / __| '__/ _` |/ __| |/ / _ \ '__|
 | | | | (_| \__ \ | | | (__| | | (_| | (__|   <  __/ |
 |_| |_|\__,_|___/_| |_|\___|_|  \__,_|\___|_|\_\___|_|
ART
    printf '%s\n' "${RESET}" >&2
    printf '%s\n' "  ${DIM}multithreaded hash cracker — dictionary, rules, brute force${RESET}" >&2
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
install.sh — install hashcracker

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
OS="$(uname -s)"
case "$OS" in
    Linux) OS="linux" ;;
    Darwin) OS="darwin" ;;
    MINGW*|MSYS*|CYGWIN*) die "Windows is not supported. Use WSL2." ;;
    *) die "unsupported OS: $OS" ;;
esac

# ============================================================================
# Bootstrap: locate the project, cloning the monorepo if piped from the web
# ============================================================================
resolve_project() {
    if [ -f "./CMakeLists.txt" ] && [ -d "./wordlists" ] && [ -f "./main.cpp" ]; then pwd; return; fi
    local self="${BASH_SOURCE[0]:-}"
    if [ -n "$self" ] && [ -f "$(dirname "$self")/CMakeLists.txt" ] && [ -d "$(dirname "$self")/wordlists" ]; then
        (cd "$(dirname "$self")" && pwd); return
    fi
    have git || { warn "git not found — installing it"; pkg_install git || die "could not install git; install it then re-run"; }
    have git || die "git is required to bootstrap hashcracker"
    local cache="${XDG_CACHE_HOME:-$HOME/.cache}/hashcracker-src"
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
# Build toolchain + libraries (compiler, cmake, ninja, openssl, boost)
# ============================================================================
ensure_build_deps() {
    local cc_ok=0 boost_ok=0
    if have g++ || have clang++; then cc_ok=1; fi
    if [ -e /usr/include/boost/program_options.hpp ] || [ -e /opt/homebrew/include/boost/program_options.hpp ] || [ -e /usr/local/include/boost/program_options.hpp ]; then boost_ok=1; fi
    if [ "$cc_ok" -eq 1 ] && [ "$boost_ok" -eq 1 ] && have cmake && have ninja; then
        ok "build toolchain present (cmake, ninja, c++, boost)"
        return
    fi
    info "installing build toolchain (compiler, cmake, ninja, openssl, boost)"
    if   have apt-get; then pkg_install g++ cmake ninja-build libssl-dev libboost-program-options-dev
    elif have dnf;     then pkg_install gcc-c++ cmake ninja-build openssl-devel boost-program-options boost-devel
    elif have pacman;  then pkg_install gcc cmake ninja openssl boost
    elif have zypper;  then pkg_install gcc-c++ cmake ninja openssl-devel libboost_program_options-devel
    elif have apk;     then pkg_install g++ cmake ninja-build openssl-dev boost-dev
    elif have brew;    then pkg_install cmake ninja openssl boost
    else die "unsupported package manager. Install manually: g++, cmake, ninja, libssl-dev, libboost-program-options-dev"; fi
}

# ============================================================================
# Build + install (binary onto PATH, wordlists into the data dir)
# ============================================================================
build_and_install() {
    header "Building hashcracker (release)"
    cmake --preset release >&2
    cmake --build build/release >&2
    [ -x build/release/hashcracker ] || die "build produced no build/release/hashcracker"
    strip -s build/release/hashcracker 2>/dev/null || true
    mkdir -p "$INSTALL_DIR"
    install -m 0755 build/release/hashcracker "$INSTALL_DIR/hashcracker"
    ok "installed hashcracker -> ${INSTALL_DIR}/hashcracker ($(du -h "$INSTALL_DIR/hashcracker" | cut -f1))"

    mkdir -p "$WORDLIST_DIR"
    install -m 0644 wordlists/*.txt "$WORDLIST_DIR/"
    ok "installed bundled wordlists -> ${WORDLIST_DIR}/"
}

wire_path() {
    case ":$PATH:" in *":$INSTALL_DIR:"*) ok "$INSTALL_DIR already on PATH"; return ;; esac
    local shell rc=""
    shell="$(basename "${SHELL:-bash}")"
    case "$shell" in
        zsh)  rc="$HOME/.zshrc" ;;
        fish) mkdir -p "$HOME/.config/fish/conf.d"
              echo "fish_add_path $INSTALL_DIR" > "$HOME/.config/fish/conf.d/hashcracker.fish"
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
# Main (wrapped + stdin from /dev/null so `curl | bash` is always safe)
# ============================================================================
main() {
    banner
    have "$BINARY" && info "existing install at $(command -v "$BINARY") — updating"

    PROJECT="$(resolve_project)"
    cd "$PROJECT"
    ensure_build_deps
    build_and_install
    wire_path

    header "Verify"
    if have "$BINARY" && "$BINARY" --help >/dev/null 2>&1; then
        ok "hashcracker is on PATH and runs"
    else
        warn "installed to $INSTALL_DIR but not yet on this shell's PATH"
        warn "open a new terminal, or: export PATH=\"$INSTALL_DIR:\$PATH\""
    fi

    printf '\n%s\n\n' "  ${GREEN}${BOLD}hashcracker is ready.${RESET}" >&2
    cat >&2 <<FOOTER
  ${DIM}crack one now (cracks to 'password'):${RESET}
    ${CYAN}${BINARY} --hash 5f4dcc3b5aa765d61d8327deb882cf99 --wordlist ${WORDLIST_DIR}/10k-most-common.txt${RESET}

  ${DIM}brute force:${RESET}      ${CYAN}${BINARY} --hash <md5> --bruteforce --charset lower,digits${RESET}
  ${DIM}wordlist + rules:${RESET} ${CYAN}${BINARY} --hash <md5> --wordlist ${WORDLIST_DIR}/10k-most-common.txt --rules${RESET}
  ${DIM}every option:${RESET}     ${CYAN}${BINARY} --help${RESET}
  ${DIM}bundled wordlists:${RESET} ${WORDLIST_DIR}/
FOOTER
    have just && [ -f "$PROJECT/Justfile" ] && printf '%s\n' "  ${DIM}dev commands:${RESET}     ${CYAN}just${RESET}" >&2
    printf '%s\n' "  ${DIM}docs: https://github.com/${REPO_OWNER}/${REPO_NAME}${RESET}" >&2
    return 0
}

main "$@" </dev/null

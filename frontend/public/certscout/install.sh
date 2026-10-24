#!/usr/bin/env bash
# © AngelaMos | 2026
# install.sh
#
# One-shot installer for certscout. Goes from a fresh machine to `certscout` on
# your PATH, whether run from a clone or piped from the web:
#
#   curl -fsSL https://angelamos.com/certscout/install.sh | bash
#
# certscout is an Elixir escript: it needs the Erlang runtime on PATH to run.
# When this script installs the toolchain (via mise) it puts the runtime on
# your PATH permanently, so `certscout` just works in every new shell.

set -euo pipefail

# ============================================================================
# Config
# ============================================================================
REPO_OWNER="CarterPerez-dev"
REPO_NAME="exs-cyberjob-scraper"
BINARY="certscout"
REPO_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}.git"
DEFAULT_BRANCH="main"
ERLANG_VER="27"
ELIXIR_MIN_MAJOR=1
ELIXIR_MIN_MINOR=18

INSTALL_DIR="${CERTSCOUT_INSTALL_DIR:-$HOME/.local/bin}"
MISE_SHIMS="$HOME/.local/share/mise/shims"
USED_MISE=0

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

   ____          _   ____                  _
  / ___|___ _ __| |_/ ___|  ___ ___  _   _| |_
 | |   / _ \ '__| __\___ \ / __/ _ \| | | | __|
 | |__|  __/ |  | |_ ___) | (_| (_) | |_| | |_
  \____\___|_|   \__|____/ \___\___/ \__,_|\__|
ART
    printf '%s\n' "${RESET}" >&2
    printf '%s\n' "  ${DIM}cybersecurity certification demand scanner${RESET}" >&2
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
install.sh — install certscout

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
OS="$(uname -s)"; ARCH="$(uname -m)"
case "$OS" in
    Linux) OS="linux" ;;
    Darwin) OS="darwin" ;;
    MINGW*|MSYS*|CYGWIN*) die "Windows is not supported. Use WSL2." ;;
    *) die "unsupported OS: $OS" ;;
esac

# ============================================================================
# Bootstrap: locate the project, cloning the repo if piped from the web
# ============================================================================
resolve_project() {
    if [ -f "./mix.exs" ] && [ -d "./lib/cert_scout" ]; then pwd; return; fi
    local self="${BASH_SOURCE[0]:-}" d
    if [ -n "$self" ]; then
        d="$(cd "$(dirname "$self")" && pwd)"
        [ -f "$d/mix.exs" ] && { printf '%s\n' "$d"; return; }
    fi
    have git || { warn "git not found — installing it"; pkg_install git || die "could not install git; install it then re-run"; }
    have git || die "git is required to bootstrap certscout"
    local cache="${XDG_CACHE_HOME:-$HOME/.cache}/certscout-src"
    if [ -d "$cache/.git" ]; then
        info "updating cached clone at $cache"
        git -C "$cache" pull --ff-only --quiet 2>/dev/null || warn "pull failed; using existing clone"
    else
        info "cloning ${REPO_NAME}"
        git clone --depth 1 --branch "$DEFAULT_BRANCH" --quiet "$REPO_URL" "$cache" \
            || die "clone failed from ${REPO_URL}"
    fi
    printf '%s\n' "$cache"
}

# ============================================================================
# Toolchain: reuse a good Elixir if present, else install a pinned one via mise
# ============================================================================
elixir_ok() {
    have mix && have elixir || return 1
    local v maj min
    v="$(elixir --version 2>/dev/null | sed -n 's/^Elixir \([0-9][0-9]*\)\.\([0-9][0-9]*\).*/\1 \2/p')"
    maj="${v%% *}"; min="${v##* }"
    [ -n "$maj" ] || return 1
    [ "$maj" -gt "$ELIXIR_MIN_MAJOR" ] 2>/dev/null && return 0
    [ "$maj" -eq "$ELIXIR_MIN_MAJOR" ] 2>/dev/null && [ "$min" -ge "$ELIXIR_MIN_MINOR" ] 2>/dev/null && return 0
    return 1
}

ensure_erlang_build_deps() {
    info "installing Erlang build dependencies (one-time)"
    if   have apt-get; then pkg_install build-essential automake autoconf m4 libncurses-dev libssl-dev libssh-dev unixodbc-dev libgmp-dev ca-certificates curl git
    elif have dnf;     then pkg_install make automake autoconf gcc gcc-c++ ncurses-devel openssl-devel libssh-devel unixODBC-devel gmp-devel ca-certificates
    elif have pacman;  then pkg_install base-devel ncurses openssl libssh unixodbc gmp
    elif have zypper;  then pkg_install -t pattern devel_basis || true
                            pkg_install automake autoconf ncurses-devel libopenssl-devel libssh-devel unixODBC-devel gmp-devel
    elif have apk;     then pkg_install build-base automake autoconf m4 ncurses-dev openssl-dev libssh-dev unixodbc-dev gmp-dev
    elif have brew;    then pkg_install autoconf openssl@3 wxwidgets
    else warn "unknown package manager — ensure a C toolchain + ncurses/openssl headers are present"; fi
}

install_via_mise() {
    USED_MISE=1
    ensure_erlang_build_deps

    if ! have mise && [ ! -x "$HOME/.local/bin/mise" ]; then
        info "installing mise (runtime version manager)"
        if   have curl; then curl -fsSL https://mise.run | sh
        elif have wget; then wget -qO- https://mise.run | sh
        else die "need curl or wget to install mise"; fi
    fi
    export PATH="$HOME/.local/bin:$MISE_SHIMS:$PATH"
    have mise || die "mise installed but not found on PATH"

    info "installing Erlang/OTP ${ERLANG_VER} (compiles from source — 5-10 min, grab a coffee)"
    mise use -g "erlang@${ERLANG_VER}" >&2

    # Elixir ships a separate build per OTP generation; a bare elixir@1.18 can
    # pick the otp-28 build, which then refuses to run on the OTP 27 above.
    info "selecting a matching Elixir (OTP ${ERLANG_VER} build)"
    local ev
    ev="$(mise ls-remote elixir 2>/dev/null | grep -E "^${ELIXIR_MIN_MAJOR}\.${ELIXIR_MIN_MINOR}\.[0-9]+-otp-${ERLANG_VER}$" | tail -1)"
    [ -n "$ev" ] || ev="$(mise ls-remote elixir 2>/dev/null | grep -E -- "-otp-${ERLANG_VER}\$" | tail -1)"
    [ -n "$ev" ] || die "no OTP-${ERLANG_VER} Elixir build found via mise (run 'mise ls-remote elixir')"
    info "  -> elixir ${ev}"
    mise use -g "elixir@${ev}" >&2
    hash -r

    have mix || die "Elixir still not on PATH after mise install"
    ok "Elixir $(elixir --version 2>/dev/null | sed -n 's/^Elixir //p' | head -1)"
}

ensure_toolchain() {
    if elixir_ok; then
        ok "Elixir $(elixir --version 2>/dev/null | sed -n 's/^Elixir //p' | head -1) (using existing)"
    else
        install_via_mise
    fi
}

# ============================================================================
# Build the escript
# ============================================================================
build_escript() {
    header "Building certscout"
    info "installing Hex + Rebar"
    mix local.hex --force >/dev/null
    mix local.rebar --force >/dev/null
    info "fetching dependencies"
    mix deps.get >&2
    info "compiling"
    mix compile >&2
    info "building the escript"
    mix escript.build >/dev/null
    [ -f "./certscout" ] || die "build produced no ./certscout escript"
}

install_binary() {
    mkdir -p "$INSTALL_DIR"
    install -m 0755 ./certscout "$INSTALL_DIR/certscout"
    ok "installed certscout -> ${INSTALL_DIR}/certscout ($(du -h "$INSTALL_DIR/certscout" | cut -f1))"
}

# ============================================================================
# PATH wiring (the escript dir, plus mise shims so escript stays reachable)
# ============================================================================
shell_rc() {
    case "$(basename "${SHELL:-bash}")" in
        zsh)  printf '%s\n' "$HOME/.zshrc" ;;
        bash) [ -f "$HOME/.bashrc" ] && printf '%s\n' "$HOME/.bashrc" || printf '%s\n' "$HOME/.bash_profile" ;;
        fish) printf '%s\n' "fish" ;;
        *)    printf '%s\n' "$HOME/.profile" ;;
    esac
}

add_path() {   # add_path DIR  — idempotently put DIR on PATH (rc + this process)
    local dir="$1" rc; rc="$(shell_rc)"
    case ":$PATH:" in *":$dir:"*) : ;; *) export PATH="$dir:$PATH" ;; esac
    if [ "$rc" = "fish" ]; then
        mkdir -p "$HOME/.config/fish/conf.d"
        local f="$HOME/.config/fish/conf.d/certscout.fish"
        grep -qs "$dir" "$f" 2>/dev/null || echo "fish_add_path $dir" >> "$f"
        return
    fi
    if ! grep -qs "$dir" "$rc" 2>/dev/null; then
        printf '\nexport PATH="%s:$PATH"\n' "$dir" >> "$rc"
        ok "added $dir to PATH in $rc"
    fi
}

wire_path() {
    add_path "$INSTALL_DIR"
    [ "$USED_MISE" -eq 1 ] && add_path "$MISE_SHIMS"
    return 0
}

# ============================================================================
# Main
#
# Wrapped in a function and called with stdin redirected from /dev/null. The
# BEAM (erlang/elixir/mix/escript) reads stdin on startup; under `curl | bash`
# the script IS bash's stdin, so an un-redirected `elixir` would swallow the
# rest of the script and bash would silently stop. main "$@" </dev/null runs
# only after bash has read the whole script, and gives every child /dev/null.
# ============================================================================
main() {
    banner
    have "$BINARY" && info "existing install at $(command -v "$BINARY") — updating"

    PROJECT="$(resolve_project)"
    cd "$PROJECT"
    ensure_toolchain
    build_escript
    install_binary
    wire_path

    header "Verify"
    if have "$BINARY" && "$BINARY" --help >/dev/null 2>&1; then
        ok "certscout is on PATH and runs"
    else
        warn "installed to $INSTALL_DIR but not runnable in this shell yet"
        warn "open a new terminal (the escript needs the Erlang runtime on PATH)"
    fi

    printf '\n%s\n\n' "  ${GREEN}${BOLD}certscout is ready.${RESET}" >&2
    cat >&2 <<FOOTER
  ${DIM}quick scan (no API keys, ~1 min):${RESET}   ${CYAN}${BINARY} --sources greenhouse${RESET}
  ${DIM}every option:${RESET}                       ${CYAN}${BINARY} --help${RESET}
  ${DIM}results land in:${RESET}                    ${CYAN}./output/REPORT.md${RESET}
FOOTER
    [ "$USED_MISE" -eq 1 ] && printf '%s\n' "  ${DIM}note:${RESET} new shells pick up Erlang via mise automatically" >&2
    have just && [ -f "$PROJECT/Justfile" ] && printf '%s\n' "  ${DIM}dev commands:${RESET}                       ${CYAN}just${RESET}" >&2
    printf '%s\n' "  ${DIM}docs: https://github.com/${REPO_OWNER}/${REPO_NAME}${RESET}" >&2
    return 0
}

main "$@" </dev/null

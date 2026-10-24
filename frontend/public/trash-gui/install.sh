#!/usr/bin/env bash
# ©AngelaMos | 2026
# install.sh
#
# One-shot installer for Trash Manager (trash-gui), a KDE/Qt6 desktop app with a
# polkit-privileged delete helper. Builds, installs system-wide, registers the
# launcher and polkit policy, and refreshes the desktop caches so it appears in
# your application menu / KRunner immediately. Run from a clone or piped:
#
#   curl -fsSL https://angelamos.com/trash-gui/install.sh | bash
#
# This is a system desktop app: it installs under /usr and uses sudo. The polkit
# policy hardcodes /usr/libexec/trash-helper, so the prefix must be /usr for the
# privileged-delete feature to work.

set -euo pipefail

# ============================================================================
# Config
# ============================================================================
REPO_OWNER="CarterPerez-dev"
REPO_NAME="trash-gui"
BINARY="trash-gui"
REPO_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}.git"
DEFAULT_BRANCH="main"
PREFIX="${TRASHGUI_PREFIX:-/usr}"

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

  _               _                       _
 | |_ _ __ __ _ ___| |__    __ _ _   _(_)
 | __| '__/ _` / __| '_ \  / _` | | | | |
 | |_| | | (_| \__ \ | | || (_| | |_| | |
  \__|_|  \__,_|___/_| |_| \__, |\__,_|_|
                           |___/
ART
    printf '%s\n' "${RESET}" >&2
    printf '%s\n' "  ${DIM}Trash Manager — KDE/Qt6 trash GUI with privileged deletion${RESET}" >&2
}

# ============================================================================
# Privilege + package-manager fan
# ============================================================================
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    have sudo || die "this app installs system-wide and needs root; install sudo or run as root"
    SUDO="sudo"
fi

pkg_install() {
    if   have apt-get; then $SUDO apt-get update -y >/dev/null 2>&1 || warn "apt update had errors (often unrelated repos); continuing"
                            $SUDO apt-get install -y --no-install-recommends "$@"
    elif have dnf;     then $SUDO dnf install -y "$@"
    elif have pacman;  then $SUDO pacman -S --needed --noconfirm "$@"
    elif have zypper;  then $SUDO zypper install -y "$@"
    elif have apk;     then $SUDO apk add "$@"
    else return 1; fi
}

# ============================================================================
# Args
# ============================================================================
usage() {
    cat >&2 <<USAGE
install.sh — install Trash Manager (trash-gui)

  ./install.sh [options]
  curl -fsSL https://angelamos.com/${BINARY}/install.sh | bash

options:
  --prefix DIR    install prefix (default: ${PREFIX}; polkit needs /usr)
  -h, --help      this help
USAGE
}
while [ $# -gt 0 ]; do
    case "$1" in
        --prefix) PREFIX="$2"; shift 2 ;;
        --prefix=*) PREFIX="${1#*=}"; shift ;;
        -h|--help) usage; exit 0 ;;
        *) die "unknown option: $1 (try --help)" ;;
    esac
done
[ "$PREFIX" = "/usr" ] || warn "prefix is ${PREFIX}, not /usr — privileged deletes may fail (polkit reads /usr/share/polkit-1)"

# ============================================================================
# OS gate (KDE/Qt6 + polkit is a Linux desktop stack)
# ============================================================================
case "$(uname -s)" in
    Linux) : ;;
    *) die "Trash Manager is a Linux/KDE desktop app (polkit, KF6, freedesktop). Linux only." ;;
esac

# ============================================================================
# Bootstrap: locate the project, cloning the repo if piped from the web
# ============================================================================
resolve_project() {
    if [ -f "./CMakeLists.txt" ] && [ -f "./org.trashgui.desktop" ]; then pwd; return; fi
    local self="${BASH_SOURCE[0]:-}"
    if [ -n "$self" ] && [ -f "$(dirname "$self")/org.trashgui.desktop" ]; then
        (cd "$(dirname "$self")" && pwd); return
    fi
    have git || { warn "git not found — installing it"; pkg_install git || die "could not install git; install it then re-run"; }
    have git || die "git is required to bootstrap trash-gui"
    local cache="${XDG_CACHE_HOME:-$HOME/.cache}/trash-gui-src"
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
# Build dependencies: Qt6 + KDE Frameworks 6 + ECM + toolchain
# ============================================================================
ecm_present() {
    [ -d /usr/share/ECM ] && return 0
    [ -d /usr/lib/cmake/ECM ] && return 0
    ls -d /usr/lib/*/cmake/ECM >/dev/null 2>&1 && return 0
    return 1
}

ensure_build_deps() {
    if have cmake && have ninja && { have g++ || have clang++; } && ecm_present; then
        ok "build toolchain present (cmake, ninja, c++, KF6/ECM)"
        return
    fi
    info "installing build dependencies (Qt6 + KDE Frameworks 6 + ECM)"
    if   have apt-get; then pkg_install cmake ninja-build g++ qt6-base-dev \
                                libkf6coreaddons-dev libkf6config-dev libkf6i18n-dev \
                                libkf6widgetsaddons-dev libkf6iconthemes-dev libkf6crash-dev \
                                extra-cmake-modules desktop-file-utils
    elif have dnf;     then pkg_install cmake ninja-build gcc-c++ qt6-qtbase-devel \
                                kf6-kcoreaddons-devel kf6-kconfig-devel kf6-ki18n-devel \
                                kf6-kwidgetsaddons-devel kf6-kiconthemes-devel kf6-kcrash-devel \
                                extra-cmake-modules desktop-file-utils
    elif have pacman;  then pkg_install cmake ninja gcc qt6-base \
                                kcoreaddons kconfig ki18n kwidgetsaddons kiconthemes kcrash \
                                extra-cmake-modules desktop-file-utils
    elif have zypper;  then pkg_install cmake ninja gcc-c++ qt6-base-devel \
                                kf6-kcoreaddons-devel kf6-kconfig-devel kf6-ki18n-devel \
                                kf6-kwidgetsaddons-devel kf6-kiconthemes-devel kf6-kcrash-devel \
                                extra-cmake-modules desktop-file-utils
    elif have apk;     then pkg_install cmake samurai g++ qt6-qtbase-dev \
                                kcoreaddons-dev kconfig-dev ki18n-dev kwidgetsaddons-dev \
                                kiconthemes-dev kcrash-dev extra-cmake-modules desktop-file-utils \
                                || warn "some KF6 packages may be unavailable on Alpine; check the build output"
    else die "unsupported package manager. Install: cmake, ninja, a C++ compiler, Qt6 base, KF6 (CoreAddons/Config/I18n/WidgetsAddons/IconThemes/Crash), extra-cmake-modules"; fi
}

# ============================================================================
# Build + system install + desktop integration
# ============================================================================
build_and_install() {
    header "Building Trash Manager (release)"
    cmake --preset system-release >&2
    cmake --build build/release >&2
    [ -x build/release/src/trash-gui ] || die "build produced no trash-gui binary"

    header "Installing to ${PREFIX} (sudo)"
    $SUDO cmake --install build/release --prefix "$PREFIX" >&2
    ok "installed: ${PREFIX}/bin/trash-gui, ${PREFIX}/libexec/trash-helper, polkit policy, .desktop"
}

refresh_desktop() {
    # Make the launcher show up in the menu / KRunner without a re-login.
    have update-desktop-database && $SUDO update-desktop-database "${PREFIX}/share/applications" >/dev/null 2>&1 || true
    have kbuildsycoca6 && kbuildsycoca6 >/dev/null 2>&1 || true
    return 0
}

# ============================================================================
# Main (wrapped + stdin from /dev/null so `curl | bash` is always safe; sudo
# still prompts because it reads the password from /dev/tty, not stdin)
# ============================================================================
main() {
    banner
    have "$BINARY" && info "existing install at $(command -v "$BINARY") — updating"

    PROJECT="$(resolve_project)"
    cd "$PROJECT"
    ensure_build_deps
    build_and_install
    refresh_desktop

    header "Verify"
    okcount=0
    have "$BINARY" && { okcount=$((okcount+1)); ok "binary on PATH: $(command -v "$BINARY")"; }
    [ -x "${PREFIX}/libexec/trash-helper" ] && { okcount=$((okcount+1)); ok "privileged helper installed"; }
    [ -f "${PREFIX}/share/applications/org.trashgui.desktop" ] && { okcount=$((okcount+1)); ok "launcher registered"; }
    [ -f "${PREFIX}/share/polkit-1/actions/org.trashgui.policy" ] && { okcount=$((okcount+1)); ok "polkit policy installed"; }
    [ "$okcount" -eq 4 ] || warn "some components missing (${okcount}/4) — check the build output above"

    printf '\n%s\n\n' "  ${GREEN}${BOLD}Trash Manager is ready.${RESET}" >&2
    cat >&2 <<FOOTER
  ${DIM}launch it:${RESET}          ${CYAN}trash-gui${RESET}
  ${DIM}or find it:${RESET}         app menu (System) ${DIM}/${RESET} KRunner (Alt+Space) ${DIM}->${RESET} "Trash Manager"
  ${DIM}privileged deletes:${RESET} authorized on demand via polkit
  ${DIM}uninstall:${RESET}          ${CYAN}${PROJECT}/uninstall.sh${RESET}
FOOTER
    have just && [ -f "$PROJECT/justfile" ] && printf '%s\n' "  ${DIM}dev commands:${RESET}       ${CYAN}just${RESET}" >&2
    printf '%s\n' "  ${DIM}docs: https://github.com/${REPO_OWNER}/${REPO_NAME}${RESET}" >&2
    return 0
}

main "$@" </dev/null

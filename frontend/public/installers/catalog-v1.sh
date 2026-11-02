#!/usr/bin/env bash
# ©AngelaMos | 2026
# catalog-v1.sh

set -euo pipefail
set -E

TOOL="${1:-}"
if [ "$#" -gt 0 ]; then shift; fi
REPO_URL=https://github.com/CarterPerez-dev/Cybersecurity-Projects.git
INSTALL_DIR="${ANGELAMOS_INSTALL_DIR:-${HOME:?HOME must be set}/.local/bin}"
CACHE_ROOT="${XDG_CACHE_HOME:-$HOME/.cache}/angelamos"
DATA_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/angelamos"
SOURCE_DIR="${ANGELAMOS_SOURCE_DIR:-}"
SOURCE_REF="${ANGELAMOS_REF:-main}"
JOBS="${ANGELAMOS_BUILD_JOBS:-2}"
ORIGINAL_PATH="$PATH"
TMP_DIR=""
LINK_DIR=""
SKIP_SYSTEM_DEPS=0
OS=""
ARCH=""
FAMILY=""
SUBDIR=""
PYTHON_VERSION=3.13
LINUX_ONLY=0
ALIASES=()
ROOT=()

if [ -t 2 ] && [ -z "${NO_COLOR:-}" ]; then
    CYAN=$'\033[36m' GREEN=$'\033[32m' YELLOW=$'\033[33m' RED=$'\033[31m' RESET=$'\033[0m'
else
    CYAN="" GREEN="" YELLOW="" RED="" RESET=""
fi

info() { printf '%s\n' "  ${CYAN}+${RESET} $*" >&2; }
ok() { printf '%s\n' "  ${GREEN}+${RESET} $*" >&2; }
warn() { printf '%s\n' "  ${YELLOW}!${RESET} $*" >&2; }
die() { printf '%s\n' "  ${RED}x${RESET} $*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

cleanup() {
    if [ -n "$TMP_DIR" ] && [ -d "$TMP_DIR" ]; then rm -rf -- "$TMP_DIR"; fi
    return 0
}
trap 'printf "Installation failed at line %s.\n" "$LINENO" >&2' ERR
trap cleanup EXIT

catalog() {
    case "$TOOL" in
        bomber) FAMILY=go; SUBDIR=intermediate/sbom-generator-vulnerability-matcher ;;
        sentinel) FAMILY=go; SUBDIR=beginner/systemd-persistence-scanner; LINUX_ONLY=1 ;;
        credenum) FAMILY=nim; SUBDIR=intermediate/credential-enumeration; LINUX_ONLY=1 ;;
        cisaudit) FAMILY=bash; SUBDIR=beginner/linux-cis-hardening-auditor; LINUX_ONLY=1 ;;
        fwrule) FAMILY=v; SUBDIR=beginner/firewall-rule-engine ;;
        dlp-scan) FAMILY=python; SUBDIR=intermediate/dlp-scanner ;;
        ebpf-tracer) FAMILY=bcc; SUBDIR=beginner/linux-ebpf-security-tracer; LINUX_ONLY=1 ;;
        not-sandboxed) FAMILY=python; SUBDIR=beginner/prompt-injection-firewall; PYTHON_VERSION=3.14 ;;
        aenebris) FAMILY=haskell; SUBDIR=advanced/haskell-reverse-proxy ;;
        hive) FAMILY=go; SUBDIR=advanced/honeypot-network ;;
        hsm-emulator) FAMILY=zig; SUBDIR=advanced/hsm-emulator; LINUX_ONLY=1 ;;
        netanal) FAMILY=python; SUBDIR=beginner/network-traffic-analyzer/python; PYTHON_VERSION=3.14 ;;
        hashid) FAMILY=python; SUBDIR=foundations/hash-identifier ;;
        headers) FAMILY=python; SUBDIR=foundations/http-headers-scanner ;;
        password-vault) FAMILY=python; SUBDIR=foundations/password-manager; ALIASES=(pv) ;;
        b64tool) FAMILY=python; SUBDIR=beginner/base64-tool; PYTHON_VERSION=3.14 ;;
        dnslookup) FAMILY=python; SUBDIR=beginner/dns-lookup ;;
        caesar-cipher) FAMILY=python; SUBDIR=beginner/caesar-cipher; PYTHON_VERSION=3.12 ;;
        simplePortScanner) FAMILY=cpp; SUBDIR=beginner/simple-port-scanner ;;
        *) die "Unknown tool: $TOOL" ;;
    esac
    SUBDIR="PROJECTS/$SUBDIR"
    CACHE_DIR="$CACHE_ROOT/$TOOL"
    DATA_DIR="$DATA_ROOT/$TOOL"
}

usage() {
    cat >&2 <<USAGE
$TOOL installer

  curl -fsSL https://angelamos.com/$TOOL/install.sh | bash

Options:
  --prefix DIR       Executable directory (default: ~/.local/bin)
  --source-dir DIR   Build a local project or Cybersecurity-Projects checkout
  --skip-system-deps Use system dependencies already installed by the operator
  -h, --help         Show this help

Installs prerequisites as needed. System packages may require sudo.
Supports Linux AMD64 and ARM64; portable tools also support macOS.
Re-run the command to update. Build concurrency defaults to two jobs.

Environment: ANGELAMOS_INSTALL_DIR, ANGELAMOS_SOURCE_DIR, ANGELAMOS_REF,
ANGELAMOS_BUILD_JOBS, XDG_CACHE_HOME, XDG_DATA_HOME, NO_COLOR.
USAGE
}

parse_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --prefix|--source-dir)
                [ "$#" -ge 2 ] && [ -n "$2" ] || die "$1 needs a value"
                case "$2" in --*) die "$1 needs a value" ;; esac
                if [ "$1" = --prefix ]; then INSTALL_DIR="$2"; else SOURCE_DIR="$2"; fi
                shift 2 ;;
            --prefix=*) INSTALL_DIR="${1#*=}"; shift ;;
            --source-dir=*) SOURCE_DIR="${1#*=}"; shift ;;
            --skip-system-deps) SKIP_SYSTEM_DEPS=1; shift ;;
            -h|--help) usage; exit 0 ;;
            *) die "Unknown option: $1 (try --help)" ;;
        esac
    done
    case "$INSTALL_DIR" in /*) ;; *) die "--prefix must be an absolute directory" ;; esac
    case "$INSTALL_DIR" in *:*|*$'\n'*|*$'\r'*) die "Invalid characters in --prefix" ;; esac
    [[ "$JOBS" =~ ^[1-9][0-9]*$ ]] || die "ANGELAMOS_BUILD_JOBS must be a positive integer"
    [[ "$SOURCE_REF" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || die "Invalid source ref"
}

download() {
    if have curl; then curl --fail --show-error --silent --location --retry 3 "$1" -o "$2"
    elif have wget; then wget -q -O "$2" "$1"
    else die "curl or wget is required"
    fi
}

checksum() {
    local actual
    [[ "$1" =~ ^[a-fA-F0-9]{64}$ ]] || die "Missing or invalid SHA256 checksum"
    if have sha256sum; then actual="$(sha256sum "$2")"
    elif have shasum; then actual="$(shasum -a 256 "$2")"
    else die "sha256sum or shasum is required"
    fi
    [ "${actual%% *}" = "$1" ] || die "Checksum mismatch: $2"
}

version_at_least() {
    awk -v actual="$1" -v minimum="$2" 'BEGIN {
        split(actual, a, "."); split(minimum, b, ".");
        for (i=1; i<=3; i++) {
            if ((a[i]+0) > (b[i]+0)) exit 0;
            if ((a[i]+0) < (b[i]+0)) exit 1;
        }
        exit 0;
    }'
}

root_access() {
    if [ "$(id -u)" -ne 0 ]; then
        have sudo || die "Installing system prerequisites requires sudo"
        ROOT=(sudo)
    fi
}

packages() {
    local group="$1"
    local names=()
    if [ "$SKIP_SYSTEM_DEPS" -eq 1 ]; then return; fi
    if have apt-get; then
        case "$group" in
            git) names=(git ca-certificates) ;;
            zip) names=(unzip) ;;
            xz) names=(xz-utils) ;;
            build) names=(build-essential pkg-config) ;;
            cpp) names=(build-essential pkg-config libboost-program-options-dev) ;;
            pcap) names=(libpcap-dev) ;;
            openssl) names=(libssl-dev pkg-config) ;;
            bcc) names=(python3 python3-venv python3-bpfcc bpfcc-tools) ;;
            pkcs11) names=(opensc) ;;
            haskell) names=(build-essential libgmp-dev libffi-dev libncurses-dev zlib1g-dev pkg-config) ;;
        esac
        root_access
        "${ROOT[@]}" apt-get update >&2
        "${ROOT[@]}" env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${names[@]}" >&2
    elif have dnf; then
        case "$group" in
            git) names=(git ca-certificates) ;; zip) names=(unzip) ;; xz) names=(xz) ;; build) names=(gcc gcc-c++ make pkgconf-pkg-config) ;;
            cpp) names=(gcc-c++ make boost-devel pkgconf-pkg-config) ;; pcap) names=(libpcap-devel) ;;
            openssl) names=(openssl-devel pkgconf-pkg-config) ;; bcc) names=(python3 python3-bcc bcc-tools) ;;
            pkcs11) names=(opensc) ;; haskell) names=(gcc gcc-c++ make gmp-devel libffi-devel ncurses-devel zlib-devel) ;;
        esac
        root_access; "${ROOT[@]}" dnf install -y "${names[@]}" >&2
    elif have pacman; then
        case "$group" in
            git) names=(git ca-certificates) ;; zip) names=(unzip) ;; xz) names=(xz) ;; build) names=(base-devel) ;; cpp) names=(base-devel boost) ;;
            pcap) names=(libpcap) ;; openssl) names=(openssl pkgconf) ;; bcc) names=(python bcc bcc-tools) ;;
            pkcs11) names=(opensc) ;; haskell) names=(base-devel gmp libffi ncurses zlib) ;;
        esac
        root_access; "${ROOT[@]}" pacman -S --needed --noconfirm "${names[@]}" >&2
    elif have zypper; then
        case "$group" in
            git) names=(git ca-certificates) ;; zip) names=(unzip) ;; xz) names=(xz) ;; build) names=(gcc gcc-c++ make pkg-config) ;;
            cpp) names=(gcc-c++ make libboost_program_options-devel pkg-config) ;; pcap) names=(libpcap-devel) ;;
            openssl) names=(libopenssl-devel pkg-config) ;; bcc) names=(python3 python3-bcc bcc-tools) ;;
            pkcs11) names=(opensc) ;; haskell) names=(gcc gcc-c++ make gmp-devel libffi-devel ncurses-devel zlib-devel) ;;
        esac
        root_access; "${ROOT[@]}" zypper --non-interactive install "${names[@]}" >&2
    elif have apk; then
        case "$group" in
            git) names=(git ca-certificates) ;; zip) names=(unzip) ;; xz) names=(xz) ;; build) names=(build-base pkgconf) ;; cpp) names=(build-base boost-dev pkgconf) ;;
            pcap) names=(libpcap-dev) ;; openssl) names=(openssl-dev pkgconf) ;; bcc) names=(python3 py3-bcc bcc-tools) ;;
            pkcs11) names=(opensc) ;; haskell) names=(build-base gmp-dev libffi-dev ncurses-dev zlib-dev) ;;
        esac
        root_access; "${ROOT[@]}" apk add --no-cache "${names[@]}" >&2
    elif have brew; then
        case "$group" in
            git) names=(git) ;; zip) names=(unzip) ;; xz) names=(xz) ;; build) names=(make pkg-config) ;; cpp) names=(boost ninja pkg-config) ;;
            pcap) names=(libpcap) ;; openssl) names=(openssl pkg-config) ;;
            haskell) names=(gmp libffi ncurses zlib pkg-config) ;;
            *) die "$group is not supported on macOS" ;;
        esac
        brew install "${names[@]}" >&2
    else
        die "No supported package manager for $group prerequisites (apt, dnf, pacman, zypper, apk, brew)"
    fi
}

platform() {
    case "$(uname -s)" in Linux) OS=linux ;; Darwin) OS=darwin ;; *) die "Use Linux or macOS; on Windows use a Linux VM or WSL" ;; esac
    case "$(uname -m)" in x86_64|amd64) ARCH=amd64 ;; aarch64|arm64) ARCH=arm64 ;; *) die "Only AMD64 and ARM64 are supported" ;; esac
    if [ "$LINUX_ONLY" -eq 1 ] && [ "$OS" != linux ]; then die "$TOOL requires Linux"; fi
}

prepare_path() {
    local directory
    mkdir -p "$INSTALL_DIR"
    [ -w "$INSTALL_DIR" ] || die "$INSTALL_DIR is not writable; choose --prefix"
    case ":$ORIGINAL_PATH:" in *":$INSTALL_DIR:"*) return ;; esac
    for directory in "$HOME/.local/bin" "$HOME/bin" /usr/local/bin; do
        case ":$ORIGINAL_PATH:" in
            *":$directory:"*)
                if [ -w "$directory" ]; then LINK_DIR="$directory"; break; fi
                if [ "$directory" = /usr/local/bin ]; then
                    root_access; LINK_DIR="$directory"; break
                fi ;;
        esac
    done
    [ -n "$LINK_DIR" ] || die "No writable directory on the current PATH. Use --prefix with a PATH directory."
}

resolve_source() {
    local cache="$CACHE_DIR/source/$SOURCE_REF" origin
    if [ -n "$SOURCE_DIR" ]; then
        if [ -d "$SOURCE_DIR/$SUBDIR" ]; then SOURCE_DIR="$SOURCE_DIR/$SUBDIR"; fi
        [ -f "$SOURCE_DIR/README.md" ] || die "--source-dir must contain the $TOOL project"
    elif [ -d "$PWD/$SUBDIR" ]; then
        SOURCE_DIR="$PWD/$SUBDIR"
    elif have git && [ "$(git rev-parse --show-prefix 2>/dev/null || true)" = "$SUBDIR/" ]; then
        SOURCE_DIR="$PWD"
    else
        if ! have git; then packages git; fi
        have git || die "Git is required to download the source"
        if [ -e "$cache" ]; then
            [ -d "$cache/.git" ] || die "Unexpected source cache: $cache"
            origin="$(git -C "$cache" remote get-url origin)"
            [ "$origin" = "$REPO_URL" ] || die "Source cache has a different origin"
            [ -z "$(git -C "$cache" status --porcelain)" ] || die "Source cache contains edits: $cache"
            [ "$(git -C "$cache" branch --show-current)" = "$SOURCE_REF" ] || die "Source cache is on a different ref"
            git -C "$cache" pull --ff-only >&2
        else
            mkdir -p "$(dirname "$cache")"
            git clone --depth 1 --filter=blob:none --sparse --branch "$SOURCE_REF" "$REPO_URL" "$cache" >&2
            git -C "$cache" sparse-checkout set "$SUBDIR" >&2
        fi
        SOURCE_DIR="$cache/$SUBDIR"
    fi
    [ -d "$SOURCE_DIR" ] || die "Project is missing: $SUBDIR"
    mkdir -p "$TMP_DIR/source"
    (
        cd "$SOURCE_DIR"
        tar --exclude=.git --exclude=.venv --exclude=node_modules --exclude=.stack-work \
            --exclude=dist-newstyle --exclude=.zig-cache --exclude=zig-out --exclude=build \
            --exclude=bin --exclude=.env --exclude='.env.*' --exclude=__pycache__ \
            --exclude=.pytest_cache --exclude=.mypy_cache --exclude=.ruff_cache -cf - .
    ) | tar -xf - -C "$TMP_DIR/source"
    SOURCE_DIR="$TMP_DIR/source"
}

ensure_uv() {
    if have uv && version_at_least "$(uv --version 2>/dev/null | awk '{print $2}' || true)" 0.9.0; then return; fi
    local destination="$CACHE_ROOT/toolchains/uv"
    if [ ! -x "$destination/uv" ]; then
        download https://astral.sh/uv/install.sh "$TMP_DIR/uv-install.sh"
        UV_UNMANAGED_INSTALL="$destination" sh "$TMP_DIR/uv-install.sh" >&2
    fi
    export PATH="$destination:$PATH"
    have uv || die "uv installation failed"
}

ensure_build() {
    if ! have cc || ! have make || ! have pkg-config; then packages build; fi
    have cc && have make || die "A C compiler and make are required"
}

install_python() {
    if [ "$TOOL" = netanal ] && ! pkg-config --exists libpcap; then packages pcap; fi
    ensure_uv
    UV_TOOL_DIR="$DATA_DIR/uv" UV_TOOL_BIN_DIR="$INSTALL_DIR" \
        uv tool install --force --upgrade --python "$PYTHON_VERSION" "$SOURCE_DIR" >&2
}

install_go() {
    local version archive expected destination go_bin
    go_bin="$(command -v go || true)"
    if [ -z "$go_bin" ] || ! version_at_least "$(GOTOOLCHAIN=local "$go_bin" env GOVERSION | cut -c 3-)" 1.25.0; then
        download 'https://go.dev/VERSION?m=text' "$TMP_DIR/go-version"
        IFS= read -r version < "$TMP_DIR/go-version"
        [[ "$version" =~ ^go[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "Invalid Go version response"
        archive="$version.$OS-$ARCH.tar.gz"
        destination="$CACHE_ROOT/toolchains/$version-$OS-$ARCH"
        go_bin="$destination/go/bin/go"
        if [ ! -x "$go_bin" ]; then
            download 'https://go.dev/dl/?mode=json&include=all' "$TMP_DIR/go-releases.json"
            expected="$(awk -v archive="$archive" '
                /"filename":/ { wanted = index($0, "\"" archive "\"") > 0 }
                wanted && /"sha256":/ {gsub(/[",[:space:]]/, ""); sub(/^sha256:/, ""); print; exit}
            ' "$TMP_DIR/go-releases.json")"
            download "https://go.dev/dl/$archive" "$TMP_DIR/go.tar.gz"
            checksum "$expected" "$TMP_DIR/go.tar.gz"
            mkdir -p "$destination"
            tar -xzf "$TMP_DIR/go.tar.gz" -C "$destination"
        fi
    fi
    (
        cd "$SOURCE_DIR"
        unset GOROOT
        CGO_ENABLED=0 GOTOOLCHAIN=auto "$go_bin" build -p "$JOBS" -trimpath -buildvcs=false \
            -ldflags='-s -w' -o "$TMP_DIR/$TOOL" "./cmd/$TOOL"
    )
    install -m 0755 "$TMP_DIR/$TOOL" "$INSTALL_DIR/$TOOL"
    if [ "$TOOL" = hive ]; then
        mkdir -p "$DATA_DIR"
        if [ -d "$SOURCE_DIR/infra" ]; then cp -R "$SOURCE_DIR/infra" "$DATA_DIR/"; fi
        info "The hive CLI is installed. Serving the network requires its PostgreSQL configuration."
    fi
}

install_bash() {
    [ "${BASH_VERSINFO[0]}" -ge 4 ] || die "cisaudit requires Bash 4 or newer"
    mkdir -p "$DATA_DIR"
    cp -R "$SOURCE_DIR/src" "$DATA_DIR/"
    {
        printf '#!/usr/bin/env bash\n# ©AngelaMos | 2026\n# cisaudit\n'
        printf 'exec bash %q "$@"\n' "$DATA_DIR/src/cisaudit.sh"
    } > "$TMP_DIR/$TOOL"
    install -m 0755 "$TMP_DIR/$TOOL" "$INSTALL_DIR/$TOOL"
}

install_nim() {
    ensure_build
    local nim_bin current
    nim_bin="$(command -v nim || true)"
    current=""
    if [ -n "$nim_bin" ]; then current="$("$nim_bin" --version 2>/dev/null | awk 'NR==1 {print $4}' || true)"; fi
    if ! version_at_least "$current" 2.2.0; then
        download https://nim-lang.org/choosenim/init.sh "$TMP_DIR/choosenim.sh"
        CHOOSENIM_NO_ANALYTICS=1 sh "$TMP_DIR/choosenim.sh" -y >&2
        export PATH="$HOME/.nimble/bin:$PATH"
        nim_bin="$(command -v nim)"
        current="$("$nim_bin" --version | awk 'NR==1 {print $4}')"
    fi
    version_at_least "$current" 2.2.0 || die "Nim 2.2 or newer is required"
    (
        cd "$SOURCE_DIR"
        "$nim_bin" c -d:release --opt:size --parallelBuild:"$JOBS" \
            --nimcache:"$CACHE_DIR/nimcache" -o:"$TMP_DIR/$TOOL" src/harvester.nim >&2
    )
    if have strip; then strip "$TMP_DIR/$TOOL"; fi
    install -m 0755 "$TMP_DIR/$TOOL" "$INSTALL_DIR/$TOOL"
}

install_v() {
    ensure_build
    local v_bin current archive expected destination="$CACHE_ROOT/toolchains/v-0.5.1-$OS-$ARCH"
    v_bin="$(command -v v || true)"
    current=""
    if [ -n "$v_bin" ]; then current="$("$v_bin" version 2>/dev/null | awk '{print $2}' || true)"; fi
    if ! version_at_least "$current" 0.5.1; then
        v_bin="$destination/v/v"
        if [ ! -x "$v_bin" ]; then
            case "$OS-$ARCH" in
                linux-amd64) archive=v_linux.zip; expected=0c35c79343b308e0415619d8e6d8da340c6a24c18331123553cc686ffb18abf4 ;;
                linux-arm64) archive=v_linux_arm64.zip; expected=3e1c290faffbe98b54337301d1f65045cd0f1618a7bf20fd4b4c820de52e1951 ;;
                darwin-amd64) archive=v_macos_x86_64.zip; expected=04918d73d41ae16ec49d5169ea737ea61c0e0bf28d023bd6661d06b708c806eb ;;
                darwin-arm64) archive=v_macos_arm64.zip; expected=226c96c63d8caa6909fc91a8026e8fbffa30264fec4dc0495b9e1536a98f6c7c ;;
            esac
            if ! have unzip; then packages zip; fi
            download "https://github.com/vlang/v/releases/download/0.5.1/$archive" "$TMP_DIR/v.zip"
            checksum "$expected" "$TMP_DIR/v.zip"
            mkdir -p "$destination"
            unzip -q -o "$TMP_DIR/v.zip" -d "$destination"
        fi
        "$v_bin" version >&2
    fi
    "$v_bin" -prod -o "$TMP_DIR/$TOOL" "$SOURCE_DIR/src" >&2
    if have strip; then strip "$TMP_DIR/$TOOL"; fi
    install -m 0755 "$TMP_DIR/$TOOL" "$INSTALL_DIR/$TOOL"
}

install_cpp() {
    if ! have c++ || ! printf '#include <boost/program_options.hpp>\nint main() {}\n' | \
        c++ -x c++ - -lboost_program_options -o "$TMP_DIR/boost-check" >/dev/null 2>&1; then packages cpp; fi
    local cmake_bin
    cmake_bin="$(command -v cmake || true)"
    if [ -z "$cmake_bin" ] || ! version_at_least "$("$cmake_bin" --version | awk 'NR==1 {print $3}')" 3.31.0; then
        ensure_uv
        UV_TOOL_DIR="$CACHE_ROOT/toolchains/uv-tools" UV_TOOL_BIN_DIR="$CACHE_ROOT/toolchains/bin" \
            uv tool install --force --python 3.13 cmake==3.31.6 >&2
        cmake_bin="$CACHE_ROOT/toolchains/bin/cmake"
    fi
    "$cmake_bin" -S "$SOURCE_DIR" -B "$TMP_DIR/build" -DCMAKE_BUILD_TYPE=Release >&2
    "$cmake_bin" --build "$TMP_DIR/build" --parallel "$JOBS" >&2
    install -m 0755 "$TMP_DIR/build/$TOOL" "$INSTALL_DIR/$TOOL"
}

install_bcc() {
    if ! /usr/bin/python3 -c 'from bcc import BPF' >/dev/null 2>&1; then packages bcc; fi
    /usr/bin/python3 -c 'from bcc import BPF' || die "The distribution Python BCC bindings are required"
    local release
    release="$(uname -r)"
    if [ ! -e "/lib/modules/$release/build" ] && [ ! -r /sys/kernel/kheaders.tar.xz ]; then
        if [ "$SKIP_SYSTEM_DEPS" -eq 0 ]; then
            root_access
            if have apt-get; then "${ROOT[@]}" apt-get install -y "linux-headers-$release" >&2
            elif have dnf; then "${ROOT[@]}" dnf install -y "kernel-devel-$release" >&2
            elif have pacman; then "${ROOT[@]}" pacman -S --needed --noconfirm linux-headers >&2
            else die "Install kernel headers matching $release before using eBPF"; fi
        fi
        [ -e "/lib/modules/$release/build" ] || die "Kernel headers for $release are unavailable"
    fi
    ensure_uv
    uv venv --allow-existing --system-site-packages --python /usr/bin/python3 "$DATA_DIR/venv" >&2
    uv pip install --python "$DATA_DIR/venv/bin/python" --upgrade "$SOURCE_DIR" >&2
    "$DATA_DIR/venv/bin/python" -c 'from bcc import BPF; from src.config import EBPF_DIR; assert (EBPF_DIR / "process_tracer.c").is_file()'
    ln -sfn "$DATA_DIR/venv/bin/ebpf-tracer" "$INSTALL_DIR/ebpf-tracer"
    info "Live tracing requires root and a kernel with BPF support."
}

install_haskell() {
    local stack_bin
    if ! have xz; then packages xz; fi
    if ! have cc || ! pkg-config --exists gmp libffi zlib; then packages haskell; fi
    stack_bin="$(command -v stack || true)"
    if [ -z "$stack_bin" ]; then
        packages haskell
        download https://get-ghcup.haskell.org "$TMP_DIR/ghcup.sh"
        BOOTSTRAP_HASKELL_NONINTERACTIVE=1 BOOTSTRAP_HASKELL_MINIMAL=1 \
            BOOTSTRAP_HASKELL_ADJUST_BASHRC=0 sh "$TMP_DIR/ghcup.sh" >&2
        "$HOME/.ghcup/bin/ghcup" install stack >&2
        stack_bin="$HOME/.ghcup/bin/stack"
    fi
    mkdir -p "$DATA_DIR/bin"
    (
        cd "$SOURCE_DIR"
        PATH="$DATA_DIR/bin:$PATH" "$stack_bin" --jobs "$JOBS" build --copy-bins --local-bin-path "$DATA_DIR/bin" >&2
    )
    cp -R "$SOURCE_DIR/examples" "$DATA_DIR/"
    {
        printf '#!/usr/bin/env bash\n# ©AngelaMos | 2026\n# aenebris\n'
        printf 'case "${1:-}" in\n'
        printf '  -h|--help|"") printf "Usage: aenebris CONFIG.yaml\\nExample configurations: %%s\\n" %q; exit 0 ;;\n' "$DATA_DIR/examples"
        printf 'esac\nexec %q "$@"\n' "$DATA_DIR/bin/aenebris"
    } > "$TMP_DIR/$TOOL"
    install -m 0755 "$TMP_DIR/$TOOL" "$INSTALL_DIR/$TOOL"
}

install_zig() {
    local zig_bin version expected machine destination="$CACHE_ROOT/toolchains/zig-0.16.0-$ARCH"
    zig_bin="$(command -v zig || true)"
    version=""
    if [ -n "$zig_bin" ]; then version="$("$zig_bin" version 2>/dev/null || true)"; fi
    if [ "$version" != 0.16.0 ]; then
        zig_bin="$destination/zig"
        if [ ! -x "$zig_bin" ]; then
            machine=x86_64; if [ "$ARCH" = arm64 ]; then machine=aarch64; fi
            download https://ziglang.org/download/index.json "$TMP_DIR/zig-index.json"
            expected="$(awk -v machine="$machine-linux" '
                /"0.16.0":/ {version=1}
                version && index($0, "\"" machine "\"") {platform=1}
                platform && /"shasum":/ {gsub(/[",[:space:]]/, ""); sub(/^shasum:/, ""); print; exit}
            ' "$TMP_DIR/zig-index.json")"
            download "https://ziglang.org/download/0.16.0/zig-$machine-linux-0.16.0.tar.xz" "$TMP_DIR/zig.tar.xz"
            checksum "$expected" "$TMP_DIR/zig.tar.xz"
            if ! have xz; then packages xz; fi
            mkdir -p "$destination"
            tar -xJf "$TMP_DIR/zig.tar.xz" --strip-components=1 -C "$destination"
        fi
    fi
    if ! pkg-config --exists openssl; then packages openssl; fi
    if ! have pkcs11-tool; then packages pkcs11; fi
    (
        cd "$SOURCE_DIR"
        "$zig_bin" build --release=safe -j"$JOBS" --prefix "$DATA_DIR" >&2
    )
    {
        printf '#!/usr/bin/env bash\n# ©AngelaMos | 2026\n# hsm-emulator\n'
        printf 'set -euo pipefail\n'
        printf 'state="${XDG_DATA_HOME:-$HOME/.local/share}/angelamos/hsm-emulator/token"\n'
        printf 'mkdir -p "$state"\nchmod 700 "$state"\n'
        printf 'export ANGELAMOS_HSM_TOKEN="${ANGELAMOS_HSM_TOKEN:-$state/token.bin}"\n'
        printf 'export ANGELAMOS_HSM_OBJECTS="${ANGELAMOS_HSM_OBJECTS:-$state/objects.bin}"\n'
        printf 'if [ "$#" -eq 0 ]; then set -- --list-slots; fi\n'
        printf 'exec pkcs11-tool --module %q "$@"\n' "$DATA_DIR/lib/libhsm.so"
    } > "$TMP_DIR/$TOOL"
    install -m 0755 "$TMP_DIR/$TOOL" "$INSTALL_DIR/$TOOL"
    "$INSTALL_DIR/$TOOL" --list-slots >&2
}

wire_path() {
    local command rc line shell_name resolved
    if [ -n "$LINK_DIR" ]; then
        for command in "$TOOL" "${ALIASES[@]}"; do
            if [ -w "$LINK_DIR" ]; then ln -sfn "$INSTALL_DIR/$command" "$LINK_DIR/$command"
            else "${ROOT[@]}" ln -sfn "$INSTALL_DIR/$command" "$LINK_DIR/$command"; fi
        done
        shell_name="${SHELL:-bash}"
        shell_name="${shell_name##*/}"
        case "$shell_name" in
            fish) rc="$HOME/.config/fish/conf.d/angelamos-tools.fish"; printf -v line 'fish_add_path -- %q' "$INSTALL_DIR" ;;
            zsh) rc="${ZDOTDIR:-$HOME}/.zshrc"; printf -v line 'export PATH=%q:"$PATH"' "$INSTALL_DIR" ;;
            bash) rc="$HOME/.bashrc"; printf -v line 'export PATH=%q:"$PATH"' "$INSTALL_DIR" ;;
            *) rc="$HOME/.profile"; printf -v line 'export PATH=%q:"$PATH"' "$INSTALL_DIR" ;;
        esac
        mkdir -p "$(dirname "$rc")"
        if ! grep -qxF "$line" "$rc" 2>/dev/null; then printf '\n%s\n' "$line" >> "$rc"; fi
    fi
    resolved="$(PATH="$ORIGINAL_PATH" command -v "$TOOL")" || die "$TOOL is not on the original PATH"
    [ "$resolved" -ef "$INSTALL_DIR/$TOOL" ] || die "An older $TOOL shadows the installation at $resolved"
}

main() {
    catalog
    parse_args "$@"
    platform
    printf '\n%s[ AngelaMos / %s ]%s\n  Install the tool and its prerequisites.\n\n' "$CYAN" "$TOOL" "$RESET" >&2
    TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/angelamos-$TOOL.XXXXXXXX")"
    mkdir -p "$CACHE_DIR" "$DATA_DIR"
    prepare_path
    export PATH="$INSTALL_DIR:$PATH"
    resolve_source
    info "Building $TOOL for $OS/$ARCH"
    case "$FAMILY" in
        python) install_python ;; go) install_go ;; bash) install_bash ;; nim) install_nim ;;
        v) install_v ;; cpp) install_cpp ;; bcc) install_bcc ;; haskell) install_haskell ;; zig) install_zig ;;
    esac
    if [ "$FAMILY" != zig ]; then "$INSTALL_DIR/$TOOL" --help >/dev/null; fi
    wire_path
    ok "$TOOL is installed. Run: $TOOL --help"
    info "Docs: https://github.com/CarterPerez-dev/Cybersecurity-Projects/tree/main/$SUBDIR"
    if have just; then info "Project recipes are available with just in a source checkout."; fi
}

main "$@" </dev/null

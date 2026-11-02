#!/usr/bin/env bash
# ©AngelaMos | 2026
# install.sh

set -euo pipefail
TOOL=cisaudit
TMP_DIR=""
cleanup() { if [ -n "$TMP_DIR" ]; then rm -rf -- "$TMP_DIR"; fi; return 0; }
trap cleanup EXIT
trap 'printf "Installer download failed.\n" >&2' ERR

main() {
    local base="${ANGELAMOS_INSTALL_BASE_URL:-https://angelamos.com}" expected actual
    TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/angelamos-bootstrap.XXXXXXXX")"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL --retry 3 "$base/installers/catalog-v1.sh" -o "$TMP_DIR/runtime.sh"
        curl -fsSL --retry 3 "$base/installers/catalog-v1.sh.sha256" -o "$TMP_DIR/checksum"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$TMP_DIR/runtime.sh" "$base/installers/catalog-v1.sh"
        wget -qO "$TMP_DIR/checksum" "$base/installers/catalog-v1.sh.sha256"
    else printf 'curl or wget is required.\n' >&2; exit 1; fi
    read -r expected _ < "$TMP_DIR/checksum"
    [[ "$expected" =~ ^[a-f0-9]{64}$ ]] || { printf 'Invalid installer checksum.\n' >&2; exit 1; }
    if command -v sha256sum >/dev/null 2>&1; then actual="$(sha256sum "$TMP_DIR/runtime.sh")"
    elif command -v shasum >/dev/null 2>&1; then actual="$(shasum -a 256 "$TMP_DIR/runtime.sh")"
    else printf 'sha256sum or shasum is required.\n' >&2; exit 1; fi
    [ "${actual%% *}" = "$expected" ] || { printf 'Installer checksum mismatch.\n' >&2; exit 1; }
    bash "$TMP_DIR/runtime.sh" "$TOOL" "$@" </dev/null
}

main "$@" </dev/null

#!/usr/bin/env bash
# =============================================================================
# AngelaMos | 2026
# randomize-ports.sh
# =============================================================================
# Picks fresh non-colliding host ports and writes them into .env,
# .env.development, compose.yml and dev.compose.yml. File edits are done in
# pure Python (no sed) so a bad pattern can never truncate a file.
# =============================================================================

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$DIR" <<'PY'
import random, re, sys, pathlib

root = pathlib.Path(sys.argv[1])

keys = ["PROD_NGINX", "PROD_FRONTEND",
        "DEV_NGINX", "DEV_FRONTEND", "DEV_API", "DEV_DB", "DEV_REDIS"]
ports = random.sample(range(10000, 60001), len(keys))
p = dict(zip(keys, ports))

def edit(path, repls):
    f = root / path
    text = f.read_text()
    for pat, rep in repls:
        text = re.sub(pat, rep, text, flags=re.M)
    f.write_text(text)
    print(f"  updated {path}")

# env files: KEY=VALUE
edit(".env", [
    (r"^NGINX_HOST_PORT=.*$",    f"NGINX_HOST_PORT={p['PROD_NGINX']}"),
    (r"^FRONTEND_HOST_PORT=.*$", f"FRONTEND_HOST_PORT={p['PROD_FRONTEND']}"),
])
edit(".env.development", [
    (r"^NGINX_HOST_PORT=.*$",    f"NGINX_HOST_PORT={p['DEV_NGINX']}"),
    (r"^FRONTEND_HOST_PORT=.*$", f"FRONTEND_HOST_PORT={p['DEV_FRONTEND']}"),
    (r"^API_HOST_PORT=.*$",      f"API_HOST_PORT={p['DEV_API']}"),
    (r"^DB_HOST_PORT=.*$",       f"DB_HOST_PORT={p['DEV_DB']}"),
    (r"^REDIS_HOST_PORT=.*$",    f"REDIS_HOST_PORT={p['DEV_REDIS']}"),
])

# compose default fallbacks: ${KEY:-NNNNN}
edit("compose.yml", [
    (r"\$\{NGINX_HOST_PORT:-\d+\}", f"${{NGINX_HOST_PORT:-{p['PROD_NGINX']}}}"),
])
edit("dev.compose.yml", [
    (r"\$\{NGINX_HOST_PORT:-\d+\}",    f"${{NGINX_HOST_PORT:-{p['DEV_NGINX']}}}"),
    (r"\$\{FRONTEND_HOST_PORT:-\d+\}", f"${{FRONTEND_HOST_PORT:-{p['DEV_FRONTEND']}}}"),
    (r"\$\{API_HOST_PORT:-\d+\}",      f"${{API_HOST_PORT:-{p['DEV_API']}}}"),
    (r"\$\{DB_HOST_PORT:-\d+\}",       f"${{DB_HOST_PORT:-{p['DEV_DB']}}}"),
    (r"\$\{REDIS_HOST_PORT:-\d+\}",    f"${{REDIS_HOST_PORT:-{p['DEV_REDIS']}}}"),
])

print("\nNew host ports:")
for k in keys:
    print(f"  {k.lower():14} {p[k]}")
PY

echo ""
echo "Done. Restart dev with: just dev-down && just dev-up"

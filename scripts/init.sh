#!/usr/bin/env bash
# =============================================================================
# AngelaMos | 2026
# init.sh
# =============================================================================
# Run once after copying the template: set the project name/title across the
# env files + frontend, then randomize all host ports. Pure-Python edits.
# =============================================================================

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo ""
read -rp "Project name (kebab-case): " RAW

python3 - "$DIR" "$RAW" <<'PY'
import re, sys, pathlib

root = pathlib.Path(sys.argv[1])
raw = sys.argv[2]

slug = re.sub(r"[^a-z0-9-]", "", raw.strip().lower().replace(" ", "-"))
if not slug:
    sys.exit("Error: empty name")
title = slug.replace("-", " ").title()

def edit(path, repls, optional=False):
    f = root / path
    if optional and not f.exists():
        return
    text = f.read_text()
    for pat, rep in repls:
        text = re.sub(pat, rep, text, flags=re.M)
    f.write_text(text)
    print(f"  updated {path}")

edit(".env", [
    (r"^APP_NAME=.*$", f"APP_NAME={slug}"),
    (r"^VITE_APP_TITLE=.*$", f"VITE_APP_TITLE={title}"),
])
edit(".env.development", [
    (r"^APP_NAME=.*$", f"APP_NAME={slug}-dev"),
    (r"^VITE_APP_TITLE=.*$", f'VITE_APP_TITLE="{title} (Dev)"'),
])
edit("frontend/package.json", [(r'"name":\s*"[^"]*"', f'"name": "{slug}"')])
edit("frontend/index.html", [(r"<title>.*</title>", f"<title>{title}</title>")],
     optional=True)

print(f"\n  slug:  {slug}\n  title: {title}")
PY

echo ""
echo "Randomizing host ports..."
bash "$DIR/scripts/randomize-ports.sh"

echo ""
echo "Done. Go build something."

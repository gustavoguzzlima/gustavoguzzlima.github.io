#!/usr/bin/env bash
# Gera static/og-image.png (1200x630) a partir de scripts/og-image.html.
# Sem serviço externo: usa o google-chrome headless que já existe na máquina.
# Uso: scripts/gerar-og-image.sh
set -euo pipefail

SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SELF/.." && pwd)"
CHROME="${CHROME:-google-chrome}"
OUT="$ROOT/static/og-image.png"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

"$CHROME" --headless=new --disable-gpu --no-sandbox --hide-scrollbars \
  --force-device-scale-factor=1 --window-size=1200,630 \
  --screenshot="$TMP/og.png" "file://$ROOT/scripts/og-image.html" >/dev/null 2>&1

# O chrome pode devolver a janela inteira; recorta exatamente 1200x630.
python3 - "$TMP/og.png" "$OUT" <<'PY'
import sys
from PIL import Image
src, dst = sys.argv[1], sys.argv[2]
im = Image.open(src).convert("RGB")
if im.size != (1200, 630):
    im = im.crop((0, 0, 1200, 630))
im.save(dst, "PNG", optimize=True)
print(f"{dst}: {im.size[0]}x{im.size[1]}, {__import__('os').path.getsize(dst)} bytes")
PY

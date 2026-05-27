#!/usr/bin/env bash
#
# Bundle the four quote markdown documents into a single PDF using
# Firefox headless. No system-level installs required beyond Firefox
# and the user-installed `markdown` Python library.
#
# Usage: ./scripts/build-quote-pdf.sh
# Output: docs/build/playgrid-club-quotes.pdf

set -euo pipefail

cd "$(dirname "$0")/.."

mkdir -p docs/build

HTML_PATH=$(python3 scripts/build-quote-pdf.py)
PDF_PATH="$(pwd)/docs/build/playgrid-club-quotes.pdf"

echo "[build-pdf] HTML  $HTML_PATH"
echo "[build-pdf] PDF   $PDF_PATH"

# Firefox headless wants an absolute file:// URL.
firefox --headless --print-to-pdf="$PDF_PATH" "file://$HTML_PATH" > /dev/null 2>&1

if [ -f "$PDF_PATH" ]; then
    SIZE=$(du -h "$PDF_PATH" | cut -f1)
    echo "[build-pdf] OK    $SIZE"
else
    echo "[build-pdf] FAIL  no PDF produced" >&2
    exit 1
fi

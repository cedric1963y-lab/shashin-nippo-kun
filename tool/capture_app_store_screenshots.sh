#!/usr/bin/env bash
# Save the booted iOS Simulator as a raw PNG.
# Does not build, crop, frame, or change the app UI.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/store/screenshots/raw"

usage() {
  cat <<'EOF'
Usage: tool/capture_app_store_screenshots.sh <shot>

Shots (live UI only, see store/screenshots/README.md):
  01-site-list
  02-photo-add
  03-pdf-share
  04-paywall

Requires macOS and a booted iOS Simulator already showing that screen.
EOF
}

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "error: this needs macOS and the iOS Simulator. No screenshot was taken." >&2
  exit 1
fi

shot="${1:-}"
case "$shot" in
  01-site-list | 02-photo-add | 03-pdf-share | 04-paywall) ;;
  *)
    usage
    exit 1
    ;;
esac

if ! xcrun simctl list devices booted | grep -q Booted; then
  echo "error: no booted simulator. Open one in Xcode and run the app first." >&2
  exit 1
fi

mkdir -p "$OUT"
dest="$OUT/$shot.png"
xcrun simctl io booted screenshot "$dest"
echo "wrote $dest"
if command -v sips >/dev/null 2>&1; then
  sips -g pixelWidth -g pixelHeight "$dest"
fi
echo "Leave this PNG uncropped and without a device frame."

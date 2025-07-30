#!/usr/bin/env bash
set -euo pipefail

# Resolve repo root (folder containing metadata.json and contents/)
root="$(cd "$(dirname "$0")" && pwd)"

# Read version from metadata.json (jq if available, fallback to grep)
if command -v jq >/dev/null 2>&1; then
  ver="$(jq -r '.KPlugin.Version // .KPlugin["Version"] // empty' "$root/metadata.json")"
else
  ver="$(grep -oE '"Version"\s*:\s*"[^"]+"' "$root/metadata.json" | head -n1 | sed -E 's/.*"Version"\s*:\s*"([^"]+)".*/\1/')"
fi
: "${ver:=0.1.0}"

mkdir -p "$root/dist"
out="$root/dist/org.kde.plasma.bongocat-$ver.plasmoid"

cd "$root"
rm -f "$out"

# Sanity check
if [[ ! -f metadata.json || ! -d contents ]]; then
  echo "ERROR: Run from the plasmoid root (must contain metadata.json and contents/)" >&2
  exit 1
fi

# Create package with correct top-level layout
zip -r -9 "$out" metadata.json contents > /dev/null

echo "Built: $out"

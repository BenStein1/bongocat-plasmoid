#!/usr/bin/env bash
set -euo pipefail

# Resolve repo root (folder containing metadata.json and contents/)
root="$(cd "$(dirname "$0")" && pwd)"

# Read version from metadata.json (jq if available, fallback to grep)
if command -v jq >/dev/null 2>&1; then
  ver="$(jq -r '.KPlugin.Version' "$root/metadata.json" 2>/dev/null)"
  # Double-check with alternative path in case of JSON formatting issues
  [[ -z "$ver" ]] && ver="$(jq -r '.KPlugin["Version"]' "$root/metadata.json" 2>/dev/null)"
else
  ver="$(grep -oE '"Version"\s*:\s*"[^"]+"' "$root/metadata.json" | head -n1 | sed -E 's/.*"Version"\s*:\s*"([^"]+)".*/\1/')"
fi

# Ensure we have a valid version
if [[ -z "$ver" ]]; then
  echo "ERROR: Could not extract version from metadata.json. Check JSON formatting." >&2
  exit 1
fi

mkdir -p "$root/dist"
out="$root/dist/org.kde.plasma.bongocat-$ver.plasmoid"

cd "$root"
# Force overwrite existing package
if [[ -f "$out" ]]; then
  echo "Overwriting existing package: $out"
fi
rm -f "$out"

# Verbose logging
echo "Packaging files:"
ls -la metadata.json contents/

# Sanity check
if [[ ! -f metadata.json || ! -d contents ]]; then
  echo "ERROR: Run from the plasmoid root (must contain metadata.json and contents/)" >&2
  exit 1
fi

# Create package with correct top-level layout (metadata.json at root)
echo "Creating zip package..."
zip -r9 --exclude=*.git* "$out" metadata.json contents > /dev/null

# Verify package creation
if [[ ! -f "$out" ]]; then
  echo "ERROR: Failed to create package file $out" >&2
  exit 1
fi

echo "Built: $out"

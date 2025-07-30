
**pack.sh** (build a `.plasmoid` from your tree)
```bash
#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")" && pwd)"
ver="$(jq -r '.KPlugin.Version' "$root/metadata.json" 2>/dev/null || echo "0.1.0")"
mkdir -p "$root/dist"
out="$root/dist/org.kde.plasma.bongocat-$ver.plasmoid"

# Must have metadata.json + contents/ at archive root
cd "$root"
rm -f "$out"
zip -r "$out" metadata.json contents config 2>/dev/null || zip -r "$out" metadata.json contents
echo "Built: $out"

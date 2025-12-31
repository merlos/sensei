#!/usr/bin/env bash
set -euo pipefail

# Generate iOS app icon PNGs from an SVG source.
# Usage: ./generate_icons.sh [source.svg]
# Defaults to icon.svg in this directory. Requires one of: inkscape, rsvg-convert, or ImageMagick (convert).

SRC=${1:-icon.svg}
OUTDIR="$(cd "$(dirname "$0")" && pwd)"
cd "$OUTDIR"

if [[ ! -f "$SRC" ]]; then
  echo "[icon-gen] Source SVG not found: $SRC" >&2
  exit 1
fi

echo "[icon-gen] Using source: $SRC"

# Pick an available renderer
render() {
  local size="$1"; shift
  local output="$1"; shift
  if command -v inkscape >/dev/null 2>&1; then
    inkscape "$SRC" --export-type=png --export-filename="$output" -w "$size" -h "$size" >/dev/null 2>&1
  elif command -v rsvg-convert >/dev/null 2>&1; then
    rsvg-convert -w "$size" -h "$size" "$SRC" -o "$output"
  elif command -v convert >/dev/null 2>&1; then
    convert -background none -resize "${size}x${size}" "$SRC" "$output"
  else
    echo "[icon-gen] Please install inkscape, rsvg-convert, or ImageMagick (convert)." >&2
    exit 1
  fi
  echo "[icon-gen] Generated ${output} (${size}px)"
}

# Size (px)  Output filename
icons=(
  "40 Icon-20@2x.png"
  "60 Icon-20@3x.png"
  "58 Icon-29@2x.png"
  "87 Icon-29@3x.png"
  "80 Icon-40@2x.png"
  "120 Icon-40@3x.png"
  "120 Icon-60@2x.png"
  "180 Icon-60@3x.png"
  "76 Icon-76.png"
  "152 Icon-76@2x.png"
  "167 Icon-83.5@2x.png"
  "1024 Icon-1024.png"  # App Store marketing icon
)

for entry in "${icons[@]}"; do
  set -- $entry
  size="$1"; shift
  filename="$1"; shift
  render "$size" "$filename"
done

echo "[icon-gen] Done. Place these files in AppIcon.appiconset and update Contents.json if needed."

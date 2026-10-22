#!/usr/bin/env bash
# ============================================================
# Genere les images PNG des schemas d'architecture a partir
# des fichiers Mermaid (.md) de docs/architecture/.
#
# Prerequis (une fois) :
#   npm install -g @mermaid-js/mermaid-cli      # fournit "mmdc"
#
# Usage : bash scripts/render-diagrams.sh        (depuis la racine du depot)
# ============================================================
set -euo pipefail

SRC="docs/architecture"
OUT="docs/architecture/img"
mkdir -p "$OUT"

for f in "$SRC"/*.md; do
  name="$(basename "$f" .md)"
  tmp="$(mktemp --suffix=.mmd)"
  # Extraire le bloc entre ```mermaid et la cloture ```
  awk '/```mermaid/{flag=1;next}/```/{flag=0}flag' "$f" > "$tmp"
  echo "Rendu : $name -> $OUT/$name.png"
  mmdc -i "$tmp" -o "$OUT/$name.png" -b white
  rm -f "$tmp"
done

echo "Termine. Images dans $OUT/"

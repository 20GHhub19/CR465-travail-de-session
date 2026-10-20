#!/usr/bin/env bash
# ============================================================
# Empreinte d'auteur — manifeste vérifiable
#
# Produit :
#   1. la liste horodatée des commits d'un auteur avec leur SHA
#   2. un bundle Git autonome (historique complet, vérifiable hors ligne)
#   3. les empreintes SHA-256 des deux artefacts
#
# Usage : ./scripts/authorship-manifest.sh [pseudo-git] [branche]
#   ./scripts/authorship-manifest.sh fokomaximejoel Projet-CR465-D-Maxime
# ============================================================
set -euo pipefail

AUTHOR="${1:-fokomaximejoel}"
BRANCH="${2:-$(git rev-parse --abbrev-ref HEAD)}"
OUT="authorship"

# shasum existe sur macOS, sha256sum sur Linux
if command -v shasum >/dev/null 2>&1; then
  sha256() { shasum -a 256 "$1" | awk '{print $1}'; }
elif command -v sha256sum >/dev/null 2>&1; then
  sha256() { sha256sum "$1" | awk '{print $1}'; }
else
  echo "ERREUR : ni shasum ni sha256sum disponibles." >&2; exit 1
fi
BUNDLE="$OUT/${AUTHOR}.bundle"
MANIFEST="$OUT/${AUTHOR}-commits.txt"

mkdir -p "$OUT"

# 1) Liste des commits de l'auteur (SHA, date ISO, sujet)
{
  echo "# Empreinte d'auteur — $AUTHOR"
  echo "# Branche : $BRANCH"
  echo "# Généré le : $(date -u '+%Y-%m-%dT%H:%M:%SZ') (UTC)"
  echo "# Format  : <sha> <date> <sujet>"
  echo "#"
  git log "$BRANCH" --author="$AUTHOR" \
      --date=iso-strict --pretty=format:'%H %ad %s'
  echo
} > "$MANIFEST"

# 2) Bundle : contient l'historique complet de la branche
git bundle create "$BUNDLE" "$BRANCH" >/dev/null 2>&1

# 3) Empreintes
COMMITS=$(git log "$BRANCH" --author="$AUTHOR" --oneline | wc -l | tr -d ' ')
FILES=$(git log "$BRANCH" --author="$AUTHOR" --name-only --format="" \
        | sort -u | grep -v '^$' | wc -l | tr -d ' ')
HEAD_SHA=$(git rev-parse "$BRANCH")
TREE_SHA=$(git rev-parse "$BRANCH^{tree}")
MANIFEST_HASH=$(sha256 "$MANIFEST")
BUNDLE_HASH=$(sha256 "$BUNDLE")

cat <<EOF

=== EMPREINTE D'AUTEUR ===
Auteur          : $AUTHOR
Branche         : $BRANCH
Commits         : $COMMITS
Fichiers        : $FILES

HEAD            : $HEAD_SHA
Arbre (tree)    : $TREE_SHA

Manifeste       : $MANIFEST
SHA-256         : $MANIFEST_HASH

Bundle Git      : $BUNDLE ($(du -h "$BUNDLE" | awk '{print $1}'))
SHA-256         : $BUNDLE_HASH

Vérification par un tiers :
  echo "$BUNDLE_HASH  $BUNDLE" | { command -v shasum >/dev/null && shasum -a 256 -c - || sha256sum -c -; }
  git bundle verify $BUNDLE
  git log --author=$AUTHOR --oneline

Toute modification de l'historique change ces empreintes.
Consigner ce bloc hors du dépôt (courriel, GitBook, mémoire) pour
qu'il serve de référence externe.
EOF

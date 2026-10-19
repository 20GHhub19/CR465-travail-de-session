#!/usr/bin/env bash
# ============================================================
# Genere compose/n8n/workflows/commande-moodle.json a partir du modele,
# en injectant le jeton Moodle et l'URL depuis compose/.env.
#
# Pourquoi : un workflow n8n ne doit pas contenir de secret en clair dans
# le depot. Le fichier genere est dans .gitignore.
#
# Usage (depuis la racine du depot) :
#   ./scripts/render-n8n-workflow.sh
# ============================================================
set -euo pipefail

ENV_FILE="${ENV_FILE:-compose/.env}"
TPL="compose/n8n/workflows/commande-moodle.template.json"
OUT="compose/n8n/workflows/commande-moodle.json"

[ -f "$ENV_FILE" ] || { echo "ERREUR : $ENV_FILE introuvable"; exit 1; }
[ -f "$TPL" ]      || { echo "ERREUR : $TPL introuvable (lancer depuis la racine)"; exit 1; }

set -a
# shellcheck disable=SC1090
. "$ENV_FILE"
set +a

: "${MOODLE_WS_TOKEN:?MOODLE_WS_TOKEN manquant (lancer scripts/configure-moodle-webservice.sh)}"
: "${BASE_DOMAIN:?BASE_DOMAIN manquant}"
COURSE_ID="${MOODLE_COURSE_ID:-2}"

sed -e "s|__MOODLE_URL__|https://lms.${BASE_DOMAIN}|g" \
    -e "s|__MOODLE_COURSE_ID__|${COURSE_ID}|g" \
    -e "s|__MOODLE_WS_TOKEN__|${MOODLE_WS_TOKEN}|g" \
    "$TPL" > "$OUT"
chmod 600 "$OUT"

if grep -q "__MOODLE" "$OUT"; then
  echo "ERREUR : placeholders restants dans $OUT" >&2
  exit 1
fi
echo "Workflow genere : $OUT (jeton injecte, fichier non versionne)"

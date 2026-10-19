#!/usr/bin/env bash
# ============================================================
# Genere compose/keycloak/import/realm-cr465.json a partir du modele
# realm-cr465.template.json, en injectant les secrets du fichier .env.
#
# Pourquoi : un realm importe par Keycloak ne sait pas lire les variables
# d'environnement. Le fichier genere contient donc de VRAIS secrets :
# il est dans .gitignore et ne doit jamais etre commite.
#
# Usage (depuis la racine du depot) :
#   ./scripts/render-keycloak-realm.sh
# ============================================================
set -euo pipefail

ENV_FILE="${ENV_FILE:-compose/.env}"
TPL="compose/keycloak/import/realm-cr465.template.json"
OUT="compose/keycloak/import/realm-cr465.json"

[ -f "$ENV_FILE" ] || { echo "ERREUR : $ENV_FILE introuvable. Faire : cp compose/.env.example compose/.env"; exit 1; }
[ -f "$TPL" ]      || { echo "ERREUR : $TPL introuvable (lancer depuis la racine)."; exit 1; }

# charge les variables sans les exporter dans l'environnement du shell appelant
set -a
# shellcheck disable=SC1090
. "$ENV_FILE"
set +a

: "${MOODLE_OIDC_CLIENT_SECRET:?MOODLE_OIDC_CLIENT_SECRET manquant dans $ENV_FILE}"
: "${DRUPAL_OIDC_CLIENT_SECRET:?DRUPAL_OIDC_CLIENT_SECRET manquant dans $ENV_FILE}"

sed -e "s|__MOODLE_OIDC_CLIENT_SECRET__|${MOODLE_OIDC_CLIENT_SECRET}|g" \
    -e "s|__DRUPAL_OIDC_CLIENT_SECRET__|${DRUPAL_OIDC_CLIENT_SECRET}|g" \
    "$TPL" > "$OUT"
chmod 600 "$OUT"

if grep -q "__.*_SECRET__" "$OUT"; then
  echo "ERREUR : des placeholders subsistent dans $OUT" >&2
  exit 1
fi

echo "Realm genere : $OUT (secrets injectes, fichier non versionne)"

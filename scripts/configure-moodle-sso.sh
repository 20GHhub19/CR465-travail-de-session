#!/usr/bin/env bash
# ============================================================
# Branche le SSO Keycloak dans Moodle (plugin core auth_oauth2).
#
# Prerequis : la stack tourne, le realm Keycloak est importe et le client
# "moodle" existe (voir scripts/render-keycloak-realm.sh).
#
# Usage (depuis la racine du depot) :
#   ./scripts/configure-moodle-sso.sh [nom_conteneur_moodle]
# ============================================================
set -euo pipefail

ENV_FILE="${ENV_FILE:-compose/.env}"
CONTAINER="${1:-cr465-moodle}"
SCRIPT_LOCAL="compose/moodle/sso/configure-oidc.php"

[ -f "$ENV_FILE" ]        || { echo "ERREUR : $ENV_FILE introuvable"; exit 1; }
[ -f "$SCRIPT_LOCAL" ]    || { echo "ERREUR : $SCRIPT_LOCAL introuvable (lancer depuis la racine)"; exit 1; }

set -a
# shellcheck disable=SC1090
. "$ENV_FILE"
set +a

: "${BASE_DOMAIN:?BASE_DOMAIN manquant}"
: "${MOODLE_OIDC_CLIENT_SECRET:?MOODLE_OIDC_CLIENT_SECRET manquant}"

ISSUER_URL="https://auth.${BASE_DOMAIN}/realms/cr465"
INTERNAL_URL="http://keycloak:8080/realms/cr465"
CLIENT_ID="moodle"

echo "Conteneur : $CONTAINER"
echo "Issuer    : $ISSUER_URL"
echo "Client ID : $CLIENT_ID"
echo "Interne   : $INTERNAL_URL"

# copie du script dans le conteneur
docker cp "$SCRIPT_LOCAL" "${CONTAINER}:/tmp/configure-oidc.php"

# execution avec l'utilisateur du serveur web (l'image alpine-moodle tourne en nobody)
APP_USER="$(docker exec "$CONTAINER" sh -c 'id -un 2>/dev/null || echo nobody' | tr -d "\r")"
APP_USER="${APP_USER:-nobody}"
echo "Utilisateur applicatif : $APP_USER"

docker exec -u "$APP_USER" \
  -e SSO_ISSUER_NAME="Keycloak" \
  -e SSO_ISSUER_URL="$ISSUER_URL" \
  -e SSO_INTERNAL_URL="$INTERNAL_URL" \
  -e SSO_CLIENT_ID="$CLIENT_ID" \
  -e SSO_CLIENT_SECRET="$MOODLE_OIDC_CLIENT_SECRET" \
  "$CONTAINER" php /tmp/configure-oidc.php

# purge des caches Moodle pour que le bouton apparaisse
docker exec -u "$APP_USER" "$CONTAINER" php /var/www/html/admin/cli/purge_caches.php >/dev/null
echo "Caches Moodle purges."
echo "SSO Moodle branche : bouton 'Keycloak' attendu sur la page de connexion."

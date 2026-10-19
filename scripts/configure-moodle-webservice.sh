#!/usr/bin/env bash
# ============================================================
# Prepare l'API web Moodle pour n8n et enregistre le jeton dans .env
#
# - active les services web (REST)
# - cree le service "cr465" avec 6 fonctions
# - cree un compte de service "svc-n8n" a role limite (pas administrateur)
# - cree le cours de demonstration s'il n'existe pas
# - ecrit MOODLE_WS_TOKEN dans compose/.env
#
# Usage (depuis la racine du depot) :
#   ./scripts/configure-moodle-webservice.sh [conteneur]
# ============================================================
set -euo pipefail

ENV_FILE="${ENV_FILE:-compose/.env}"
CONTAINER="${1:-cr465-moodle}"

[ -f "$ENV_FILE" ] || { echo "ERREUR : $ENV_FILE introuvable"; exit 1; }

APP_USER="$(docker exec "$CONTAINER" sh -c 'id -un' | tr -d '\r')"
APP_USER="${APP_USER:-nobody}"

echo "Conteneur : $CONTAINER (utilisateur $APP_USER)"

docker cp compose/moodle/webservice/configure-webservice.php "${CONTAINER}:/tmp/configure-webservice.php"
OUT="$(docker exec -u "$APP_USER" "$CONTAINER" php /tmp/configure-webservice.php)"
echo "$OUT"

TOKEN="$(echo "$OUT" | sed -n 's/^TOKEN=//p' | tail -1)"
[ -n "$TOKEN" ] || { echo "ERREUR : jeton non recupere" >&2; exit 1; }

# cours de demonstration
docker cp compose/moodle/webservice/seed-course.php "${CONTAINER}:/tmp/seed-course.php"
docker exec -u "$APP_USER" "$CONTAINER" php /tmp/seed-course.php

# mise a jour de .env (sans dupliquer la cle)
if grep -q '^MOODLE_WS_TOKEN=' "$ENV_FILE"; then
  tmp="$(mktemp)"
  sed "s|^MOODLE_WS_TOKEN=.*|MOODLE_WS_TOKEN=${TOKEN}|" "$ENV_FILE" > "$tmp"
  mv "$tmp" "$ENV_FILE"
else
  printf '\n# Jeton du service web Moodle (genere par scripts/configure-moodle-webservice.sh)\nMOODLE_WS_TOKEN=%s\n' "$TOKEN" >> "$ENV_FILE"
fi
chmod 600 "$ENV_FILE"

echo "Jeton enregistre dans $ENV_FILE (jamais versionne)."

docker exec -u "$APP_USER" "$CONTAINER" php /var/www/html/admin/cli/purge_caches.php >/dev/null
echo "Caches Moodle purges."

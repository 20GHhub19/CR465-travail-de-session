#!/usr/bin/env bash
# ============================================================
# Scan local des images Docker de la stack (Trivy, hors-ligne / local)
# Aucune dependance a un service cloud : Trivy tourne en conteneur local.
#
# Usage (depuis la racine du depot) :
#   ./scripts/scan-images.sh                 # scan de toutes les images du compose
#   ./scripts/scan-images.sh traefik:v3.3.7  # scan d'une image precise
#
# Sortie : rapports texte dans docs/security/scans/
# ============================================================
set -euo pipefail

COMPOSE_FILE="${COMPOSE_FILE:-compose/docker-compose.yml}"
ENV_FILE="${ENV_FILE:-compose/.env}"
OUT_DIR="docs/security/scans"
TRIVY_IMAGE="aquasec/trivy:0.76.0"
SEVERITY="HIGH,CRITICAL"

command -v docker >/dev/null 2>&1 || { echo "ERREUR : docker introuvable."; exit 1; }

# --- Collecte des images ------------------------------------------------
if [ "$#" -gt 0 ]; then
  IMAGES=("$@")
else
  [ -f "$COMPOSE_FILE" ] || { echo "ERREUR : $COMPOSE_FILE introuvable (lancer depuis la racine)."; exit 1; }
  ENV_ARG=""
  [ -f "$ENV_FILE" ] && ENV_ARG="--env-file $ENV_FILE"
  # shellcheck disable=SC2207,SC2086
  IMAGES=($(docker compose $ENV_ARG -f "$COMPOSE_FILE" config --images | sort -u))
fi

[ "${#IMAGES[@]}" -gt 0 ] || { echo "ERREUR : aucune image a scanner."; exit 1; }

mkdir -p "$OUT_DIR"
echo "Images a scanner : ${#IMAGES[@]}"
printf '  - %s\n' "${IMAGES[@]}"
echo

STATUS=0
for IMG in "${IMAGES[@]}"; do
  SAFE_NAME="$(echo "$IMG" | tr '/:@' '___')"
  REPORT="$OUT_DIR/${SAFE_NAME}.txt"
  echo ">> Scan de $IMG"
  docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$PWD/$OUT_DIR:/out" \
    "$TRIVY_IMAGE" image \
      --scanners vuln \
      --severity "$SEVERITY" \
      --no-progress \
      --format table \
      --output "/out/${SAFE_NAME}.txt" \
      "$IMG" || STATUS=1
  echo "   rapport : $REPORT"
done

echo
echo "Termine. Rapports dans $OUT_DIR/"
echo "Rappel : un rapport genere doit etre relu avant remise (severites HIGH/CRITICAL)."
exit "$STATUS"

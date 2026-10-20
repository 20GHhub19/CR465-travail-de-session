#!/usr/bin/env bash
# ============================================================
# Preparation d'une demonstration
#
# Demarre la stack, attend que les services soient sains,
# puis affiche les URLs et les preuves a montrer a l'ecran.
# A lancer juste avant d'enregistrer la video.
#
# Usage : bash scripts/demo-prep.sh
# ============================================================
set -uo pipefail

COMPOSE_DIR="compose"
COMPOSE_FILE="$COMPOSE_DIR/docker-compose.yml"
ENV_FILE="$COMPOSE_DIR/.env"
# Nom de projet compose = prefixe des volumes. Le changer cree de NOUVEAUX volumes
# (Moodle se reinstalle, la base est vide). Garder "cr465test" pour retrouver les
# donnees de demonstration deja en place.
PROJECT="${CR465_PROJECT:-cr465test}"
DOMAIN="${BASE_DOMAIN:-cr465.test}"

echo "============================================================"
echo " Preparation de la demonstration"
echo "============================================================"

# --- Verifications ---
[ -f "$COMPOSE_FILE" ] || { echo "ERREUR : $COMPOSE_FILE introuvable (lancez depuis la racine)."; exit 1; }
[ -f "$ENV_FILE" ]     || { echo "ERREUR : $ENV_FILE absent. Copiez compose/.env.example vers compose/.env."; exit 1; }
command -v docker >/dev/null || { echo "ERREUR : docker introuvable."; exit 1; }
docker info >/dev/null 2>&1 || { echo "ERREUR : le demon Docker ne repond pas (Docker Desktop lance ?)."; exit 1; }

if ! docker volume ls --format '{{.Name}}' | grep -q "^${PROJECT}_postgres_data$"; then
  echo
  echo "!! Premier demarrage pour le projet '$PROJECT' : les volumes sont vides."
  echo "   Moodle doit s'installer (plusieurs minutes) et les comptes de demo sont absents."
  echo "   Pour retrouver un environnement deja initialise, utilisez le projet existant :"
  echo "       CR465_PROJECT=cr465test bash scripts/demo-prep.sh"
  echo
fi

echo "Compose  : $COMPOSE_FILE"
echo "Secrets  : $ENV_FILE (non versionne)"
echo

# --- Demarrage ---
echo ">> Demarrage de la stack…"
docker compose -p "$PROJECT" --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d
if [ $? -ne 0 ]; then
  echo "ERREUR : le demarrage a echoue. Voir : docker compose -p $PROJECT logs"
  exit 1
fi

# --- Attente de sante (max 180 s) ---
echo
echo ">> Attente de la sante des services (max 180 s)…"
for i in $(seq 1 36); do
  total=$(docker compose -p "$PROJECT" --env-file "$ENV_FILE" -f "$COMPOSE_FILE" ps -q | wc -l | tr -d ' ')
  healthy=$(docker compose -p "$PROJECT" --env-file "$ENV_FILE" -f "$COMPOSE_FILE" ps --format '{{.Health}}' 2>/dev/null | grep -c '^healthy$')
  printf '   %3ds : %s conteneurs, %s sains\n' "$((i*5))" "$total" "$healthy"
  if [ "$healthy" -ge 7 ]; then break; fi
  sleep 5
done

echo
echo "============================================================"
echo " Etat des conteneurs"
echo "============================================================"
docker compose -p "$PROJECT" --env-file "$ENV_FILE" -f "$COMPOSE_FILE" ps --format 'table {{.Name}}\t{{.Status}}'

# --- Verification des domaines ---
echo
echo "============================================================"
echo " Reponses HTTP (attendu : 200 ou 3xx)"
echo "============================================================"
for h in shop lms auth flow admin; do
  code=$(curl -k -s -o /dev/null -w '%{http_code}' --max-time 15 \
         --resolve "$h.$DOMAIN:443:127.0.0.1" "https://$h.$DOMAIN/" 2>/dev/null)
  printf '  %-22s %s\n' "$h.$DOMAIN" "${code:-timeout}"
done

echo
echo "============================================================"
echo " Ce qu'il faut montrer a l'ecran"
echo "============================================================"
cat <<EOF
  Boutique     : https://shop.$DOMAIN/
  Moodle       : https://lms.$DOMAIN/
  Keycloak     : https://auth.$DOMAIN/admin/
  n8n          : https://flow.$DOMAIN/
  Portainer    : https://admin.$DOMAIN/

  Preuve d'inscription Moodle :
    docker exec cr465-postgres psql -U pgadmin -d moodle -c \\
      "SELECT u.email, c.shortname FROM mdl_user_enrolments ue
       JOIN mdl_enrol e ON e.id=ue.enrolid
       JOIN mdl_user u ON u.id=ue.userid
       JOIN mdl_course c ON c.id=e.courseid ORDER BY ue.id DESC LIMIT 3;"

  Preuve de durcissement :
    docker inspect cr465-traefik --format 'user={{.Config.User}} caps={{.HostConfig.CapDrop}} ro={{.HostConfig.ReadonlyRootfs}}'

  Journal du webhook :
    docker logs cr465-drupal --tail 5 | grep cr465_notify
EOF
echo
echo "PRET. Vous pouvez enregistrer."
echo "Arret : docker compose -p $PROJECT --env-file $ENV_FILE -f $COMPOSE_FILE down"

#!/bin/bash
# ============================================================
# Initialisation PostgreSQL : une base + un utilisateur par service.
# Execute UNE SEULE FOIS, a la creation du volume postgres_data.
# Principe du moindre privilege : chaque service ne peut se connecter
# qu'a SA base, avec SON utilisateur.
# ============================================================
set -euo pipefail

create_db() {
  local db="$1" user="$2" pass="$3"
  if [ -z "$pass" ]; then
    echo "ERREUR : mot de passe manquant pour la base ${db}" >&2
    exit 1
  fi
  echo "CR465 : creation de la base ${db} (proprietaire ${user})"
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres \
       -v db="$db" -v usr="$user" -v pass="$pass" <<'EOSQL'
CREATE ROLE :"usr" LOGIN PASSWORD :'pass';
CREATE DATABASE :"db" OWNER :"usr" ENCODING 'UTF8';
REVOKE ALL ON DATABASE :"db" FROM PUBLIC;
EOSQL
}

create_db drupal   drupal   "${DRUPAL_DB_PASSWORD:-}"
create_db moodle   moodle   "${MOODLE_DB_PASSWORD:-}"
create_db keycloak keycloak "${KEYCLOAK_DB_PASSWORD:-${KC_DB_PASSWORD:-}}"
create_db n8n      n8n      "${N8N_DB_PASSWORD:-}"

echo "CR465 : bases initialisees (drupal, moodle, keycloak, n8n)"

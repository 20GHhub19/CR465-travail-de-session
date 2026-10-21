#!/usr/bin/env bash
# ============================================================
# Installe et configure Drupal Commerce (boutique CR465)
#
# Idempotent : si Drupal est deja installe, ne reinstalle pas ;
# les entites (boutique, produit, passerelle) sont creees si absentes.
#
# Usage (depuis la racine du depot) :
#   ./scripts/configure-drupal.sh [conteneur]
# ============================================================
set -euo pipefail

ENV_FILE="${ENV_FILE:-compose/.env}"
CONTAINER="${1:-cr465-drupal}"
DRUSH="vendor/bin/drush"

[ -f "$ENV_FILE" ] || { echo "ERREUR : $ENV_FILE introuvable"; exit 1; }

set -a
# shellcheck disable=SC1090
. "$ENV_FILE"
set +a

: "${DRUPAL_DB_PASSWORD:?DRUPAL_DB_PASSWORD manquant}"
: "${DRUPAL_ADMIN_PASSWORD:?DRUPAL_ADMIN_PASSWORD manquant}"
: "${BASE_DOMAIN:?BASE_DOMAIN manquant}"

DB_URL="pgsql://${DRUPAL_DB_USER}:${DRUPAL_DB_PASSWORD}@postgres:5432/${DRUPAL_DB_NAME}"

echo "Conteneur : $CONTAINER"

# --- 1. Installation du site si necessaire --------------------------
INSTALLED="$(docker exec -w /opt/drupal "$CONTAINER" "$DRUSH" status --field=bootstrap 2>/dev/null || echo "")"
if [ "$INSTALLED" = "Successful" ]; then
  echo "Drupal deja installe."
else
  echo ">> Installation de Drupal"
  docker exec -w /opt/drupal "$CONTAINER" "$DRUSH" site:install standard \
    --db-url="$DB_URL" \
    --account-name="${DRUPAL_ADMIN_USER:-admin}" \
    --account-pass="$DRUPAL_ADMIN_PASSWORD" \
    --site-name="CR465 Formation" \
    --site-mail="admin@${BASE_DOMAIN}" -y
fi

# --- 2. Modules -----------------------------------------------------
echo ">> Activation des modules Commerce"
docker exec -w /opt/drupal "$CONTAINER" "$DRUSH" en -y \
  commerce commerce_store commerce_price commerce_product commerce_cart \
  commerce_checkout commerce_payment commerce_payment_example cr465_notify >/dev/null

# --- 3. Boutique par defaut -----------------------------------------
echo ">> Boutique"
docker exec -w /opt/drupal "$CONTAINER" "$DRUSH" php:eval '
if (!\Drupal::entityTypeManager()->getStorage("commerce_store")->loadMultiple()) {
  $s = \Drupal\commerce_store\Entity\Store::create([
    "type" => "online",
    "name" => "CR465 Boutique",
    "mail" => "admin@cr465.test",
    "address" => ["country_code"=>"CA","address_line1"=>"1 rue Test","locality"=>"Montreal","administrative_area"=>"QC","postal_code"=>"H0H0H0"],
    "default_currency" => ["entity" => \Drupal::entityTypeManager()->getStorage("commerce_currency")->load("USD")],
    "billing_countries" => ["CA"],
  ]);
  $s->save();
  echo "boutique creee\n";
} else { echo "boutique deja presente\n"; }'

# --- 4. Produit et passerelle de paiement ---------------------------
echo ">> Produit et paiement simule"
docker exec -w /opt/drupal "$CONTAINER" "$DRUSH" php:script scripts/configure-commerce.php

# --- 5. Webhook n8n --------------------------------------------------
echo ">> Webhook n8n"
docker exec -w /opt/drupal "$CONTAINER" "$DRUSH" config:set cr465_notify.settings \
  webhook_url "https://flow.${BASE_DOMAIN}/webhook/commande" -y >/dev/null

# Secret HMAC : n8n rejette toute requete non signee (401)
if [ -n "${DRUPAL_WEBHOOK_SECRET:-}" ]; then
  docker exec -w /opt/drupal "$CONTAINER" "$DRUSH" config:set cr465_notify.settings \
    webhook_secret "${DRUPAL_WEBHOOK_SECRET}" -y >/dev/null
  echo "   secret HMAC configure"
fi

docker exec -w /opt/drupal "$CONTAINER" "$DRUSH" cr >/dev/null
echo "Drupal Commerce configure."
echo "Boutique : https://shop.${BASE_DOMAIN}/"

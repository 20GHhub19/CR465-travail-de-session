#!/bin/sh
# ============================================================
# Entrypoint CR465 pour le conteneur Drupal
#
# Le dossier sites/default est un volume persistant : sans settings.php,
# Drupal ne demarre pas. On le (re)cree depuis le modele bake dans l'image
# au premier demarrage, puis on laisse l'entrypoint officiel faire son travail.
# ============================================================
set -e

SETTINGS="/opt/drupal/web/sites/default/settings.php"
TEMPLATE="/opt/drupal/default.settings.php"

if [ ! -f "$SETTINGS" ]; then
  echo "[cr465] Creation de settings.php depuis le modele"
  cp "$TEMPLATE" "$SETTINGS"
  chmod 666 "$SETTINGS"
fi

# Le dossier files doit exister et appartenir a www-data
mkdir -p /opt/drupal/web/sites/default/files
chown -R www-data:www-data /opt/drupal/web/sites/default/files 2>/dev/null || true

exec docker-php-entrypoint apache2-foreground

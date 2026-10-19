# ============================================================
# Image Drupal Commerce pour CR465
#
# Base epinglee : drupal:10.6.19-php8.4-apache
#
# Ajouts par rapport a l'image officielle :
#   - extension bcmath (calculs de prix Commerce), intl
#   - drush (administration en ligne de commande)
#   - module drupal/commerce et ses dependances, bakes dans l'image
#     => aucun telechargement au demarrage, deploiement reproductible
# ============================================================
FROM drupal:10.6.19-php8.4-apache

# --- Extensions PHP requises par Drupal Commerce -------------------
RUN apt-get update \
 && apt-get install -y --no-install-recommends libicu-dev libzip-dev \
 && docker-php-ext-install bcmath intl \
 && rm -rf /var/lib/apt/lists/*

# --- Drush + Drupal Commerce (bakes dans l'image) ------------------
RUN composer require --no-interaction --no-progress \
      drush/drush:^13 \
      drupal/commerce:^3 \
 && composer clear-cache

# --- Modele de settings.php conserve hors du volume persistant -------
# (le volume sites/default masque le fichier d'origine)
RUN cp /opt/drupal/web/sites/default/default.settings.php /opt/drupal/default.settings.php

# --- Entrypoint : cree settings.php au premier demarrage -------------
COPY entrypoint.sh /usr/local/bin/cr465-entrypoint.sh
RUN chmod +x /usr/local/bin/cr465-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/cr465-entrypoint.sh"]

# --- Scripts de configuration (drush php:script) --------------------
COPY scripts/ /opt/drupal/scripts/

# --- Module custom CR465 (notification n8n) -------------------------
COPY modules/ /opt/drupal/web/modules/custom/

# --- Droits sur les repertoires ecrits par Drupal -------------------
RUN mkdir -p /opt/drupal/web/sites/default/files \
 && chown -R www-data:www-data /opt/drupal/web/sites/default/files /opt/drupal/web/modules

# Verification au build
RUN php -m | grep -E '^(bcmath|intl)$'

# Déploiement Docker Compose

## Ordre des opérations

```bash
./scripts/launch-vm.sh                 # 1. VM as Code
cp compose/.env.example compose/.env   # 2. secrets locaux
./scripts/gen-certs.sh                 # 3. AC locale + certificat *.cr465.test
./scripts/render-keycloak-realm.sh     # 4. realm avec secrets
docker compose -f compose/docker-compose.yml up -d
./scripts/configure-moodle-sso.sh      # 5. SSO Moodle
./scripts/configure-moodle-webservice.sh  # 6. API + jeton pour n8n
./scripts/configure-drupal.sh          # 7. boutique Commerce
./scripts/scan-images.sh               # 8. scan des images
```

## Fichiers

| Fichier | Contenu |
|---|---|
| `compose/docker-compose.yml` | 9 services, 5 réseaux, volumes, durcissement |
| `compose/.env.example` | modèle de configuration, **aucun secret** |
| `compose/drupal/Dockerfile` | image Drupal dérivée (bcmath, intl, drush, Commerce) |
| `compose/n8n/workflows/*.template.json` | workflow d'attribution d'accès |
| `compose/keycloak/import/*.template.json` | realm `cr465` |

## Gestion des secrets

Aucun secret n'est versionné. Trois mécanismes :

| Secret | Mécanisme |
|---|---|
| Mots de passe (BD, admin) | `compose/.env`, ignoré par Git |
| Secret des clients OIDC | injecté dans le realm par `render-keycloak-realm.sh` (fichier généré, ignoré) |
| Jeton de service Moodle | généré localement, injecté dans le workflow n8n par `render-n8n-workflow.sh` (fichier généré, ignoré) |

Un `.gitignore` vérifie aussi `*.key`, `*.pem`, `*.crt`, `secrets/`.

## Dépendances entre services

- `keycloak`, `moodle`, `n8n`, `drupal` attendent `postgres` **sain** (`condition: service_healthy`).
- `traefik` attend `socket-proxy`.
- Tous les services ont un **healthcheck** (sauf `whoami`, image `scratch` sans binaire interne).

## Volumes persistants

`postgres_data` · `keycloak_data` · `moodle_data` · `moodle_html` · `n8n_data` ·
`drupal_settings` · `drupal_files` · `portainer_data`

## Reproductibilité

- Images épinglées (aucun `latest`).
- Commerce et les modules Drupal sont **bakés dans l'image** : aucun téléchargement au démarrage.
- Les fichiers générés (realm, workflow) le sont par script, à partir du `.env`.

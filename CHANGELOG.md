# Journal des modifications

> Ce fichier documente **toutes** les modifications apportées au dépôt, sprint par sprint,
> avec la justification et la preuve de vérification. Objectif : que chaque membre puisse
> comprendre et défendre n'importe quel changement.

---

## Sprint D — Moodle, Portainer et sortie contrôlée (19 octobre 2026)

### Ajouts

| Élément | Détail |
|---|---|
| Service `moodle` | `erseco/alpine-moodle:v5.3.0`, installation automatique au premier démarrage (499 tables créées), nginx + php-fpm, port interne 8080 |
| Service `portainer` | `portainer/portainer-ce:2.45.2`, connecté à `socket-proxy-admin`, accès via `admin.<domaine>` restreint par allowlist IP |
| Service `socket-proxy-admin` | API Docker en lecture **et écriture**, réservé à Portainer, réseau `socket` |
| Réseau `egress` | Sortie Internet contrôlée, rattachée uniquement à Moodle (dépendances) et n8n (webhooks) |
| Volume `portainer_data` | Persistance de la configuration Portainer |
| Volumes `moodle_data`, `moodle_html` | Persistance des données et du code Moodle |

### Modifications

- `compose/docker-compose.yml` : noms de réseaux explicites (`cr465_edge`, `cr465_app`, `cr465_data`, `cr465_socket`, `cr465_egress`) pour un routage déterministe.
- `.env.example` : ajout de `ADMIN_ALLOWLIST` (IP autorisées sur les interfaces d'administration).
- Schémas 01, 02 et 05 : Moodle et Portainer passés en « déployé », réseau `egress` représenté.

### Justification

- **Portainer exige l'écriture sur l'API Docker** : il ne peut pas fonctionner avec un proxy en lecture seule. D'où une seconde instance `socket-proxy-admin`, isolée et réservée à lui.
- **Réseau `egress`** : Moodle télécharge ses dépendances Composer à l'installation ; sans sortie, l'installation échoue (`Could not resolve host: api.github.com`). L'exception est limitée à deux services et documentée.
- **Noms de réseaux explicites** : un conteneur multi-réseaux (Moodle en a trois) doit indiquer à Traefik lequel utiliser, sinon le routeur n'est pas créé.
- **Moodle sur port 8080** : l'image expose nginx sur 8080, pas 80 ; le label Traefik et le healthcheck ont été alignés.

### Vérifications effectuées

| Test | Résultat |
|---|---|
| Tous les conteneurs | `postgres (healthy)`, `keycloak (healthy)`, `moodle (healthy)`, `traefik (healthy)`, `portainer Up` |
| `https://lms.cr465.test` | **303** → page de connexion Moodle (interface en français) |
| `https://admin.cr465.test` | **307** (redirection Portainer, UI servie) |
| `https://auth.cr465.test/realms/cr465/...` | **302** (flux OIDC) |
| `https://whoami.cr465.test` | **200** |
| Installation Moodle | 499 tables créées dans la base `moodle` |

### Incidents rencontrés et corrigés

1. `MOODLE_SITENAME` avec espaces → l'image passe la valeur en argument CLI, échec `Options non reconnues`. Corrigé en `CR465-Formation`.
2. Moodle en échec d'installation sans Internet (réseaux `internal`) → création du réseau `egress`.
3. Routeur Traefik absent pour Moodle → conteneur multi-réseaux : ajout de `traefik.docker.network`.
4. Healthcheck Moodle en échec (303 interprété comme erreur) → test HTTP acceptant 2xx et 3xx.

### Reste à faire (Sprint E)

- Drupal Commerce (boutique, paiement simulé).
- n8n (workflow webhook → API Moodle).
- Module OIDC côté Moodle (brancher le client `moodle` déjà créé dans Keycloak).
- Suppression de `whoami`, GitBook, vidéo, document de synthèse.

---

## Sprint C — Socle de données et identité (19 octobre 2026)

### Ajouts

| Élément | Détail |
|---|---|
| `compose/postgres/init/01-create-databases.sh` | Création automatique de 4 bases + 4 utilisateurs dédiés (drupal, moodle, keycloak, n8n) au premier démarrage |
| Service `postgres` | `postgres:17.11-alpine`, `read_only`, `cap_drop: ALL` + 5 capacités ciblées, limites 1 CPU / 1 Go, healthcheck `pg_isready`, réseau `data` uniquement |
| Service `keycloak` | `quay.io/keycloak/keycloak:26.8.1`, `start --import-realm`, healthcheck `/health/ready`, dépend de PostgreSQL sain, réseaux `app` + `data` |
| `compose/keycloak/import/realm-cr465.template.json` | Realm `cr465` : rôles `etudiant`/`enseignant`, clients OIDC `moodle` et `drupal` (PKCE S256), politique de mot de passe, anti-bruteforce |
| `scripts/render-keycloak-realm.sh` | Injecte les secrets du `.env` dans le realm ; échoue si un placeholder subsiste |
| `docs/operations/deploiement.md` | Ordre de déploiement, rôle du rendu de realm, procédure de réinitialisation |
| `CHANGELOG.md` | Ce journal |

### Modifications

- `compose/docker-compose.yml` : ajout des volumes `postgres_data` et `keycloak_data`, des services `postgres` et `keycloak`, des labels Traefik pour `auth.<domaine>`.
- `compose/.env.example` : `POSTGRES_USER`/`POSTGRES_PASSWORD` (remplace `POSTGRES_SUPERPASS`), ajout de `MOODLE_OIDC_CLIENT_SECRET` et `DRUPAL_OIDC_CLIENT_SECRET`.
- `.gitignore` : le realm généré `compose/keycloak/import/realm-cr465.json` n'est **jamais** versionné (il contient des secrets).
- `scripts/deploy-stack.sh` : rend le realm avant chaque déploiement.
- Schémas 01 et 05 : PostgreSQL et Keycloak passent de « cible » à « déployé ».

### Justification

- **Une base + un utilisateur par service** : sans cela, une compromission de Moodle donnerait accès aux données de Drupal ou de Keycloak.
- **Realm généré, jamais committé** : l'énoncé pénalise les secrets dans Git (−3 images, −2 livrables). Un realm avec secret en clair serait exactement ce cas.
- **Keycloak sans `read_only`** : écart assumé — l'image reconstruit sa configuration Quarkus au premier démarrage. Documenté dans `docs/security/02-durcissement-execution.md`.
- **Clients `moodle` + `drupal`** : le premier est le minimum exigé par la grille (SSO Moodle) ; le second prépare la bonification SSO côté boutique.

### Vérifications effectuées

| Test | Résultat |
|---|---|
| Initialisation PostgreSQL | `CR465 : bases initialisees (drupal, moodle, keycloak, n8n)` |
| Rôles créés | `drupal`, `moodle`, `keycloak`, `n8n` présents dans `pg_roles` |
| Santé des conteneurs | `cr465-postgres (healthy)`, `cr465-keycloak (healthy)` |
| Découverte OIDC via Traefik | `issuer: https://auth.cr465.test/realms/cr465` ✅ |
| Import du realm | clients `moodle` et `drupal` listés via `kcadm` ✅ |
| Injection du secret | secret du client `moodle` identique à `MOODLE_OIDC_CLIENT_SECRET` ✅ |
| Démarrage du flux OIDC | `GET /protocol/openid-connect/auth?...` → **302** (redirection vers la page de connexion) ✅ |

### Reste à faire (Sprint D)

- Drupal Commerce, Moodle, n8n, Portainer.
- Module OIDC côté Moodle (configuration de l'application, pas seulement du realm).
- Suppression du service de test `whoami` avant la remise (15 CVE HIGH, image de test).

---

## Sprint B — Durcissement de la stack (19 octobre 2026)

### Ajouts

| Élément | Détail |
|---|---|
| `scripts/scan-images.sh` | Scan Trivy local (aucun service cloud), rapports HIGH/CRITICAL dans `docs/security/scans/` |
| `docs/security/01-securite-images.md` | Choix et épinglage des images, procédure de scan, lecture des rapports |
| `docs/security/02-durcissement-execution.md` | Matrice des contrôles, traitement du socket Docker, risques résiduels |
| `docs/security/03-rapport-scan.md` | Résultats réels du scan |
| `docs/operations/incident-api-docker.md` | Diagnostic de l'incompatibilité Traefik / API Docker |

### Modifications

- `compose/docker-compose.yml` : `cap_drop: ALL`, `no-new-privileges`, `read_only` + `tmpfs`, utilisateurs non-root, `cap_add` ciblés, limites CPU/mémoire, healthcheck Traefik, logs bornés, `accessLog` JSON.
- **Socket Docker** : montage direct supprimé, remplacé par `docker-socket-proxy` (`POST: 0`) sur un réseau `socket` dédié.
- Réseau `app` passé en `internal: true`.
- Images épinglées : `traefik:v3.7.15`, `whoami:v1.12.0`, `socket-proxy:v0.5.0`.
- Scripts rendus exécutables.

### Justification

- `:ro` sur un socket Unix **n'empêche pas** les écritures via l'API HTTP : le proxy filtrant est la seule vraie protection.
- `cap_drop: ALL` + `cap_add` ciblé : seule la capacité réellement nécessaire est accordée (`NET_BIND_SERVICE` pour Traefik).
- `app` interne : un conteneur compromis ne peut plus exfiltrer de données vers Internet.
- Images épinglées : un `latest` implicite rend le déploiement non reproductible.

### Vérifications effectuées

| Test | Résultat |
|---|---|
| `docker compose config` | valide |
| Traefik | `Up (healthy)` |
| Routage HTTPS | `https://whoami.cr465.test` → 200, TLS 1.3 |
| Redirection HTTP → HTTPS | 301 |
| Scan Trivy | `traefik:v3.7.15` : **0 HIGH / 0 CRITICAL** · `whoami` : 15 HIGH · `socket-proxy` : 6 HIGH |

### Incident résolu

Traefik v3.3 négocie l'API Docker 1.24, refusée depuis Docker 25 (minimum 1.40) : le proxy
répondait 404 bien qu'en bonne santé. Résolu par `traefik:v3.7.15` (API 1.44). Détail :
`docs/operations/incident-api-docker.md`.

---

## Sprint A — Cohérence du dépôt (19 octobre 2026)

### Modifications

| Fichier | Changement |
|---|---|
| `.gitignore` | Commande shell `docker run … gitleaks` retirée du fichier ; ajout `*.log`, `*.iso`, `*.crt`, `*.p12`, `acme.json`, `.idea/`, `.vscode/` |
| `compose/.env.example` | Domaine unifié `cr465.test` ; commentaires sortis des valeurs (un commentaire en fin de ligne peut être avalé dans la valeur) |
| `compose/docker-compose.yml` | `whoami.cr465.lan` → `whoami.cr465.test` |
| `scripts/test-routing.sh` | Hôte de test aligné |
| `docs/architecture/01` à `05` | Réécriture des 5 schémas : zones de confiance, flux interdits, webhook signé, SSO OIDC, 7 couches ; bandeau d'état honnête (déployé vs cible) |
| `docs/architecture/README.md` | Guide de lecture des 5 schémas |
| `docs/architecture/img/*.png` | Rendus PNG des schémas |
| `md/Contributions.md` | Relevé Git réel + répartition des verticales (à compléter par chaque membre) |

### Justification

- Trois conventions de domaine coexistaient (`exemple.lan`, `example.lan`, `cr465.lan`) : le schéma ne pouvait pas être « conforme au réel ».
- Les docs affirmaient « conformes au déploiement réel » alors que 6 services sur 8 étaient absents : risque direct de pénalité.
- `.gitignore` : une commande shell collée dans le fichier est interprétée comme motif d'exclusion.
- `Contributions.md` vide alors que 100 % des commits étaient d'un seul auteur : −1 à −2 points sur les livrables.

### Vérifications effectuées

| Test | Résultat |
|---|---|
| Domaines résiduels | aucun (`exemple.lan` / `example.lan` éliminés) |
| YAML | `docker-compose.yml`, `user-data.yaml`, `.gitbook.yaml` valides |
| Secrets dans les fichiers suivis | aucun |
| Blocs Mermaid | 5/5 présents et compilés sans erreur |

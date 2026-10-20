# Journal des modifications

> Ce fichier documente **toutes** les modifications apportées au dépôt, sprint par sprint,
> avec la justification et la preuve de vérification. Objectif : que chaque membre puisse
> comprendre et défendre n'importe quel changement.

---

## Sprint J — Création automatique du compte Moodle (19 octobre 2026)

### Problème

Le workflow n8n cherchait l'apprenant par `username = email` mais **ne le créait pas**. Un nouvel
acheteur recevait un webhook HTTP 200, l'exécution n8n était marquée `success`, et pourtant
aucune inscription n'existait : le parcours ne fonctionnait que pour des comptes déjà provisionnés
par un premier login SSO.

### Modifications

- `compose/n8n/workflows/commande-moodle.template.json` : ajout du nœud **Creer utilisateur
  Moodle** (`core_user_create_users`, `auth=oauth2`, `onError: continueRegularOutput`) avant la
  recherche ; l'inscription utilise désormais l'id issu de la recherche.
- Correction de la référence `$json.body.email` → `$('Webhook commande').item.json.body.email`
  dans le nœud de recherche (cassée par l'insertion du nœud précédent).
- Documentation : `docs/operations/integration-n8n.md`, page 10 du GitBook (limite levée),
  page 07 (provisioning), procédure de déploiement, script vidéo.

### Vérifications réelles

| Test | Résultat |
|---|---|
| Achat avec un email jamais vu | compte Moodle créé (`auth=oauth2`) **et** inscrit à `CR465-DEMO` |
| Second achat, même email | toujours **1** inscription (idempotent) |
| Webhook direct hors Drupal | `{"status":"enrolled","email":…}` |

---

## Sprint I — Reproductibilité sur un poste neuf (19 octobre 2026)

### Modifications

- `README.md` : le démarrage rapide omettait l'étape de montage du dossier `compose/` dans la VM.
  Ajout de `scripts/mount-compose.sh` en étape 2, précision que le déploiement s'exécute **dans
  la VM**, et tableau de compatibilité macOS / Linux / Windows (Git Bash ou WSL2).
- `scripts/mount-compose.sh` : `pwd -W` n'existe que sous Git Bash — le script échouait sur
  macOS et Linux. Détection par `uname -s`, chemin adapté par plateforme. L'activation de
  `local.privileged-mounts` (spécifique à Windows/Hyper-V) est désormais conditionnelle.
- `scripts/deploy-stack.sh` : contrôle préalable de la présence du compose dans la VM, avec
  message explicite renvoyant vers `mount-compose.sh`.
- `scripts/authorship-manifest.sh` : `shasum` est absent de Linux (`sha256sum` à la place).
  Fonction `sha256()` qui choisit l'outil disponible.

### Vérifications

| Test | Résultat |
|---|---|
| `bash -n` sur les trois scripts | ✅ |
| Exécution du manifeste après modification | ✅ empreintes régénérées |
| Démarrage rapide relu étape par étape | ✅ chaque commande a son prérequis rempli |

---

## Sprint H — Retrait du service de test (19 octobre 2026)

### Modifications

- `compose/docker-compose.yml` : suppression du service `whoami` et de son alias DNS. La stack
  compte désormais **9 services**, tous métier ou d'infrastructure.
- `scripts/test-routing.sh` : le test de routage cible **Moodle** (`lms.cr465.test`) au lieu du
  service de test.
- `docs/security/scans/traefik_whoami_v1.12.0.txt` : rapport supprimé.
- Documentation alignée : README, GitBook (architecture, sécurité, limites, déploiement),
  pages d'architecture, rapport de scan, script vidéo.

### Justification

Le service `traefik/whoami` n'avait plus de fonction : il servait à prouver le routage avant que
les applications existent. Il était **exposé publiquement**, sa raison d'être est de divulguer
des informations sur le conteneur et la requête, et son scan relevait **15 vulnérabilités HIGH**.
Le conserver n'apportait aucun point et ajoutait une surface d'attaque inutile.

### Vérifications

| Test | Résultat |
|---|---|
| `docker compose config --services` | 9 services, aucun `whoami` |
| `docker compose config` | valide |
| Références résiduelles | aucune hors notes historiques |

---

## Sprint G — Drupal Commerce et chaîne complète (19 octobre 2026)

### Ajouts

| Élément | Détail |
|---|---|
| `compose/drupal/Dockerfile` | Image derivee : `bcmath`, `intl`, `drush`, **Drupal Commerce bake**, module custom |
| `compose/drupal/entrypoint.sh` | Recree `settings.php` au premier demarrage (volume persistant) |
| `compose/drupal/modules/cr465_notify/` | Module qui notifie n8n au passage d'une commande a `completed` (payload + HMAC) |
| `compose/drupal/scripts/configure-commerce.php` | Boutique, passerelle de paiement simulee, produit |
| `compose/drupal/scripts/simulate-purchase.php` | Simule un achat complet pour la demonstration |
| `compose/drupal/php/99-cr465.ini` | Confiance TLS dans l'AC du projet (appels vers n8n) |
| `scripts/configure-drupal.sh` | Installation/configuration reproductible |
| `docs/operations/drupal-commerce.md` | Procedure, pieges, limites |

### Modifications

- `compose/docker-compose.yml` : service `drupal`, volumes `drupal_settings` et `drupal_files`, capacites ciblees (installation), montage de l'AC.
- README : etat d'avancement mis a jour.

### Justification

- **Commerce bake dans l'image** : evite tout telechargement au demarrage et garantit un deploiement reproductible.
- **Capacites ciblees sur Drupal** : `cap_drop: ALL` est conserve, seules les capacites necessaires a l'installation et a Apache sont ajoutees (documente).
- **Module custom plutot que Rules** : une dependance de moins, un comportement explicite et testable.

### Verifications effectuees

| Test | Resultat |
|---|---|
| Boutique `https://shop.cr465.test/` | **200** |
| Page produit | **200** — « Formation CR465 - Initiation aux conteneurs », 49.00 |
| Panier | **200** |
| Notification n8n | **HTTP 200** journalisee par Drupal |
| **Chaine complete** | commande `completed` -> n8n -> **inscription Moodle creee** (`acheteur2@cr465.test`, cours `CR465-DEMO`) |

### Incidents rencontres et corriges

1. `ext-bcmath` manquant -> image derivee.
2. Volumes de modules bloquant Composer -> modules bakes dans l'image.
3. `cap_drop: ALL` sans `DAC_OVERRIDE` -> installation impossible -> capacites ciblees.
4. `settings.php` perdu a chaque recreation -> volume + entrypoint.
5. Devise `CAD` absente du referentiel -> produit en `USD` (documente).
6. Certificat Traefik non reconnu par Drupal -> AC montee + `curl.cainfo`.
7. `$entity->getOriginal()` inexistant -> `$entity->original`.

### Reste a faire (Sprint H)

- Verification de la signature HMAC cote n8n.
- Creation automatique de l'utilisateur Moodle s'il n'existe pas.
- Suppression de `whoami`, GitBook, video, document de synthese.

---

## Sprint F — n8n et attribution d'accès (19 octobre 2026)

### Ajouts

| Élément | Détail |
|---|---|
| Service `n8n` | `n8nio/n8n:1.123.85`, base PostgreSQL dédiée, UI `flow.<domaine>` |
| `compose/n8n/workflows/commande-moodle.template.json` | Workflow webhook → recherche utilisateur → `enrol_manual_enrol_users` |
| `scripts/render-n8n-workflow.sh` | Injecte URL et jeton Moodle dans le workflow (secret hors dépôt) |
| `scripts/configure-moodle-webservice.sh` | Service web REST, compte `svc-n8n`, rôle limité, jeton permanent |
| `compose/moodle/webservice/configure-webservice.php` | Création du service, des fonctions et du rôle |
| `compose/moodle/webservice/seed-course.php` | Cours de démonstration `CR465-DEMO` |
| `docs/operations/integration-n8n.md` | Procédure, pièges, limites |

### Modifications

- `compose/docker-compose.yml` : service n8n, volume `n8n_data`, montage du workflow et de l'AC.
- `.env.example` : `MOODLE_WS_TOKEN`, `MOODLE_COURSE_ID`.
- `.gitignore` : workflow généré (contient le jeton).

### Vérifications effectuées

| Test | Résultat |
|---|---|
| API Moodle (site info) | 200, compte `svc-n8n`, 6 fonctions exposées |
| Recherche utilisateur | `field=username` → utilisateur trouvé (id=3) |
| Inscription directe | `enrol_manual_enrol_users` → `null` (succès) |
| **Chaîne complète** | `POST https://flow.cr465.test/webhook/commande` → `{"status":"enrolled","email":"etudiant1@cr465.test"}` |
| Vérification en base | ligne présente dans `mdl_user_enrolments`, cours `CR465-DEMO` |

### Incidents rencontrés et corrigés

1. `wsaccessusernologin` → plugin `auth_webservice` + compte en mode `webservice`.
2. Recherche par email renvoyant `[]` → recherche par `username` + `moodle/user:viewalldetails`.
3. `wsusercannotassign` → ligne dans `role_allow_assign` pour autoriser l'attribution du rôle student.
4. n8n exécutait un **ancien workflow** (7 doublons actifs, même chemin de webhook) → purge des workflows avant import.
5. Valeurs d'expressions préfixées par `=` → n8n les traitait comme des expressions, jeton vide → configuration en `POST` form-urlencoded avec valeurs littérales.

### Reste à faire (Sprint G)

- **Drupal Commerce** (boutique + paiement simulé) : seul maillon manquant du parcours.
- Création automatique de l'utilisateur Moodle s'il n'existe pas (nœud conditionnel).
- Signature HMAC du webhook et idempotence.
- Suppression de `whoami`, GitBook, vidéo, document de synthèse.

---

## Sprint E — SSO Moodle ↔ Keycloak fonctionnel (19 octobre 2026)

### Ajouts

| Élément | Détail |
|---|---|
| `scripts/gen-certs.sh` | AC locale + certificat wildcard `*.cr465.test` (825 jours), SAN, extensions serveur |
| `compose/traefik/dynamic/tls.yml` | Certificat par défaut de Traefik (fin du certificat auto-signé interne) |
| `compose/moodle/php/99-cr465.ini` | `curl.cainfo` / `openssl.cafile` : Moodle fait confiance à l'AC du projet |
| `scripts/configure-moodle-sso.sh` | Branche le fournisseur OIDC dans Moodle (idempotent) |
| `compose/moodle/sso/configure-oidc.php` | Script Moodle : création/mise à jour du fournisseur, découverte des endpoints, activation du plugin |
| `docs/operations/sso-moodle.md` | Procédure complète et justification des choix |

### Modifications

- `compose/docker-compose.yml` : provider fichier Traefik, montage des certificats, **alias DNS internes** (`auth`, `lms`, `shop`, `flow`, `admin`, `whoami`), montage de l'AC dans Moodle.
- `compose/keycloak/import/realm-cr465.template.json` : attribut PKCE retiré du client `moodle`.
- `scripts/deploy-stack.sh` : génère les certificats avant le déploiement.

### Justification

- **Certificat signé par une AC locale** : Moodle refuse les endpoints non HTTPS et valide le certificat ; le certificat auto-signé interne de Traefik ne pouvait pas être validé.
- **Alias DNS réseau** : `*.cr465.test` n'existe pas dans un DNS public ; les alias Docker permettent la résolution interne sans toucher au `hosts` de la VM.
- **PKCE retiré pour `moodle` uniquement** : le plugin `auth_oauth2` de Moodle n'envoie pas `code_challenge`. Le client reste confidentiel (secret + redirect URI strict + TLS vérifié). Le client `drupal` conserve PKCE.
- **`curlsecurityblockedhosts` vidé** : écart assumé, compensé par la segmentation (Keycloak joignable seulement depuis le réseau `app`).

### Vérifications effectuées

| Test | Résultat |
|---|---|
| Résolution interne | `getent hosts auth.cr465.test` → IP de Traefik ✅ |
| Confiance TLS | cURL de Moodle → `.well-known` : **OK, 6 586 octets** ✅ |
| Découverte d'endpoints | 11 endpoints enregistrés (authorization, token, userinfo, jwks…) ✅ |
| Plugin activé | `auth_oauth2` actif, fournisseur visible sur la page de connexion ✅ |
| Bouton SSO | page `/login/index.php` contient `auth/oauth2/login.php` et « Keycloak » ✅ |
| Redirection OAuth | **303** vers `auth.cr465.test/.../auth?client_id=moodle&redirect_uri=https://lms.cr465.test/admin/oauth2callback.php&scope=openid profile email` ✅ |
| Formulaire Keycloak | **200**, page « Se connecter à CR465 - Plateforme de formation » ✅ |
| **Connexion complète** | Authentification avec `etudiant1` → **200 sur `https://lms.cr465.test/my/`**, titre « Tableau de bord \| moodle » ✅ |

### Incidents rencontrés et corrigés

1. `image` NOT NULL dans `mdl_oauth2_issuer` → champ `image` fourni vide.
2. Moodle ne résolvait pas `auth.cr465.test` → alias DNS sur Traefik.
3. Moodle bloquait les adresses privées (SSRF) → `curlsecurityblockedhosts` vidé, documenté.
4. Keycloak refusait le flux (`Missing parameter: code_challenge_method`) → PKCE retiré du client `moodle`.
5. Chemin des scripts CLI Moodle (`admin/cli` et non `public/admin/cli`) → corrigé.

### Reste à faire (Sprint F)

- Drupal Commerce + paiement simulé.
- n8n + workflow d'attribution d'accès.
- Suppression de `whoami`, GitLab/GitBook, vidéo, synthèse.

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

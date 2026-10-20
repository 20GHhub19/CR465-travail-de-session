# Contribution de Maxime — branche `Projet-CR465-D-Maxime`

> Document de traçabilité individuelle. Périmètre : **du dernier commit de Gaius**
> (`3cde540`, *feat(phase3): Traefik + TLS + segmentation reseau*) **à la tête actuelle**
> (`a9a782c`). Toutes les modifications listées ici sont celles de l'auteur `fokomaximejoel`.

## Bilan

| Indicateur | Valeur |
|---|---|
| Commits | **30** |
| Fichiers distincts | **82** |
| Fichiers créés | 55 |
| Fichiers modifiés | 99 |
| Fichiers supprimés | 1 |
| Signatures | 100 % des commits signés en SSH (badge *Verified* sur GitHub) |
| Étiquette de référence | `empreinte-maxime-v2` (`b1a3c6e`) |

## Chronologie des commits

| Commit | Date | Message |
|---|---|---|
| `98f9a9c` | 2026-10-19 | chore: assainit le .gitignore (retrait commande shell, exclusions completes) |
| `22771d1` | 2026-10-19 | refactor(domaine): unifie tous les sous-domaines sur cr465.test |
| `321d7ae` | 2026-10-19 | docs(architecture): schemas consolides, guide de lecture et contributions |
| `720afab` | 2026-10-19 | feat(compose): durcit la stack conteneurisee |
| `9288730` | 2026-10-19 | feat(scripts): scan local des images avec Trivy |
| `3c2b42e` | 2026-10-19 | docs(security): politique images, durcissement, rapport de scan |
| `976f953` | 2026-10-19 | docs: met a jour README et schemas apres durcissement |
| `73b981f` | 2026-10-19 | feat(compose): ajoute PostgreSQL et Keycloak durcis |
| `0d47bee` | 2026-10-19 | feat(keycloak): realm cr465 avec clients OIDC Moodle et Drupal |
| `aa0236f` | 2026-10-19 | docs: deploiement, journal des modifications et schemas a jour |
| `628a0eb` | 2026-10-19 | feat(compose): ajoute Moodle, Portainer et un reseau egress controle |
| `3ce9151` | 2026-10-19 | docs: Moodle et Portainer deployes, journal du sprint D |
| `a846a8f` | 2026-10-19 | feat(tls): certificat local de confiance et alias DNS internes |
| `8fa08f3` | 2026-10-19 | feat(sso): branche le fournisseur OIDC Keycloak dans Moodle |
| `ce4336f` | 2026-10-19 | docs: SSO Moodle-Keycloak fonctionnel et journal du sprint E |
| `1546587` | 2026-10-19 | feat(integration): n8n attribue les acces Moodle apres commande |
| `8332f15` | 2026-10-19 | docs: integration n8n-Moodle et journal du sprint F |
| `681baa4` | 2026-10-19 | feat(drupal): boutique Drupal Commerce et chaine d achat complete |
| `c950285` | 2026-10-19 | docs: drupal commerce et journal du sprint G |
| `f380ae7` | 2026-10-19 | docs(gitbook): remplissage des 11 pages du livrable |
| `af6c57c` | 2026-10-19 | docs: document de synthese (Word, 8 pages) et script video |
| `9894e33` | 2026-10-19 | chore: retire le service de test whoami et aligne la documentation |
| `762cbf1` | 2026-10-19 | docs: recapitalatif complet des modifications depuis le premier commit |
| `beb7864` | 2026-10-19 | docs: identifie les contributions de fokomaximejoel dans GitBook et contributions |
| `5126dfa` | 2026-10-19 | chore: empreinte d auteur verifiable et propriete des fichiers |
| `d51cb28` | 2026-10-19 | docs: precise le point de reference de l empreinte (etiquette) |
| `6269965` | 2026-10-19 | docs: empreinte rattachee a une etiquette signee (v2) |
| `8d928f4` | 2026-10-19 | chore: empreintes SHA-256 de l etiquette v2 |
| `aefc1aa` | 2026-10-19 | chore: manifeste des commits de l etiquette v2 |
| `a9a782c` | 2026-10-19 | docs: formulation sans compteur figé (tous les commits signes) |

## Fichiers touchés, par domaine


### Orchestration et durcissement (2 fichiers)

- `compose/.env.example`
- `compose/docker-compose.yml`

### Données et identité (2 fichiers)

- `compose/keycloak/import/realm-cr465.template.json`
- `compose/postgres/init/01-create-databases.sh`

### Moodle et SSO (4 fichiers)

- `compose/moodle/php/99-cr465.ini`
- `compose/moodle/sso/configure-oidc.php`
- `compose/moodle/webservice/configure-webservice.php`
- `compose/moodle/webservice/seed-course.php`

### Intégration n8n (1 fichiers)

- `compose/n8n/workflows/commande-moodle.template.json`

### Boutique Drupal (8 fichiers)

- `compose/drupal/Dockerfile`
- `compose/drupal/entrypoint.sh`
- `compose/drupal/modules/cr465_notify/config/install/cr465_notify.settings.yml`
- `compose/drupal/modules/cr465_notify/cr465_notify.info.yml`
- `compose/drupal/modules/cr465_notify/cr465_notify.module`
- `compose/drupal/php/99-cr465.ini`
- `compose/drupal/scripts/configure-commerce.php`
- `compose/drupal/scripts/simulate-purchase.php`

### Traefik et TLS (1 fichiers)

- `compose/traefik/dynamic/tls.yml`

### Scripts (14 fichiers)

- `scripts/authorship-manifest.sh`
- `scripts/configure-drupal.sh`
- `scripts/configure-moodle-sso.sh`
- `scripts/configure-moodle-webservice.sh`
- `scripts/deploy-stack.sh`
- `scripts/destroy-vm.sh`
- `scripts/gen-certs.sh`
- `scripts/install-gvisor.sh`
- `scripts/launch-vm.sh`
- `scripts/mount-compose.sh`
- `scripts/render-keycloak-realm.sh`
- `scripts/render-n8n-workflow.sh`
- `scripts/scan-images.sh`
- `scripts/test-routing.sh`

### Documentation technique (23 fichiers)

- `docs/architecture/01-architecture-generale.md`
- `docs/architecture/02-segmentation-reseau.md`
- `docs/architecture/03-sequence-integration.md`
- `docs/architecture/04-sequence-sso.md`
- `docs/architecture/05-defense-en-profondeur.md`
- `docs/architecture/README.md`
- `docs/architecture/img/01-architecture-generale.png`
- `docs/architecture/img/02-segmentation-reseau.png`
- `docs/architecture/img/03-sequence-integration.png`
- `docs/architecture/img/04-sequence-sso.png`
- `docs/architecture/img/05-defense-profondeur.png`
- `docs/operations/deploiement.md`
- `docs/operations/drupal-commerce.md`
- `docs/operations/incident-api-docker.md`
- `docs/operations/integration-n8n.md`
- `docs/operations/sso-moodle.md`
- `docs/operations/video-script.md`
- `docs/security/01-securite-images.md`
- `docs/security/02-durcissement-execution.md`
- `docs/security/03-rapport-scan.md`
- `docs/security/scans/tecnativa_docker-socket-proxy_v0.5.0.txt`
- `docs/security/scans/traefik_v3.7.15.txt`
- `docs/security/scans/traefik_whoami_v1.12.0.txt`

### GitBook (17 fichiers)

- `gitbook/README.md`
- `gitbook/assets/01-architecture-generale.png`
- `gitbook/assets/02-segmentation-reseau.png`
- `gitbook/assets/03-sequence-integration.png`
- `gitbook/assets/04-sequence-sso.png`
- `gitbook/assets/05-defense-profondeur.png`
- `gitbook/projet-realisation/01-presentation.md`
- `gitbook/projet-realisation/02-architecture.md`
- `gitbook/projet-realisation/03-vm-cloud-init.md`
- `gitbook/projet-realisation/04-deploiement-compose.md`
- `gitbook/projet-realisation/05-segmentation-reseau.md`
- `gitbook/projet-realisation/06-securite.md`
- `gitbook/projet-realisation/07-sso.md`
- `gitbook/projet-realisation/08-workflow-n8n.md`
- `gitbook/projet-realisation/09-observabilite.md`
- `gitbook/projet-realisation/10-limites-risques.md`
- `gitbook/projet-realisation/11-contributions.md`

### Livrables (5 fichiers)

- `.github/CODEOWNERS`
- `AUTHORSHIP.md`
- `CHANGELOG.md`
- `CR465-synthese-groupe-D.docx`
- `RECAP-modifications.md`

### Autres (5 fichiers)

- `.gitignore`
- `README.md`
- `authorship/empreintes.txt`
- `authorship/fokomaximejoel-commits.txt`
- `md/Contributions.md`

## Vérification par un tiers

```bash
# 1. Les commits de l'auteur dans ce périmètre
git log --author=fokomaximejoel --oneline 3cde540..HEAD | wc -l   # → 30

# 2. Signatures valides
git log --format='%h %G?' --author=fokomaximejoel | sort | uniq -c   # → G partout

# 3. Reconstruire l'historique hors ligne
git bundle verify authorship/fokomaximejoel.bundle
shasum -a 256 authorship/fokomaximejoel.bundle   # comparer à authorship/empreintes.txt
```

## Ce que je peux expliquer et démontrer

| Sujet | Preuve |
|---|---|
| Durcissement des conteneurs | `cap_drop`, `no-new-privileges`, non-root, `read_only` — vérifiable par `docker inspect` |
| Segmentation réseau | 5 réseaux, `app` interne, `egress` réservé — schéma + `docker network inspect` |
| Socket Docker | deux proxys filtrants (RO pour Traefik, RW pour Portainer) |
| Données | 4 bases, 4 utilisateurs, `REVOKE ALL FROM PUBLIC` |
| Identité | realm déclaratif, 2 clients OIDC, secrets générés au déploiement |
| SSO Moodle | parcours complet testé, session ouverte via Keycloak |
| Intégration | achat Drupal → webhook → inscription Moodle vérifiée en base |
| Images | scan Trivy local, versions épinglées |
| Livrables | GitBook (11 pages), synthèse Word (8 pages), script vidéo |

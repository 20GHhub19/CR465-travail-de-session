# Contributions des membres

> Ce fichier est un livrable évalué : la grille prévoit explicitement « contributions
> individuelles non identifiables → −1 à −2 points ».
> **Chaque membre doit compléter sa propre ligne** — ne pas laisser l'équipe remplir à votre place.

## État vérifié de l'historique Git

Relevé le 19 octobre 2026 (`git shortlog -sne --all`) :

| Auteur (Git) | Commits | Branche principale |
|---|---:|---|
| **fokomaximejoel** (Maxime) | **23** | `Projet-CR465-D-Maxime` |
| Gaius Heumen | 11 | `Projet-CR465-D-Gaius` |
| Citizen X | 6 | (à préciser) |
| notap-exe | 1 | (à préciser) |
| 20GHhub19 | 1 | dépôt de référence |
| PolyMTL (licence initiale) | 2 | — |

**Branches distantes** : `Projet-CR465-D` (12 commits), `-Anna` (21), `-Gaius` (19), `-Maxime` (19), `main` (8).

## Répartition des verticales (à valider en équipe)

| Membre | Verticale | Fichiers / dossiers sous sa responsabilité | Commits attendus |
|---|---|---|---|
| **Gaius** | Socle VM as Code + reverse proxy | `cloud-init/`, `compose/traefik/`, `scripts/` | ✅ 11 commits |
| **Maxime** | Architecture, schémas, documentation, coordination | `docs/architecture/`, `gitbook/`, synthèse | à produire |
| **Anna** | Applications cœur | `compose/drupal-commerce/`, `compose/moodle/`, `compose/postgres/` | à produire |
| *(membre 4)* | Identité, intégrations, observabilité | `compose/keycloak/`, `compose/n8n/`, `compose/observability/` | à produire |
| *(membre 5)* | Sécurité transversale | `docs/security/`, `scripts/scan-images.sh`, durcissement | à produire |

## Contributions détaillées

### Gaius — Socle VM as Code et reverse proxy
- `cloud-init/user-data.yaml` : utilisateur `adminops` par clé SSH, durcissement SSH, UFW, fail2ban,
  mises à jour automatiques, sysctl, durcissement du démon Docker.
- `compose/docker-compose.yml` : Traefik et segmentation réseau initiale (service de test depuis retiré).
- `scripts/` : lancement de VM, déploiement, test de routage, montage du compose, destruction.
- `docs/operations/incident-multipass-windows.md` : diagnostic et contournement d'incident.
- `gitbook/` : squelette de la documentation.

### Maxime (`fokomaximejoel`) — Architecture, sécurité et intégrations
- `docs/architecture/01` à `05` : schémas consolidés (zones de confiance, flux interdits,
  authentification des webhooks, SSO OIDC, sept couches de défense).
- `docs/architecture/README.md` : guide de lecture des cinq schémas.
- `docs/architecture/img/` : rendus PNG des schémas.
- Unification du domaine et corrections de cohérence du dépôt.
- Coordination, synthèse et préparation de la vidéo.

### Anna — *(à compléter)*
-

### Membre 4 — *(nom à préciser)*
-

### Membre 5 — *(nom à préciser)*
-

## Rappel des règles

1. Chaque membre **commite lui-même** sur sa branche : l'historique doit refléter la contribution réelle.
2. Aucun commit ne doit être poussé au nom d'un autre membre.
3. Ce tableau doit être cohérent avec `git log` au moment de la remise.

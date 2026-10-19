# Contribution des membres

> Les contributions sont vérifiables dans l'historique Git. Chaque membre doit pouvoir
> expliquer la partie qu'il a produite.

## Relevé Git (19 octobre 2026)

| Auteur | Commits |
|---|---:|
| Gaius Heumen | 11 |
| Citizen X | 6 |
| notap-exe | 1 |
| 20GHhub19 | 1 |
| PolyMTL (licence initiale) | 2 |

Branches de travail : `Projet-CR465-D`, `Projet-CR465-D-Anna`, `Projet-CR465-D-Gaius`,
`Projet-CR465-D-Maxime`.

## Répartition des verticales

| Membre | Verticale | Périmètre |
|---|---|---|
| **Gaius** | Socle VM as Code et reverse proxy | `cloud-init/`, Traefik, scripts de lancement, note d'incident Multipass |
| **Maxime** | Architecture, documentation, coordination | schémas, GitBook, synthèse, unification du domaine, corrections de cohérence |
| **Anna** | Applications cœur | Drupal Commerce, Moodle, PostgreSQL |
| **Membre 4** | Identité, intégrations, observabilité | Keycloak, n8n, Portainer |
| **Membre 5** | Sécurité transversale | durcissement, scans Trivy, documentation sécurité |

## Contributions détaillées (à compléter par chaque membre)

### Gaius — socle
- `cloud-init/user-data.yaml` : utilisateur, SSH durci, UFW, fail2ban, Docker, sysctl.
- `compose/docker-compose.yml` : base Traefik + réseaux.
- `scripts/` : lancement de VM, déploiement, test de routage.
- `docs/operations/incident-multipass-windows.md`.

### Maxime — architecture et documentation
- `docs/architecture/01` à `05` : schémas consolidés (zones, flux interdits, webhook signé, SSO, 7 couches).
- `docs/architecture/README.md` : guide de lecture.
- `CHANGELOG.md` : journal détaillé des modifications.
- Unification du domaine `cr465.test`, corrections `.gitignore` et contributions.

### Anna — applications cœur
- *(à compléter : Drupal Commerce, Moodle, PostgreSQL)*

### Membre 4 — identité, intégrations, observabilité
- *(à compléter : Keycloak, n8n, Portainer)*

### Membre 5 — sécurité
- *(à compléter : scans, durcissement, documentation)*

## Règle de traçabilité

Chaque modification doit être commitée par son auteur sur sa branche, avec un message
explicite. Le `CHANGELOG.md` du dépôt documente les changements majeurs, leurs justifications
et les vérifications effectuées.

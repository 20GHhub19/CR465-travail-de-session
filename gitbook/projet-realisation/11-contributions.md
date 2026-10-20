# Contribution des membres

> Les contributions sont vérifiables dans l'historique Git. Chaque membre doit pouvoir
> expliquer la partie qu'il a produite.

## Relevé Git (19 octobre 2026)

| Auteur (Git) | Commits |
|---|---:|
| **fokomaximejoel** (Maxime) | **35** |
| Gaius Heumen | 11 |
| Citizen X | 6 |
| notap-exe (Anna) | 2 |
| 20GHhub19 | 1 |
| PolyMTL (licence initiale) | 2 |

Branches de travail : `Projet-CR465-D`, `Projet-CR465-D-Anna`, `Projet-CR465-D-Gaius`,
`Projet-CR465-D-Maxime`.

## Répartition des verticales

| Membre | Verticale | Périmètre |
|---|---|---|
| **Gaius** | Socle VM as Code et reverse proxy | `cloud-init/`, Traefik, scripts de lancement, note d'incident Multipass |
| **Maxime** (`fokomaximejoel`) | Architecture, documentation, coordination | schémas, GitBook, synthèse, vidéo, base de données, identité, SSO, intégrations, durcissement |
| **Anna** (`notap-exe`) | Applications cœur | Drupal Commerce, Moodle, PostgreSQL |
| **Membre 4** | Identité, intégrations, observabilité | Keycloak, n8n, Portainer |
| **Membre 5** | Sécurité transversale | durcissement, scans Trivy, documentation sécurité |

## Contributions détaillées (à compléter par chaque membre)

### Gaius — socle
- `cloud-init/user-data.yaml` : utilisateur, SSH durci, UFW, fail2ban, Docker, sysctl.
- `compose/docker-compose.yml` : base Traefik + réseaux.
- `scripts/` : lancement de VM, déploiement, test de routage.
- `docs/operations/incident-multipass-windows.md`.

### Maxime (`fokomaximejoel`) — architecture, sécurité et intégrations
- `docs/architecture/01` à `05` : schémas consolidés (zones, flux interdits, webhook signé, SSO, 7 couches).
- `compose/docker-compose.yml` : durcissement complet, PostgreSQL, Keycloak, Moodle, Portainer, n8n, Drupal.
- `compose/keycloak/`, `compose/moodle/`, `compose/n8n/`, `compose/drupal/` : configurations et scripts.
- `scripts/` : certificats, realm, SSO, service web Moodle, workflow n8n, installation Drupal, scan Trivy.
- `docs/security/`, `docs/operations/` : documentation technique.
- `gitbook/` (11 pages), `CR465-synthese-groupe-D.docx`, `docs/operations/video-script.md`.
- `CHANGELOG.md`, `RECAP-modifications.md` : traçabilité des modifications.

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

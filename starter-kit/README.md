# Kit de démarrage — starter-kit (Docker rootful)

Kit optionnel fourni en complément de l'énoncé du travail de session. Il ne couvre que la
« plomberie » de base — Traefik, Task et un scan de vulnérabilité local — afin que votre équipe
passe son temps sur les éléments réellement notés plutôt que sur la configuration répétitive.

## Portée

Fourni : cloud-init, Traefik + service de test `whoami`, Taskfile avec `task scan` (Trivy local).
Non fourni : Drupal Commerce, Moodle, Keycloak, n8n, Opencast, Redis, Portainer CE, OpenAppSec,
la segmentation réseau complète, le SSO — tout cela reste à réaliser par votre équipe.

## Démarrage rapide

```
# 1. Démarrer une VM avec cloud-init/user-data.yaml (voir tutoriels/01-cloud-init-et-vm.md)
# 2. Copier compose/ et Taskfile.yml dans /opt/stack sur la VM
task up
curl http://<IP_DE_LA_VM>/whoami
task scan
```

## Structure

```
starter-kit/
├── cloud-init/user-data.yaml
├── compose/
│   ├── docker-compose.yml
│   ├── .env.example
│   └── traefik/dynamic/
├── Taskfile.yml
└── tutoriels/
    ├── 00-introduction.md
    ├── 01-cloud-init-et-vm.md
    ├── 02-taskfile.md
    ├── 03-traefik.md
    └── 04-scan-vulnerabilites.md
```

## Variantes

- `../starter-kit-rootless/` — même kit avec Docker en mode rootless.
- `../starter-kit-podman/` — même kit avec Podman (rootless par défaut), moteur reconnu comme
  équivalent à Docker Compose selon la contrainte #2 de l'énoncé.

Commencez par `tutoriels/00-introduction.md`.

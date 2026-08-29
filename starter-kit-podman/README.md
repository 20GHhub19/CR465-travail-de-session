# Kit de démarrage — starter-kit-podman (Podman, rootless par défaut)

Variante de `../starter-kit/` utilisant **Podman** au lieu de Docker. Officiellement reconnu comme
moteur équivalent à Docker Compose par la contrainte #2 de l'énoncé (mise à jour) — utilisable pour
votre remise officielle, pas seulement pour l'exploration personnelle.

## Portée

Fourni : cloud-init (Podman rootless, `podman-compose`, Task, pare-feu), Traefik + `whoami`,
Taskfile avec `task scan` (Trivy local). Non fourni : Drupal Commerce, Moodle, Keycloak, n8n,
Opencast, Redis, Portainer CE, OpenAppSec — à réaliser par votre équipe.

## Démarrage rapide

```
# 1. Démarrer une VM avec cloud-init/user-data.yaml (voir tutoriels/01-cloud-init-et-vm.md)
# 2. En tant qu'utilisateur admin (jamais root) :
cp compose/.env.example compose/.env   # ajustez PODMAN_SOCK si nécessaire
task up
curl http://<IP_DE_LA_VM>/whoami
task scan
```

## Structure

```
starter-kit-podman/
├── cloud-init/user-data.yaml
├── compose/
│   ├── docker-compose.yml
│   ├── .env.example
│   └── traefik/dynamic/
├── Taskfile.yml
└── tutoriels/
    ├── 00-introduction.md
    ├── 01-cloud-init-et-vm.md
    └── 02-podman-vs-docker.md
```

Commencez par `tutoriels/00-introduction.md`.

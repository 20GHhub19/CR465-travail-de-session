# Kit de démarrage — starter-kit-rootless (Docker rootless)

Variante de `../starter-kit/` : la même stack (Traefik + whoami + Task + scan Trivy local), mais
avec un démon Docker exécuté en espace utilisateur, jamais en root. Kit optionnel, non requis par
l'énoncé — un durcissement supplémentaire de l'hôte pour les équipes qui veulent aller plus loin.

## Portée

Fourni : cloud-init (Docker rootless, Task, pare-feu), Traefik + `whoami`, Taskfile avec `task scan`.
Non fourni : Drupal Commerce, Moodle, Keycloak, n8n, Opencast, Redis, Portainer CE, OpenAppSec —
à réaliser par votre équipe.

## Démarrage rapide

```
# 1. Démarrer une VM avec cloud-init/user-data.yaml (voir tutoriels/01-cloud-init-et-vm.md)
# 2. En tant qu'utilisateur admin (jamais root) :
cp compose/.env.example compose/.env   # ajustez DOCKER_SOCK si nécessaire
task up
curl http://<IP_DE_LA_VM>/whoami
task scan
```

## Structure

```
starter-kit-rootless/
├── cloud-init/user-data.yaml
├── compose/
│   ├── docker-compose.yml
│   ├── .env.example
│   └── traefik/dynamic/
├── Taskfile.yml
└── tutoriels/
    ├── 00-introduction.md
    ├── 01-cloud-init-et-vm.md
    └── 02-limites-et-depannage.md
```

Pour les tutoriels Task et Traefik en détail, voir `../starter-kit/tutoriels/` (contenu identique,
seul le chemin du socket Docker change).

Commencez par `tutoriels/00-introduction.md`.

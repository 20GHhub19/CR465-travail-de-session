# Kit de démarrage — starter-kit-gvisor (sandboxing avec gVisor)

Variante de `../starter-kit/` (Docker rootful) qui ajoute le runtime **gVisor** (`runsc`), un
sandbox en espace utilisateur qui isole les appels système entre les conteneurs applicatifs et le
noyau hôte. Kit optionnel, non requis par l'énoncé — une couche de défense en profondeur
supplémentaire pour les équipes qui veulent aller plus loin sur la sécurité à l'exécution.

## Portée

Fourni : cloud-init (Docker, Task, gVisor/`runsc`, pare-feu), Traefik (runtime standard) +
`whoami` (sandboxé sous `runsc`), Taskfile avec `task scan` (Trivy) et `task verify-sandbox`.
Non fourni : Drupal Commerce, Moodle, Keycloak, n8n, Opencast, Redis, Portainer CE, OpenAppSec —
à réaliser par votre équipe.

## Démarrage rapide

```
# 1. Démarrer une VM avec cloud-init/user-data.yaml (voir tutoriels/01-cloud-init-et-vm.md)
# 2. Copier compose/ et Taskfile.yml dans /opt/stack sur la VM
task up
curl http://<IP_DE_LA_VM>/whoami
task verify-sandbox
task scan
```

## Structure

```
starter-kit-gvisor/
├── cloud-init/user-data.yaml
├── compose/
│   ├── docker-compose.yml
│   ├── .env.example
│   └── traefik/dynamic/
├── Taskfile.yml
└── tutoriels/
    ├── 00-introduction.md
    ├── 01-cloud-init-et-vm.md
    └── 02-gvisor-vs-runc.md
```

## Variantes apparentées

- `../starter-kit-rootless/` et `../starter-kit-podman/` durcissent le **privilège du démon**
  (axe différent, combinable avec gVisor).

Commencez par `tutoriels/00-introduction.md`.

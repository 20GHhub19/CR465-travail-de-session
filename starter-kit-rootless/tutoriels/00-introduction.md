# 00 — Introduction (variante Docker rootless)

## Différence avec le kit de base

Ce kit reprend exactement la même stack que `starter-kit/` (Traefik + whoami + Task + scan Trivy),
avec un seul changement : **le démon Docker tourne sous l'utilisateur `admin`, jamais en root**.
En mode classique (« rootful »), être membre du groupe `docker` équivaut en pratique à un accès
root sur l'hôte via le socket Docker. Le mode rootless élimine ce raccourci de privilège.

## Ce qui change concrètement

- Docker s'exécute comme un service utilisateur systemd (`systemctl --user`), pas comme service
  système.
- Le socket Docker se trouve dans `/run/user/<uid>/docker.sock`, pas dans `/var/run/docker.sock`.
- Le réseau des conteneurs passe par `slirp4netns` (réseau en espace utilisateur), avec un léger
  surcoût de performance réseau par rapport au mode rootful.
- Un réglage système (`net.ipv4.ip_unprivileged_port_start=80`) est nécessaire pour que Traefik
  puisse écouter sur le port 80 sans capacité Linux spéciale.

## Ce que ce kit ne fournit toujours pas

Comme pour le kit de base : Drupal Commerce, Moodle, Keycloak, n8n, Opencast, Redis, Portainer CE,
OpenAppSec, etc. restent à réaliser par votre équipe.

## Ordre de lecture suggéré

1. `01-cloud-init-et-vm.md` — démarrage de la VM en mode rootless.
2. `02-limites-et-depannage.md` — compromis et pièges connus du mode rootless.
3. Pour Task, Traefik et le scan de vulnérabilité en détail, référez-vous aux tutoriels
   équivalents de `../starter-kit/tutoriels/` — le contenu est identique, seul le socket Docker change
   (`${DOCKER_SOCK}` au lieu de `/var/run/docker.sock`, déjà pris en compte dans ce kit).

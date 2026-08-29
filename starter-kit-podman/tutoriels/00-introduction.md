# 00 — Introduction (variante Podman)

## Statut officiel

Depuis la mise à jour de la contrainte #2 de l'énoncé, **Podman avec sa couche de compatibilité
Compose (`podman-compose`) est un moteur reconnu équivalent à Docker Compose**. Vous pouvez donc
utiliser ce kit pour votre remise officielle, pas seulement pour l'exploration personnelle.

## Différence avec le kit de base

Podman est daemonless et rootless par conception (pas de démon central tournant en root, contrairement
à Docker classique) — le mode « moindre privilège » est ici la norme, pas une option à activer.
La stack fournie (Traefik + whoami + Task + scan Trivy) est identique à celle des deux autres kits,
seuls les outils qui l'exploitent changent : `podman-compose` au lieu de `docker compose`, `podman run`
au lieu de `docker run`.

## Ce que ce kit ne fournit toujours pas

Comme pour les deux autres kits : Drupal Commerce, Moodle, Keycloak, n8n, Opencast, Redis,
Portainer CE, OpenAppSec restent à réaliser par votre équipe.

## Limites connues de `podman-compose`

`podman-compose` ne supporte pas 100 % des options de Docker Compose (certaines syntaxes de
`healthcheck` ou de pilotes réseau avancés peuvent différer). Pour la stack minimale de ce kit,
tout fonctionne sans adaptation. Si vous étendez fortement votre stack, testez tôt et documentez
les éventuels écarts dans votre GitBook.

## Ordre de lecture suggéré

1. `01-cloud-init-et-vm.md` — démarrage de la VM avec Podman.
2. `02-podman-vs-docker.md` — différences pratiques, compatibilité avec Traefik, dépannage.

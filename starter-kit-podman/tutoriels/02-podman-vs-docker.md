# 02 — Podman vs Docker : différences pratiques

## Pourquoi Traefik fonctionne sans modification

Le provider `docker` de Traefik lit l'API du socket monté dans `/var/run/docker.sock` (à l'intérieur
du conteneur Traefik). Podman expose une API compatible avec celle de Docker pour les opérations
dont Traefik a besoin (lister les conteneurs, lire leurs labels). C'est pourquoi la configuration
Traefik de ce kit est identique à celle des deux autres — seul le socket monté change
(`${PODMAN_SOCK}` au lieu de `/var/run/docker.sock` ou `${DOCKER_SOCK}`).

## Différences de commandes

| Docker | Podman |
|---|---|
| `docker compose up -d` | `podman-compose up -d` |
| `docker compose logs -f` | `podman-compose logs -f` |
| `docker run --rm ...` | `podman run --rm ...` |
| Socket : `/var/run/docker.sock` | Socket : `$XDG_RUNTIME_DIR/podman/podman.sock` |

## Dépannage rapide

| Symptôme | Piste |
|---|---|
| `podman-compose: command not found` | Vérifiez `pip3 show podman-compose` ; relancez `source ~/.bashrc`. |
| Traefik ne voit aucun conteneur | Vérifiez que `${PODMAN_SOCK}` correspond bien à `echo $XDG_RUNTIME_DIR/podman/podman.sock`. |
| Le socket disparaît après déconnexion SSH | Vérifiez `loginctl show-user admin \| grep Linger` (doit être `yes`). |
| Erreur de syntaxe compose non reproductible avec Docker | `podman-compose` ne supporte pas 100 % des options de Docker Compose — documentez l'écart dans votre GitBook plutôt que de forcer une syntaxe non supportée. |

## Rappel sur la contrainte #2 de l'énoncé

Ce kit satisfait la contrainte #2 (« Docker Compose obligatoire, ou Podman avec sa couche de
compatibilité Compose ») telle que mise à jour dans l'énoncé. Mentionnez explicitement dans votre
GitBook que vous utilisez Podman plutôt que Docker, pour éviter toute ambiguïté pour le correcteur.

# 01 — Cloud-init et démarrage de la VM (Podman)

## Avant de démarrer une VM avec ce fichier

Remplacez la ligne `ssh_authorized_keys` par votre propre clé publique (voir la même étape dans
`../starter-kit/tutoriels/01-cloud-init-et-vm.md`).

## Ce que `runcmd` installe

1. `podman` (paquet officiel Ubuntu) et ses prérequis rootless (`uidmap`, `slirp4netns`,
   `fuse-overlayfs`).
2. `podman-compose` via `pip3`, pour consommer le même format de fichier `docker-compose.yml`.
3. `net.ipv4.ip_unprivileged_port_start=80`, pour permettre à Traefik de se lier au port 80.
4. `loginctl enable-linger admin`, pour que le socket Podman reste actif après déconnexion.
5. Le service utilisateur `podman.socket`, qui expose une API compatible Docker — c'est ce qui
   permet à Traefik de continuer à utiliser son provider `docker` sans modification.

## Démarrer la VM et vérifier l'installation

```
ssh admin@<IP_DE_LA_VM>
cloud-init status --wait
systemctl --user status podman.socket
podman info | grep -i rootless
```

## Étape suivante

Copiez `compose/` et `Taskfile.yml` dans `/opt/stack`, ajustez `PODMAN_SOCK` dans `.env` si
nécessaire, puis lancez `task up` **en tant qu'utilisateur admin** (jamais avec `sudo`).

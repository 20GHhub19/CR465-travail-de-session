# 01 — Cloud-init et démarrage de la VM (rootless)

## Avant de démarrer une VM avec ce fichier

Remplacez la ligne `ssh_authorized_keys` par votre propre clé publique (voir la même étape dans
`../starter-kit/tutoriels/01-cloud-init-et-vm.md`).

## Ce que `runcmd` fait de plus par rapport au kit de base

1. Installe les prérequis rootless (`uidmap`, `dbus-user-session`, `fuse-overlayfs`, `slirp4netns`).
2. Installe `docker-ce-rootless-extras` au lieu de `docker-ce` (pas de démon système).
3. Configure `net.ipv4.ip_unprivileged_port_start=80` pour permettre le bind sur le port 80.
4. Active la persistance de session (`loginctl enable-linger admin`) — indispensable pour que le
   démon rootless reste actif après déconnexion et redémarre au boot de la VM.
5. Exécute `dockerd-rootless-setuptool.sh install` **en tant qu'utilisateur `admin`**, jamais en root.
6. Exporte `DOCKER_HOST` et `XDG_RUNTIME_DIR` dans le profil shell de `admin`.

## Démarrer la VM et vérifier l'installation

```
ssh admin@<IP_DE_LA_VM>
cloud-init status --wait
systemctl --user status docker
docker info | grep -i rootless
```

Si `docker info` confirme le mode rootless et que `systemctl --user status docker` indique
« active (running) », l'installation a réussi.

## Étape suivante

Copiez `compose/` et `Taskfile.yml` dans `/opt/stack`, adaptez `DOCKER_SOCK` dans `.env` si
nécessaire (voir `02-limites-et-depannage.md`), puis lancez `task up` **en tant qu'utilisateur
admin** (jamais avec `sudo`).

# 01 — Cloud-init et démarrage de la VM (gVisor)

## Avant de démarrer une VM avec ce fichier

Remplacez la ligne `ssh_authorized_keys` par votre propre clé publique (voir la même étape dans
`../starter-kit/tutoriels/01-cloud-init-et-vm.md`). gVisor exige un noyau **Linux 5.6 ou plus
récent** (x86_64 ou ARM64) — vérifiez que l'image de votre VM le respecte.

## Ce que `runcmd` fait de plus par rapport au kit de base

1. Ajoute le dépôt apt officiel de gVisor (clé `gvisor.dev/archive.key`).
2. Installe le paquet `runsc`.
3. Exécute `runsc install`, qui enregistre le runtime `runsc` dans `/etc/docker/daemon.json`.
4. Redémarre le démon Docker pour que le nouveau runtime soit disponible.

## Démarrer la VM et vérifier l'installation

```
ssh admin@<IP_DE_LA_VM>
cloud-init status --wait
runsc --version
docker info | grep -i runtime
```

Vous devriez voir `runsc` listé parmi les runtimes disponibles de Docker.

## Étape suivante

Copiez `compose/` et `Taskfile.yml` dans `/opt/stack`, puis lancez `task up` — voir
`02-gvisor-vs-runc.md` pour comprendre pourquoi seul le service `whoami` utilise `runtime: runsc`.

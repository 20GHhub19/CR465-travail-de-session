# Tests de compatibilité par plateforme

> Objectif : démontrer que la plateforme se déploie sur les trois systèmes visés, quel que soit
> le processeur. Chaque ligne doit être **réellement exécutée** avant d'être cochée.

## Matrice de compatibilité

| Plateforme | Architecture | État | Validé par |
|---|---|---|---|
| macOS (Apple Silicon) | arm64 | ✅ testé (Docker local) | Maxime |
| macOS (Apple Silicon) | arm64 | ⬜ VM as Code à valider (Multipass non installé) | — |
| macOS (Intel) | amd64 | ⬜ non testé | — |
| Linux Ubuntu 24.04 | amd64 | ⬜ non testé | — |
| Windows 11 + Hyper-V | amd64 | ⬜ non testé | — |
| Windows + WSL2 (Linux) | amd64 | ⬜ non testé | — |

## Ce qui ne dépend pas de la plateforme

| Élément | Preuve |
|---|---|
| `cloud-init/user-data.yaml` | YAML standard, aucune commande propre à un OS |
| `compose/docker-compose.yml` | Docker Compose v2, portable |
| Images | **toutes multi-arch** (voir ci-dessous) |
| Scripts `.sh` | bash ; Windows via Git Bash ou WSL2 |

### Support des architectures (vérifié par `docker manifest inspect`)

| Image | linux/amd64 | linux/arm64 |
|---|---|---|
| `tecnativa/docker-socket-proxy:v0.5.0` | ✅ | ✅ |
| `traefik:v3.7.15` | ✅ | ✅ |
| `postgres:17.11-alpine` | ✅ | ✅ |
| `quay.io/keycloak/keycloak:26.8.1` | ✅ | ✅ |
| `portainer/portainer-ce:2.45.2` | ✅ | ✅ |
| `erseco/alpine-moodle:v5.3.0` | ✅ | ✅ |
| `n8nio/n8n:1.123.85` | ✅ | ✅ |
| `drupal:10.6.19-php8.4-apache` | ✅ | ✅ |

L'image applicative `cr465/drupal:1.0.0` est **construite localement** (`build:` dans le compose) :
elle est donc produite pour l'architecture de la machine, sans dépendance à un registre.

## Procédure — Windows 11

### Prérequis système

1. **Virtualisation activée dans le BIOS/UEFI** (VT-x ou AMD-V).
2. **Hyper-V activé** : Panneau de configuration → Programmes → Activer ou désactiver des
   fonctionnalités Windows → cocher **Hyper-V** + **Plateforme d'hyperviseur Windows** → redémarrer.
3. **Git pour Windows** (inclut Git Bash).
4. **Multipass** : https://multipass.run/install (installeur Windows).

### Vérification

```bash
# Ouvrir GIT BASH (pas cmd.exe, pas PowerShell)
git --version
multipass version
bash scripts/check-platform.sh
```

Attendu : `Hyper-V : active`, `multipass : OK`, et les 8 images `OK` pour `linux/amd64`.

### Déploiement

```bash
# Depuis Git Bash, à la racine du dépôt
bash scripts/launch-vm.sh
bash scripts/mount-compose.sh      # active les montages privilégiés si nécessaire
cp compose/.env.example compose/.env    # puis renseigner les secrets
bash scripts/deploy-stack.sh
bash scripts/test-routing.sh
```

> Si `mount-compose.sh` demande une élévation : ouvrir **PowerShell en administrateur** et lancer
> `multipass set local.privileged-mounts=true`, puis reprendre.

### Points de vigilance Windows

| Symptôme | Cause | Solution |
|---|---|---|
| `multipass launch` échoue | Hyper-V inactif | activer la fonctionnalité + redémarrer |
| chemins `/opt/...` transformés | Git Bash convertit les chemins | `MSYS_NO_PATHCONV=1` (déjà présent dans les scripts) |
| montage impossible | montages privilégiés désactivés | `multipass set local.privileged-mounts=true` en admin |
| lenteur au démarrage | disque dur mécanique | prévoir 5 à 10 min pour le premier `launch` |

## Procédure — Linux (Ubuntu 24.04, amd64)

```bash
sudo snap install multipass
sudo usermod -aG kvm "$USER"      # sinon multipass ne peut pas démarrer de VM
# se reconnecter, puis :
bash scripts/check-platform.sh
bash scripts/launch-vm.sh
bash scripts/mount-compose.sh
./scripts/deploy-stack.sh
```

> Le groupe `kvm` est la cause d'échec la plus fréquente sur Linux.

## Procédure — macOS

```bash
brew install --cask multipass
bash scripts/check-platform.sh
bash scripts/launch-vm.sh
```

Sur Apple Silicon, Multipass lance une VM **arm64** : c'est le cas déjà validé.

## Ce qu'il faut consigner

Pour chaque plateforme testée, relever :

1. la sortie de `scripts/check-platform.sh` ;
2. la sortie de `multipass info vm-cr465-d` (architecture, ressources) ;
3. la sortie de `docker compose ps` (9 conteneurs `Up`) ;
4. le code HTTP de chaque domaine via `scripts/test-routing.sh` ;
5. une capture d'écran de la boutique et de Moodle.

Ces éléments alimentent la section « tests » du GitBook et la vidéo.

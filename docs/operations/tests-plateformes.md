# Tests de compatibilité par plateforme

> Objectif : démontrer que la plateforme se déploie sur les trois systèmes visés, quel que soit
> le processeur. Chaque ligne doit être **réellement exécutée** avant d'être cochée.

## Matrice de compatibilité

| Plateforme | Architecture | État | Validé par |
|---|---|---|---|
| macOS (Apple Silicon) | arm64 | ✅ testé (Docker local) | Maxime |
| macOS 27 (Apple Silicon) | arm64 | ❌ Multipass bloqué (vmnet) — voir incident | Maxime |
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


## Incident — Multipass inopérant sur macOS 27 (19 octobre 2026)

### Symptôme

`multipass launch` reste bloqué : état `Starting`/`Unknown`, aucune IPv4, `timed out waiting for
response`. Le processus `qemu-system-aarch64` tourne mais consomme **0,0 % de CPU** et n'avance
pas (0,02 s de temps CPU après 8 minutes).

### Diagnostic

Test direct du binaire QEMU fourni par Multipass :

| Commande | CPU après 5 s | Conclusion |
|---|---|---|
| `qemu-system-aarch64 -accel hvf -M virt -m 256 …` | **98,7 %** (6,81 s) | l'accélération matérielle fonctionne |
| idem + `-nic vmnet-shared,…` | **0,0 %** (0,06 s) | **le périphérique réseau bloque le démarrage** |

La cause est donc **`vmnet-shared`** : Multipass utilise `vmnet.framework` pour le réseau partagé,
et cette API ne fonctionne plus avec macOS 27 dans cette version de Multipass (1.16.4).

### Contournements

| Option | Effort | Fidélité |
|---|---|---|
| **Démonstration sur Windows 11 + Hyper-V** | 20 min | ✅ identique (même cloud-init) |
| Démonstration sur Linux (Multipass/snap) | 30 min | ✅ identique |
| Autre outil sur macOS (Lima en `vz`, UTM) | 1 h | ⚠️ ne réutilise pas les scripts du dépôt |
| Attendre une version corrigée de Multipass | inconnu | — |

### Ce qui reste vérifié malgré l'incident

- `cloud-init schema --config-file cloud-init/user-data.yaml` → **Valid schema** (conteneur Ubuntu 24.04)
- stack complète : 9 conteneurs sains, 5 domaines répondant 200/3xx
- toutes les images existent en `amd64` et `arm64`

## Ce qu'il faut consigner

Pour chaque plateforme testée, relever :

1. la sortie de `scripts/check-platform.sh` ;
2. la sortie de `multipass info vm-cr465-d` (architecture, ressources) ;
3. la sortie de `docker compose ps` (9 conteneurs `Up`) ;
4. le code HTTP de chaque domaine via `scripts/test-routing.sh` ;
5. une capture d'écran de la boutique et de Moodle.

Ces éléments alimentent la section « tests » du GitBook et la vidéo.

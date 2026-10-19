# Plateforme pédagogique conteneurisée sécurisée — CR465

Travail de session (Polytechnique Montréal, CR465 Groupe D). Architecture multi-services conteneurisée (Docker Compose) sur une VM Linux provisionnée par cloud-init.

> **Référence** : l'énoncé et les grilles fournis par l'enseignant sont dans `md/`.
> **Notre documentation** : technique dans `docs/`, livrable GitBook dans `gitbook/`.

## État d'avancement

| Couche | État |
|---|---|
| VM as Code (`cloud-init`) | ✅ opérationnelle (SSH durci, UFW, fail2ban, mises à jour auto) |
| Reverse proxy (Traefik) | ✅ opérationnel — HTTPS, redirection, journal JSON |
| Segmentation réseau | ✅ 4 réseaux, `app` et `data` en `internal: true` |
| Durcissement des conteneurs | ✅ `cap_drop: ALL`, non-root, `read_only`, limites, healthcheck |
| socket-proxy | ✅ API Docker en lecture seule |
| Applications métier (Drupal, Moodle, Keycloak, n8n, PostgreSQL, Portainer) | 🔶 à déployer (phase 4) |
| Scan d'images (Trivy) | 🔶 script fourni (`scripts/scan-images.sh`), rapports à produire |

## Pile technique

**Déployé** : Traefik · socket-proxy · service de test `whoami`
**Cible** : Drupal Commerce · Moodle · Keycloak · n8n · PostgreSQL · Portainer CE
**Bonus (non engagés)** : Redis · Grafana/Loki · OpenAppSec (WAF, mode local)

> Le durcissement gVisor est **étudié mais non activé** : le script d'installation existe
> (`scripts/install-gvisor.sh`), mais aucun `runtime: runsc` n'est déclaré dans le compose.
> Ne pas le présenter comme actif.

## Prérequis (poste de dev)

- Git, Multipass, un éditeur. **Docker est installé _dans la VM_** par cloud-init.
- Pour scanner les images : Docker en local (Trivy tourne en conteneur).

## Démarrage rapide

```bash
# 1. Lancer la VM (VM as Code)
./scripts/launch-vm.sh                 # ou : multipass launch 24.04 --cloud-init cloud-init/user-data.yaml

# 2. Configurer les secrets (jamais commités)
cp compose/.env.example compose/.env   # puis remplir compose/.env

# 3. Déployer la stack
./scripts/deploy-stack.sh              # ou : docker compose -f compose/docker-compose.yml up -d

# 4. Vérifier le routage HTTPS
./scripts/test-routing.sh

# 5. Scanner les images (local, hors-ligne)
./scripts/scan-images.sh
```

## Structure du dépôt

| Dossier | Contenu |
|---|---|
| `cloud-init/` | VM as Code (user-data.yaml) |
| `compose/` | services et configurations Docker Compose |
| `docs/architecture/` | schémas (architecture, segmentation, séquences, défense en profondeur) |
| `docs/security/` | sécurité des images, durcissement, rapports de scan |
| `docs/operations/` | procédures et incidents |
| `gitbook/` | documentation GitBook (livrable) |
| `md/` | énoncé et grilles de référence (fournis) |
| `scripts/` | lancement, déploiement, tests, scan d'images |
| `media/` | captures et ressources de la vidéo |

## Équipe et contributions

Voir [`md/Contributions.md`](md/Contributions.md).

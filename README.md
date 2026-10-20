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
| PostgreSQL | ✅ opérationnel — 4 bases + 4 utilisateurs dédiés |
| Keycloak + realm `cr465` | ✅ opérationnel — clients `moodle` et `drupal`, rôles, OIDC vérifié |
| **SSO Moodle ↔ Keycloak** | ✅ **fonctionnel** — bouton Keycloak sur la page de connexion, session Moodle ouverte après authentification |
| Moodle | ✅ opérationnel (Moodle 5.3, installé automatiquement, page de connexion FR) |
| Portainer CE | ✅ opérationnel (accès `admin.<domaine>` restreint par IP) |
| n8n + API Moodle | ✅ opérationnel — webhook → inscription vérifiée |
| Drupal Commerce | ✅ opérationnel — boutique, produit, paiement simulé, webhook n8n |
| Scan d'images (Trivy) | 🔶 script fourni (`scripts/scan-images.sh`), rapports à produire |

## Pile technique

**Déployé** : Traefik · socket-proxy (RO + RW) · PostgreSQL · Keycloak · Moodle · Portainer CE · n8n · Drupal Commerce
**Cible** : — (tous les services sont déployés)
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
./scripts/launch-vm.sh                 # 4 vCPU / 8 Go / 60 Go, Ubuntu 24.04 + cloud-init

# 2. Exposer le dossier compose/ dans la VM  (OBLIGATOIRE)
./scripts/mount-compose.sh             # monte ./compose sur /opt/cr465-groupe-d/compose

# 3. Configurer les secrets (jamais commités)
cp compose/.env.example compose/.env   # puis remplir compose/.env

# 4. Déployer la stack (exécution DANS la VM)
./scripts/deploy-stack.sh

# 5. Vérifier le routage HTTPS
./scripts/test-routing.sh

# 6. Scanner les images (local, hors-ligne)
./scripts/scan-images.sh
```

> Le déploiement tourne **dans la VM**, pas sur le poste de dev : `deploy-stack.sh` passe par
> `multipass exec`. Docker n'est donc pas requis localement, sauf pour le scan Trivy.

### Compatibilité des postes de dev

| Système | Prérequis |
|---|---|
| macOS | Multipass, Git. Scripts exécutables directement. |
| Linux | Multipass, Git, bash. Scripts exécutables directement. |
| Windows | Multipass, Git **avec Git Bash** (ou WSL2). Lancer les scripts depuis Git Bash, pas depuis `cmd`. |

## Structure du dépôt

| Dossier | Contenu |
|---|---|
| `cloud-init/` | VM as Code (user-data.yaml) |
| `compose/` | services et configurations Docker Compose |
| `docs/architecture/` | schémas (architecture, segmentation, séquences, défense en profondeur) |
| `docs/security/` | sécurité des images, durcissement, rapports de scan |
| `docs/operations/` | ordre de déploiement, procédure SSO, incidents |
| `gitbook/` | documentation GitBook (livrable) |
| `md/` | énoncé et grilles de référence (fournis) |
| `scripts/` | lancement, déploiement, tests, scan d'images |
| `media/` | captures et ressources de la vidéo |

## Équipe et contributions

Voir [`md/Contributions.md`](md/Contributions.md).

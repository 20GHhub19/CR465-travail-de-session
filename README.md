# Plateforme pédagogique conteneurisée sécurisée — CR465

Travail de session (Polytechnique Montréal, CR465). Architecture multi-services
conteneurisée (Docker Compose) sur une VM Linux provisionnée par cloud-init.

> **Référence** : l'énoncé et les grilles fournis par l'enseignant sont dans `md/`.
> **Notre documentation** : technique dans `docs/`, livrable GitBook dans `gitbook/`.

## Pile technique
Traefik · Drupal Commerce · Moodle · Keycloak · n8n · PostgreSQL
· Portainer CE · (bonus : Redis, Grafana/Loki, OpenAppSec) · durcissement gVisor.

## Prérequis (poste de dev)
- Git, Multipass, un éditeur. **Docker est installé _dans la VM_** par cloud-init.

## Démarrage rapide
```bash
# 1. Lancer la VM (VM as Code)
multipass launch 24.04 --name plateforme --cpus 4 --memory 8G --disk 60G \
  --cloud-init cloud-init/user-data.yaml

# 2. Configurer les secrets (jamais commités)
cp compose/.env.example compose/.env   # puis remplir compose/.env

# 3. Déployer la stack
docker compose -f compose/docker-compose.yml up -d
```

## Structure du dépôt
| Dossier | Contenu |
|---|---|
| `cloud-init/` | VM as Code (user-data.yaml) |
| `compose/` | services et configurations Docker Compose |
| `docs/` | architecture, sécurité, opérations, tests |
| `gitbook/` | documentation GitBook (livrable) |
| `md/` | énoncé et grilles de référence (fournis) |
| `scripts/` | scripts de démarrage et de validation |
| `media/` | captures et ressources de la vidéo |

## Équipe et contributions
Voir `md/Contributions.md`.

| Membre | Rôle | Branche |
|---|---|---|
| (vous) | Coordination + Architecture | Projet-CR465-D-Gaius |
| … | … | … |

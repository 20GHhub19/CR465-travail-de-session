# Sécurité des images

> Critère de la grille : versions explicites, choix justifiés, **scan local** (sans service cloud).

## 1. Images retenues et justification

| Image | Version épinglée | Source | Justification |
|---|---|---|---|
| `traefik` | `v3.7.15` | Docker Official Image | Reverse proxy maintenu ; version de correctif figée (pas de `v3.3` flottant, pas de `latest`). v3.7 est la première ligne négociant correctement l'API Docker ≥ 1.40 |
| `tecnativa/docker-socket-proxy` | `v0.5.0` | Projet communautaire largement utilisé | Filtre l'API Docker en lecture seule : évite de monter le socket brut |

**Règles appliquées**

1. Aucune image en `latest` (l'ancienne configuration utilisait une image de test sans tag = `latest`).
2. Version **de correctif** plutôt que de ligne mineure : `v3.7.15` et non `v3.7`.
3. Images officielles ou d'éditeur de confiance, pas d'image « random » non maintenue.

**Amélioration possible (non bloquante)** : épingler par digest (`image: traefik:v3.3.7@sha256:…`)
pour garantir l'immuabilité absolue du binaire récupéré.

## 2. Scan local des images

Aucun service cloud n'est utilisé : le scan tourne **localement**, dans un conteneur Trivy.

```bash
# depuis la racine du dépôt
./scripts/scan-images.sh
```

Le script :

1. lit les images réellement déclarées dans `compose/docker-compose.yml` (`docker compose config --images`) ;
2. lance `aquasec/trivy:0.76.0` en local sur chaque image ;
3. écrit un rapport par image dans `docs/security/scans/<image>.txt` ;
4. se limite aux vulnérabilités **HIGH et CRITICAL** (bruit maîtrisé).

Scanner une image précise :

```bash
./scripts/scan-images.sh traefik:v3.3.7
```

## 3. Comment lire un rapport

| Colonne | Signification |
|---|---|
| `Library` | Paquet concerné dans l'image |
| `Vulnerability` | Identifiant CVE |
| `Severity` | HIGH / CRITICAL |
| `Fixed Version` | Version corrigée — **si la colonne est vide, aucun correctif n'existe encore** |

**Ce qu'on attend d'un travail de session** : montrer le scan, identifier les vulnérabilités
corrigeables, et décider (mise à jour de l'image, ou acceptation du risque documentée).
Il n'est pas exigé d'obtenir zéro vulnérabilité : les images de base en contiennent toujours.

## 4. Limites assumées

- Le scan porte sur les images **de base**, pas sur les dépendances applicatives ajoutées
  plus tard (Drupal, Moodle) : à relancer après chaque ajout de service.
- Trivy télécharge sa base de vulnérabilités au premier lancement (mise en cache locale) :
  le scan est local, mais la base doit être à jour pour être pertinente.

## 5. Compatibilité API Docker (incident rencontré)

Traefik `v3.3` négocie l'API Docker **1.24**, refusée par les moteurs récents
(minimum **1.40** depuis Docker 25+). Symptôme : `API returned a 400 (Bad Request)` et
aucun routeur créé, alors que le proxy répond.

Correctif retenu : **Traefik `v3.7.15`**, qui négocie l'API 1.44. Le `drop-in`
`DOCKER_MIN_API_VERSION=1.24` du cloud-init devient inutile (il est conservé pour les
moteurs anciens, sans effet sur les récents).

Détail complet : [`docs/operations/incident-api-docker.md`](../operations/incident-api-docker.md).

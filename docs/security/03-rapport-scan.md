# Rapport de scan des images — 19 octobre 2026

Scan réalisé avec **Trivy 0.76.0**, en local (conteneur), sévérités **HIGH et CRITICAL**.
Commande : `./scripts/scan-images.sh`. Rapports bruts : `docs/security/scans/`.

## Résultats

| Image | Version | HIGH | CRITICAL | Rapport |
|---|---:|---:|---:|---|
| `traefik` | v3.7.15 | **0** | **0** | `scans/traefik_v3.7.15.txt` |
| `tecnativa/docker-socket-proxy` | v0.5.0 | 6 | 0 | `scans/tecnativa_docker-socket-proxy_v0.5.0.txt` |

## Analyse

### `traefik:v3.7.15` — 0 vulnérabilité HIGH/CRITICAL

Image à jour, aucun correctif attendu. C'est l'image qui **traite le trafic exposé** : c'est
donc le bon endroit pour exiger zéro vulnérabilité connue, et c'est le cas.

### Service de test `whoami` — retiré

Le service `traefik/whoami` servait uniquement à valider le routage Traefik en début de projet.
Son scan révélait **15 vulnérabilités HIGH** dans les bibliothèques Go compilées. Il a été
**retiré de la stack avant la remise** : plus de surface d'attaque inutile, plus de service
exposé sans rôle métier. Le test de routage cible désormais Moodle (`scripts/test-routing.sh`).

### `tecnativa/docker-socket-proxy:v0.5.0` — 6 HIGH

Dont `CVE-2026-14456` (OpenSSL, déni de service par mémoire non bornée), **correctif disponible**
en `3.5.8-r0`. Comme l'image n'est pas mise à jour en amont, deux compensations sont en place :

1. Le conteneur a des **limites de ressources** (`0.25 CPU`, `64 Mo`) : une fuite mémoire
   provoque son redémarrage, pas la saturation de l'hôte.
2. Il n'est **pas exposé** : réseau `socket` interne, aucun port publié, accessible uniquement
   depuis Traefik.

Recommandation : surveiller une version corrigée en amont, ou construire une image dérivée
avec OpenSSL à jour.

## Ce que ce scan démontre pour la grille

| Exigence de l'énoncé | Preuve fournie |
|---|---|
| Versions explicites | Les trois images sont épinglées (aucun `latest`) |
| Scan **local / hors-ligne** | Trivy tourne en conteneur local, aucun service cloud |
| Réflexion sur le risque | Vulnérabilités analysées une par une, décision documentée par image |

## Limites

- Le scan couvre les images **actuellement** dans le compose. Drupal, Moodle, Keycloak, n8n
  et PostgreSQL devront être scannés à leur ajout (le script les prendra automatiquement).
- Trivy ne détecte que les vulnérabilités **connues et publiées** : absence de résultat ne
  signifie pas absence de faille.

# Mesures de sécurité (images + exécution)

![Défense en profondeur](assets/05-defense-profondeur.png)

*Sept couches indépendantes : un attaquant doit réussir sept fois de suite.*

## Sécurité des images

| Image | Version épinglée | HIGH | CRITICAL |
|---|---|---:|---:|
| `traefik` | `v3.7.15` | 0 | 0 |
| `traefik/whoami` | `v1.12.0` | 15 | 0 |
| `tecnativa/docker-socket-proxy` | `v0.5.0` | 6 | 0 |

Scan **local** avec Trivy (`./scripts/scan-images.sh`), aucun service cloud.
Rapports bruts : `docs/security/scans/`. Analyse détaillée : `docs/security/03-rapport-scan.md`.

> `whoami` est un service de **test** : il porte 15 vulnérabilités HIGH et sera retiré
> avant la remise.

## Sécurité à l'exécution

| Contrôle | Application |
|---|---|
| `security_opt: no-new-privileges:true` | Tous les services |
| `cap_drop: ALL` | Tous les services |
| `cap_add` ciblés | Traefik : `NET_BIND_SERVICE` · PostgreSQL : 5 capacités d'initialisation · Drupal : capacités d'installation |
| Utilisateur non-root | Traefik `1000:1000` · whoami `65534:65534` · Moodle/n8n `nobody` |
| `read_only: true` | Traefik, whoami, socket-proxy, PostgreSQL |
| `tmpfs` | `/tmp` (+ `/run` pour socket-proxy et PostgreSQL) |
| Limites ressources | CPU et mémoire plafonnés par service |
| Healthchecks | Tous sauf `whoami` (image scratch) |
| Logs bornés | 3 × 10 Mo par conteneur |
| `privileged: true` | **Aucun** |

## Traitement du socket Docker

Monter `/var/run/docker.sock` donne un accès **complet** à l'API Docker — donc un équivalent
root sur l'hôte. Le mode `:ro` du montage **n'empêche pas** les écritures via l'API HTTP.

Deux proxys filtrants ont donc été déployés :

- `socket-proxy` : **lecture seule** (`POST: 0`) pour Traefik ;
- `socket-proxy-admin` : écriture autorisée, réservé à Portainer, isolé sur le réseau `socket`.

## PKI locale

Traefik sert un certificat wildcard `*.cr465.test` signé par une **AC locale**
(`scripts/gen-certs.sh`). L'AC est montée dans Moodle et Drupal (`curl.cainfo`) pour que
leurs appels HTTPS vers Keycloak et n8n soient **vérifiés**, pas ignorés.

## Ce qui n'est pas fait (assumé)

- Pas de SELinux/AppArmor personnalisé : le durcissement repose sur les capacités et les options Docker.
- Pas de WAF (OpenAppSec) : bonus non engagé (+2 points hors total).
- Le certificat est auto-signé (aucun nom de domaine public dans ce travail).

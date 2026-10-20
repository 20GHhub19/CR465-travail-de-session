# Architecture réelle déployée

> Cette page décrit ce qui **tourne réellement**, pas une cible théorique.

## Vue d'ensemble

![Architecture générale](../assets/01-architecture-generale.png)

*Les schémas détaillés et leurs sources Mermaid sont dans `docs/architecture/`.*

## Les neuf services

| Service | Image (épinglée) | Rôle | Réseaux |
|---|---|---|---|
| `traefik` | `traefik:v3.7.15` | Point d'entrée HTTPS, routage | edge, app, socket |
| `socket-proxy` | `tecnativa/docker-socket-proxy:v0.5.0` | API Docker en **lecture seule** pour Traefik | socket |
| `socket-proxy-admin` | idem | API Docker en écriture, réservé à Portainer | socket |
| `postgres` | `postgres:17.11-alpine` | Base unique, 4 bases logiques | data |
| `keycloak` | `quay.io/keycloak/keycloak:26.8.1` | Identité, SSO OIDC | app, data |
| `moodle` | `erseco/alpine-moodle:v5.3.0` | LMS, consommation des cours | app, data, egress |
| `n8n` | `n8nio/n8n:1.123.85` | Orchestration | app, data, egress |
| `drupal` | `cr465/drupal:1.0.0` (dérivée) | Boutique Commerce | app, data, egress |
| `portainer` | `portainer/portainer-ce:2.45.2` | Exploitation graphique | app, socket |

## Domaines

| Domaine | Service |
|---|---|
| `shop.cr465.test` | Drupal Commerce |
| `lms.cr465.test` | Moodle |
| `auth.cr465.test` | Keycloak |
| `flow.cr465.test` | n8n |
| `admin.cr465.test` | Portainer (restreint par IP) |

## Choix structurants

- **Une seule base PostgreSQL**, avec une base et un utilisateur dédiés par service :
  compromettre Moodle ne donne pas accès aux données de Drupal ou Keycloak.
- **Traefik ne voit jamais le socket Docker** : il passe par un proxy filtrant en lecture seule.
- **Le TLS est terminé par Traefik** ; Keycloak et Moodle reçoivent du HTTP sur le réseau interne.
- **Un réseau `egress` séparé** : seuls Moodle (dépendances) et n8n/Drupal (webhooks) sortent.

## Diagrammes disponibles

| Fichier | Contenu |
|---|---|
| `docs/architecture/01-architecture-generale.png` | Vue d'ensemble, flux numérotés |
| `docs/architecture/02-segmentation-reseau.png` | 5 réseaux, flux interdits |
| `docs/architecture/03-sequence-integration.png` | Séquence d'achat → inscription |
| `docs/architecture/04-sequence-sso.png` | Flux OIDC Moodle ↔ Keycloak |
| `docs/architecture/05-defense-profondeur.png` | 7 couches de protection |

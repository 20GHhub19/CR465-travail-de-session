# Segmentation réseau

![Segmentation réseau](assets/02-segmentation-reseau.png)

## Les cinq réseaux

| Réseau | Type | Services | Règle |
|---|---|---|---|
| `cr465_edge` | bridge | Traefik | Seul réseau avec des ports publiés (80/443) |
| `cr465_app` | `internal: true` | Traefik, Drupal, Moodle, Keycloak, n8n, Portainer, whoami | Aucune sortie Internet |
| `cr465_data` | `internal: true` | PostgreSQL, Keycloak, Moodle, n8n, Drupal | Jamais exposé, jamais routé |
| `cr465_socket` | `internal: true` | Traefik ↔ socket-proxy, Portainer ↔ socket-proxy-admin | Accès API Docker isolé |
| `cr465_egress` | bridge | Moodle, n8n, Drupal | **Sortie Internet contrôlée** |

## Flux autorisés

```
Internet → Traefik (443)
Traefik  → Drupal / Moodle / Keycloak / n8n / Portainer (réseau app)
Services → PostgreSQL (réseau data)
Drupal   → n8n (webhook d'achat)
n8n      → Moodle (API REST d'inscription)
Moodle   → Keycloak (OIDC)
```

## Flux volontairement interdits

1. **Internet → PostgreSQL / Keycloak (admin) / n8n** : aucun port publié.
2. **Traefik → PostgreSQL** : le proxy n'a aucune route vers la base.
3. **Service applicatif → Internet hors `egress`** : `app` est `internal: true`.
4. **Traefik → socket Docker brut** : passage obligé par `socket-proxy` (lecture seule).
5. **Portainer hors liste d'IP autorisées** : middleware `ipallowlist` sur `admin.<domaine>`.

## Pourquoi un réseau `egress`

Moodle télécharge ses dépendances Composer à l'installation et n8n/Drupal appellent des
webhooks. Plutôt que d'ouvrir le réseau applicatif, un réseau dédié a été créé et rattaché
**uniquement** à ces trois services. C'est une exception explicite, pas un oubli.

## Vérification

```bash
docker network inspect cr465_app --format '{{.Options.internal}}'   # attendu : true
docker network inspect cr465_data --format '{{.Options.internal}}'  # attendu : true
docker ps --format '{{.Names}}	{{.Ports}}'                          # seuls 80/443 publiés
```

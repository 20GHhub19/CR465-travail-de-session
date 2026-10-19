# Observabilité

## Portainer CE — obligatoire

`portainer/portainer-ce:2.45.2`, accessible sur `https://admin.cr465.test`, derrière Traefik
avec **restriction par liste d'IP** (`ADMIN_ALLOWLIST`).

Il permet de montrer, en démonstration :

- l'état des 9 conteneurs et leur santé ;
- les réseaux, volumes et images ;
- les **journaux** d'un conteneur (ex. : `cr465-drupal` lors d'un achat) ;
- le détail d'un conteneur (capacités, utilisateur, montages) pour illustrer le durcissement.

> Portainer a besoin d'**écrire** dans l'API Docker : il utilise `socket-proxy-admin`,
> une instance séparée du proxy en lecture seule utilisé par Traefik.

## Journaux

| Source | Configuration |
|---|---|
| Traefik | `accessLog` en **JSON**, en-têtes supprimés (`defaultmode: drop`) |
| Docker (tous les services) | rotation 3 × 10 Mo |
| Drupal | log du module `cr465_notify` (notification n8n, échecs) |
| n8n | historique d'exécution des workflows (base PostgreSQL) |

L'`accessLog` JSON est le point de départ naturel d'une agrégation Loki/Grafana.

## Diagnostic démontrable

Deux scénarios crédibles à montrer en vidéo :

1. **Achat réussi** : commande Drupal créée → log `cr465_notify` « notifiee a n8n (HTTP 200) »
   → exécution n8n verte → ligne d'inscription dans Moodle.
2. **Webhook en échec** : arrêt de n8n → nouveau passage de commande → log Drupal en erreur
   (`cURL error`), aucune inscription Moodle. Le diagnostic se fait dans Portainer.

## Non implémenté

- **Grafana + Loki** : bonus non déployé (temps consacré à la stabilisation du cœur).
- Aucun tableau de bord de métriques (Prometheus) : hors périmètre pédagogique.
- Pas d'alerting automatique.

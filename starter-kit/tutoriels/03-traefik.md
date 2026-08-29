# 03 — Traefik : comprendre et étendre la stack

## Ce que fait `compose/docker-compose.yml`

- **Réseau `edge`** : réseau Docker dédié à l'exposition, nommé explicitement — le début d'une
  segmentation réseau (à compléter avec des réseaux `app` et `data` séparés au fil du projet).
- **`traefik`** : le reverse proxy, seul point d'entrée exposé sur le port 80. Le socket Docker est
  monté en lecture seule (`:ro`), et `no-new-privileges` est activé.
- **`whoami`** : un service de test minimal (image officielle `traefik/whoami`) qui répond avec des
  informations sur la requête reçue — utile pour valider que Traefik route correctement le trafic.

## Pourquoi le tableau de bord Traefik n'est pas exposé

Le tableau de bord (`--api.dashboard`) est volontairement omis : c'est un exemple concret
d'exposition minimale (un des principes de segmentation attendus dans l'énoncé). Si vous voulez
l'activer pour du débogage local, faites-le sur un port lié à `127.0.0.1` uniquement, jamais sur
une interface publique.

## Tester que ça fonctionne

```
task up
curl http://<IP_DE_LA_VM>/whoami
```

Vous devriez voir les informations de la requête (hostname du conteneur, IP, en-têtes HTTP).

## Ajouter votre propre service derrière Traefik

Chaque nouveau service a besoin de deux éléments : être sur le réseau `edge` (ou un réseau
supplémentaire relié à `edge` si vous segmentez davantage), et porter les labels Traefik :

```yaml
  mon-service:
    image: mon-image:1.0.0
    networks:
      - edge
    security_opt:
      - no-new-privileges:true
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.mon-service.rule=PathPrefix(`/mon-service`)"
      - "traefik.http.services.mon-service.loadbalancer.server.port=<PORT_INTERNE>"
```

Remplacez le service `whoami` par vos propres services au fur et à mesure — il n'est là que pour
valider le câblage de base.

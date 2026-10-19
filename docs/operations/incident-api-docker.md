# Incident — incompatibilité API Docker / Traefik

## Symptômes

- Le service de test (aujourd'hui retiré) renvoyait **404 page not found** — réponse de Traefik lui-même.
- La redirection HTTP → HTTPS fonctionne (301), donc Traefik tourne.
- Journaux Traefik :
  ```
  ERR Failed to retrieve information of the docker client and server host
      error="Error response from daemon: API returned a 400 (Bad Request) but provided no error-message"
      providerName=docker
  ```
- Journaux du socket-proxy (niveau debug) :
  ```
  "GET /v1.24/version HTTP/1.1" 400
  ```

## Cause

Traefik **v3.3** (et antérieurs) négocie l'API Docker en **1.24**. Les moteurs récents
(Docker **25+**, ici 29.8.2) imposent un minimum de **1.40** :

```
{"message":"client version 1.24 is too old. Minimum supported API version is 1.40"}
```

Résultat : le client Docker de Traefik ne peut pas lire la liste des conteneurs, donc aucun
routeur n'est créé — le proxy répond 404 alors qu'il est en bonne santé.

Le `drop-in` `DOCKER_MIN_API_VERSION=1.24` ajouté par le cloud-init compensait sur les
moteurs anciens, mais n'a plus d'effet sur les versions récentes.

## Diagnostiquer

```bash
# 1. la requête réellement émise par Traefik
docker compose -p cr465test --env-file compose/.env.example up -d
docker logs cr465-socket-proxy --since 30s 2>&1 | grep -oE '"GET [^"]+"' | sort | uniq -c

# 2. la réponse du moteur pour cette version d'API
docker run --rm --network cr465test_socket curlimages/curl:8.10.1 \
  -s "http://socket-proxy:2375/v1.24/containers/json"
# -> client version 1.24 is too old
```

## Résolution

1. Passer l'image Traefik à **`v3.7.15`** (ligne 3.7, qui négocie l'API 1.44).
2. Recréer le conteneur : `docker compose up -d --force-recreate traefik`.
3. Vérifier que le proxy reçoit bien des requêtes en `/v1.44/...` et que le routage répond.

> ⚠️ Le paramètre `--providers.docker.apiVersion` **n'existe pas** en Traefik v3 :
> il provoque `field not found, node: apiVersion` au démarrage. Ne pas l'ajouter.

## Leçon

Une version d'image « stable » n'est pas une version **compatible** : le couple
client Docker (Traefik) / moteur (Docker Engine) doit être vérifié. Le symptôme (404 alors que
le proxy est sain) oriente à tort vers une erreur de labels ou de réseau.

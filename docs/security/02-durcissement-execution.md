# Durcissement à l'exécution

> Critère de la grille (5 points) : non-root, absence de mode privilégié, réduction des
> privilèges, `security_opt`, limites de ressources, montages prudents, healthchecks.

## 1. Contrôles et emplacement dans le code

| Contrôle | Où il est appliqué | Effet |
|---|---|---|
| `security_opt: no-new-privileges:true` | bloc commun `x-durcissement` (tous les services) | Un binaire `setuid` ne peut pas élever ses privilèges |
| `cap_drop: ALL` | bloc commun `x-durcissement` | Toutes les capacités Linux retirées par défaut |
| `cap_add: NET_BIND_SERVICE` | `traefik` uniquement | Seule capacité nécessaire pour ouvrir les ports 80/443 |
| `user: "1000:1000"` | `traefik` | Processus non-root |
| `user: "65534:65534"` | `whoami` | Exécution en `nobody` |
| `read_only: true` | `traefik`, `whoami`, `socket-proxy`, `postgres` | Système de fichiers du conteneur en lecture seule |
| `cap_add` ciblés | `postgres` : `CHOWN`, `DAC_OVERRIDE`, `FOWNER`, `SETGID`, `SETUID` | Nécessaires à l'entrypoint PostgreSQL pour préparer le volume |
| Écart assumé : `read_only` absent | `keycloak` | Au premier démarrage, Keycloak reconstruit sa configuration Quarkus dans `/opt/keycloak/lib` : le système de fichiers doit être inscriptible. Compensé par un utilisateur non-root et un volume dédié |
| `tmpfs: /tmp` | `traefik` | Zone d'écriture temporaire, non persistante |
| `deploy.resources.limits` | tous les services | Plafond CPU / mémoire : limite l'impact d'un déni de service |
| `healthcheck` | `traefik` | Redémarrage/diagnostic automatisable |
| `logging` borné (3 × 10 Mo) | tous les services | Empêche la saturation du disque par les journaux |
| Aucun `privileged: true` | — | Vérifié : aucun service n'est privilégié |

## 2. Traitement du socket Docker

**Problème** : monter `/var/run/docker.sock` dans un conteneur donne un accès **complet** à
l'API Docker — donc, de fait, un équivalent root sur l'hôte. Le mode `:ro` du montage
**n'empêche pas** les écritures effectuées via l'API HTTP.

**Solution appliquée** : un `docker-socket-proxy` en lecture seule entre Traefik et le socket.

```
Traefik --(tcp://socket-proxy:2375)--> socket-proxy --(:ro)--> /var/run/docker.sock
```

Avec `POST: 0`, toute tentative de création, modification ou suppression de conteneur
depuis Traefik est refusée.

## 3. Risques résiduels assumés

| Risque | Pourquoi il reste | Compensation |
|---|---|---|
| L'utilisateur `adminops` est dans le groupe `docker` | Nécessaire pour piloter Docker sans `sudo` | Compte à clé SSH uniquement, root SSH désactivé, fail2ban |
| `socket-proxy` garde un accès en lecture à l'API | Traefik en a besoin pour découvrir les conteneurs | Écriture désactivée (`POST: 0`), réseau `socket` isolé |
| `whoami` n'a pas de healthcheck | Image `scratch` : aucun binaire interne pour tester | Healthcheck Traefik + `scripts/test-routing.sh` |
| Certificat TLS auto-signé | Pas de nom de domaine public dans ce travail | Documenté ; remplaçable par Let's Encrypt en production |
| Keycloak non `read_only` | Reconstruction Quarkus au premier démarrage | Utilisateur non-root, volume dédié, limites de ressources |

## 4. Vérifications rapides

```bash
# aucun conteneur privilegie
docker compose -f compose/docker-compose.yml config | grep -c "privileged: true"   # attendu : 0

# capacites réellement accordées
docker inspect cr465-traefik --format '{{.HostConfig.CapDrop}} / {{.HostConfig.CapAdd}}'

# utilisateur effectif
docker exec cr465-traefik id

# système de fichiers en lecture seule
docker inspect cr465-traefik --format '{{.HostConfig.ReadonlyRootfs}}'
```

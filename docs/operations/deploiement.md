# Déploiement de la stack

## Ordre des opérations

```
1. VM as Code      ./scripts/launch-vm.sh
2. Secrets         cp compose/.env.example compose/.env  puis remplir
3. Realm SSO       ./scripts/render-keycloak-realm.sh
4. Stack           ./scripts/deploy-stack.sh
5. Vérification    ./scripts/test-routing.sh
6. Scan images     ./scripts/scan-images.sh
```

## Pourquoi l'étape 3 existe

Keycloak importe un realm depuis un fichier JSON, mais **ne sait pas lire les variables
d'environnement**. Un realm contenant un secret en clair ne peut donc pas être versionné.

Solution retenue :

| Fichier | Versionné ? | Contenu |
|---|---|---|
| `compose/keycloak/import/realm-cr465.template.json` | ✅ oui | Realm complet, secrets remplacés par des placeholders |
| `compose/keycloak/import/realm-cr465.json` | ❌ **non** (`.gitignore`) | Realm réel, secrets injectés depuis `.env` |
| `compose/.env` | ❌ **non** | Tous les secrets |

`scripts/render-keycloak-realm.sh` fait l'injection et **échoue** si un placeholder subsiste.

## Ce que le realm contient

| Élément | Valeur |
|---|---|
| Realm | `cr465` |
| Rôles | `etudiant`, `enseignant` |
| Client `moodle` | confidentiel, Authorization Code + PKCE (S256), redirect `https://lms.cr465.test/admin/oauth2callback.php` |
| Client `drupal` | confidentiel, même flow (bonification SSO côté boutique) |
| Politique de mot de passe | 12 caractères minimum, ni le login ni l'email |
| Anti-bruteforce | 5 échecs → verrouillage progressif (max 15 min) |
| Sessions | jeton 5 min, session inactive 30 min |

## Vérifications après déploiement

```bash
# tous les services sains
docker compose -f compose/docker-compose.yml ps

# découverte OIDC à travers Traefik (doit renvoyer un JSON)
curl -k --resolve auth.cr465.test:443:<IP_VM> \
  https://auth.cr465.test/realms/cr465/.well-known/openid-configuration

# rôles et clients réellement importés
docker exec cr465-keycloak /opt/keycloak/bin/kcadm.sh config credentials \
  --server http://localhost:8080 --realm master --user admin --password '<KC_ADMIN_PASSWORD>'
docker exec cr465-keycloak /opt/keycloak/bin/kcadm.sh get clients -r cr465 --fields clientId
docker exec cr465-keycloak /opt/keycloak/bin/kcadm.sh get roles -r cr465 --fields name
```

## Procédure de réinitialisation

Le realm n'est importé qu'au **premier** démarrage (volume `keycloak_data` vide).
Pour repartir de zéro :

```bash
docker compose -f compose/docker-compose.yml down -v   # supprime les volumes
./scripts/render-keycloak-realm.sh
docker compose -f compose/docker-compose.yml up -d
```

> ⚠️ `down -v` efface aussi les données PostgreSQL : à ne jamais faire sur un
> environnement qui contient des données à conserver.

## Limites connues

- Le realm importé n'inclut **aucun utilisateur** : les comptes sont créés par le parcours
  d'achat (n8n) ou par le premier login SSO. Ne jamais committer de mot de passe utilisateur.
- Keycloak reconstruit sa configuration Quarkus au premier démarrage : le conteneur
  tourne donc **sans `read_only`** (écart assumé, voir `docs/security/02-durcissement-execution.md`).

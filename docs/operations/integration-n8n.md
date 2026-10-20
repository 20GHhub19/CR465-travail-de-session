# Intégration n8n → Moodle (attribution d'accès après commande)

## Principe

```
Drupal (achat) --POST webhook--> n8n --API REST--> Moodle (creation du compte + inscription)
```

Le workflow compte cinq nœuds :

| Nœud | Rôle |
|---|---|
| Webhook commande | reçoit `{order_id, email, total, currency, store}` |
| Creer utilisateur Moodle | `core_user_create_users` — le compte est créé s'il n'existe pas (`auth=oauth2`, `username = email`) |
| Chercher utilisateur Moodle | `core_user_get_users_by_field` sur `username` = email |
| Inscrire au cours | `enrol_manual_enrol_users` (rôle étudiant, cours `CR465-DEMO`) |
| Reponse | renvoie `{"status":"enrolled","email":…}` |

Le nœud de création porte `onError: continueRegularOutput` : si le compte existe déjà, Moodle
renvoie une exception, le workflow continue et retrouve l'utilisateur à l'étape suivante.
Le parcours est donc **idempotent** — un second achat pour le même email ne crée pas de doublon.

En attendant le branchement de Drupal, le webhook se teste directement :

```bash
curl -k -X POST https://flow.cr465.test/webhook/commande \
  -H "Content-Type: application/json" \
  -d '{"email":"etudiant1@cr465.test","order_id":"CMD-0001"}'
```

Réponse attendue :

```json
{"status":"enrolled","email":"etudiant1@cr465.test","result":{}}
```

## Mise en place

```bash
./scripts/configure-moodle-webservice.sh   # cree le service web + le jeton
./scripts/render-n8n-workflow.sh           # injecte URL et jeton dans le workflow
docker compose -f compose/docker-compose.yml up -d n8n
docker exec -u node cr465-n8n n8n import:workflow --input=/workflows/commande-moodle.json
docker exec -u node cr465-n8n n8n update:workflow --all --active=true
docker compose -f compose/docker-compose.yml up -d --force-recreate n8n
```

> ⚠️ L'activation ne prend effet qu'après un **redémarrage** de n8n.
> Si vous réimportez plusieurs fois, **supprimez les anciens workflows** : deux workflows
> actifs avec le même chemin de webhook entrent en conflit et c'est l'ancien qui répond.

## Le compte de service Moodle (moindre privilège)

`scripts/configure-moodle-webservice.sh` crée :

| Élément | Détail |
|---|---|
| Service externe | `cr465`, protocole REST |
| Fonctions | `core_user_get_users_by_field`, `core_user_create_users`, `core_course_get_courses`, `core_course_get_enrolled_users`, `enrol_manual_enrol_users`, `core_webservice_get_site_info` |
| Compte | `svc-n8n`, authentification `webservice` (aucun mot de passe) |
| Rôle | `servicen8n` : `enrol/manual:enrol`, `moodle/role:assign`, `moodle/user:viewalldetails`, `moodle/user:create`, `webservice/rest:use` |
| Jeton | permanent, stocké dans `compose/.env` (jamais versionné) |

Aucun accès administrateur : le compte ne peut qu'inscrire des utilisateurs.

## Trois pièges rencontrés (et leur solution)

### 1. `wsaccessusernologin`

Un compte avec `auth = nologin` est **refusé** par l'API. Solution : activer le plugin
`auth_webservice` et affecter ce mode d'authentification au compte de service.

### 2. `wsusercannotassign`

Même avec `moodle/role:assign`, l'attribution échoue si la **matrice « Allow role
assignments »** n'autorise pas le rôle technique à attribuer le rôle `student`.
Solution : insérer une ligne dans `role_allow_assign` (fait par le script).

### 3. Recherche par email impossible

`core_user_get_users_by_field` filtre les résultats sur les champs réellement retournés :
l'email n'est pas exposé par défaut, donc une recherche `field=email` renvoie `[]`.
Solution : rechercher par **`username`** (le SSO provisionne `username = email`) et
ajouter `moodle/user:viewalldetails` au rôle.

## Sécurité

| Mesure | Détail |
|---|---|
| Jeton hors du dépôt | Généré localement, injecté dans le workflow par `render-n8n-workflow.sh`, fichier généré ignoré par Git |
| Compte dédié | `svc-n8n`, sans mot de passe, rôle limité |
| Exposition | n8n accessible uniquement via Traefik (`flow.cr465.test`) |
| Réseau | n8n sur `app` + `data` + `egress`, jamais exposé directement |

## Piège supplémentaire — référence d'expression après un nœud HTTP

Le nœud de recherche lisait `$json.body.email`. Tant qu'il suivait directement le webhook, cela
fonctionnait ; après l'insertion du nœud de création, `$json` désigne la réponse de Moodle et
`body.email` n'existe plus → Moodle répondait `invalid_parameter_exception` et **aucune
inscription n'était créée**, sans que le workflow ne signale d'erreur.

Règle : référencer explicitement le nœud source, jamais `$json` quand l'entrée a changé.

```
={{ $('Webhook commande').item.json.body.email }}
```

## Limites actuelles

- **Création d'utilisateur** : le workflow échoue si l'email n'existe pas encore dans Moodle.
  Le parcours prévu (schéma 3) prévoit un appel à `core_user_create_users` en amont —
  à ajouter comme nœud conditionnel.
- **Signature du webhook** : le webhook n'est pas encore signé (HMAC). À ajouter côté
  Drupal et vérifier dans n8n.
- **Idempotence** : un webhook rejoué renverra « already enrolled » (Moodle lève une
  exception). Prévoir un test préalable avec `core_course_get_enrolled_users`.

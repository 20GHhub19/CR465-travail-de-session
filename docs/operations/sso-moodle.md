# SSO Moodle ↔ Keycloak — procédure et choix techniques

## Résultat attendu

1. La page de connexion Moodle affiche un bouton **Keycloak**.
2. Un clic redirige vers la page de connexion Keycloak (thème du realm `cr465`).
3. Après authentification, l'utilisateur revient sur Moodle **connecté** (`/my/`).

## Mise en place

```bash
./scripts/gen-certs.sh              # AC locale + certificat wildcard
./scripts/render-keycloak-realm.sh  # realm avec les secrets
docker compose -f compose/docker-compose.yml up -d
./scripts/configure-moodle-sso.sh   # branche le fournisseur OIDC dans Moodle
```

`configure-moodle-sso.sh` est **idempotent** : le relancer met à jour le fournisseur
au lieu d'en créer un second.

## Les quatre difficultés rencontrées (et leur solution)

### 1. Traefik n'utilisait qu'un certificat auto-signé interne

Moodle refuse tout endpoint OAuth2 qui n'est pas en HTTPS **et** valide le certificat.

**Solution :** `scripts/gen-certs.sh` crée une AC locale et un certificat wildcard
`*.cr465.test`. Traefik le sert par défaut (`compose/traefik/dynamic/tls.yml`), et Moodle
le déclare comme autorité de confiance via `compose/moodle/php/99-cr465.ini`
(`curl.cainfo`).

### 2. Moodle ne résolvait pas `auth.cr465.test`

Les noms `*.cr465.test` n'existent pas dans un DNS public.

**Solution :** Traefik porte des **alias réseau** pour tous les noms publics
(`auth`, `lms`, `shop`, `flow`, `admin`). Les conteneurs du réseau `app`
résolvent donc ces noms vers Traefik, sans dépendre d'un DNS externe.

### 3. Moodle bloque les adresses privées (protection SSRF)

La découverte d'endpoints échouait avec « L'URL est bloquée ».

**Solution :** `curlsecurityblockedhosts` est vidé dans la configuration Moodle.
*Écart assumé* : ici la protection SSRF est compensée par la segmentation réseau
(Keycloak n'est joignable que depuis le réseau `app`).

### 4. PKCE obligatoire côté Keycloak, non supporté par Moodle

Keycloak rejetait le flux : `Missing parameter: code_challenge_method`.

**Solution :** l'attribut `pkce.code.challenge.method` a été **retiré du client `moodle`**
(il reste sur le client `drupal`, dont le module le supporte). Compensation : client
confidentiel avec secret, `redirect_uri` strict, TLS vérifié de bout en bout.

## Configuration obtenue

| Paramètre | Valeur |
|---|---|
| Fournisseur Moodle | `Keycloak` |
| Base URL (publique) | `https://auth.cr465.test/realms/cr465` |
| Client ID | `moodle` |
| Secret | celui de `MOODLE_OIDC_CLIENT_SECRET` |
| Scopes | `openid profile email` |
| Affichage | bouton sur la page de connexion |
| Endpoints | découverts via `.well-known/openid-configuration` |

## Vérification manuelle

```bash
# le bouton existe-t-il ?
curl -k --resolve lms.cr465.test:443:<IP> https://lms.cr465.test/login/index.php | grep -i keycloak

# la redirection est-elle correcte ?
# (client_id=moodle, redirect_uri=https://lms.cr465.test/admin/oauth2callback.php)
```

## Créer un utilisateur de démonstration

Aucun utilisateur n'est versionné (un mot de passe dans Git serait un secret exposé).
Pour une démonstration :

```bash
docker exec cr465-keycloak /opt/keycloak/bin/kcadm.sh config credentials \
  --server http://localhost:8080 --realm master --user admin --password '<KC_ADMIN_PASSWORD>'
docker exec cr465-keycloak /opt/keycloak/bin/kcadm.sh create users -r cr465 \
  -s username=etudiant1 -s email=etudiant1@cr465.test \
  -s firstName=Etudiant -s lastName=Test -s enabled=true -s emailVerified=true
docker exec cr465-keycloak /opt/keycloak/bin/kcadm.sh set-password -r cr465 \
  --username etudiant1 --new-password '<MOT_DE_PASSE>'
docker exec cr465-keycloak /opt/keycloak/bin/kcadm.sh add-roles -r cr465 \
  --uusername etudiant1 --rolename etudiant
```

> ⚠️ Utiliser un mot de passe différent de celui de la démonstration, et ne jamais
> l'écrire dans le dépôt.

## Limites connues

- **Provisioning** : à la première connexion, Moodle crée une fiche utilisateur locale
  (aucun mot de passe stocké). Si n8n crée déjà le compte à l'achat, le rattachement se
  fait par courriel — **ne jamais activer les deux mécanismes de création**.
- **Déconnexion** : la déconnexion Moodle ne ferme pas la session Keycloak (pas de
  single logout configuré). Amélioration possible.
- Le thème Keycloak utilise la page de connexion standard ; personnalisation possible
  plus tard.

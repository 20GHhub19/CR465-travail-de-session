# Identité et SSO

![Séquence SSO](assets/04-sequence-sso.png)

## Keycloak

| Élément | Valeur |
|---|---|
| Image | `quay.io/keycloak/keycloak:26.8.1` |
| Realm | `cr465` (importé au premier démarrage) |
| Rôles | `etudiant`, `enseignant` |
| Clients OIDC | `moodle`, `drupal` (confidentiels) |
| Politique de mot de passe | 12 caractères minimum, ni le login ni l'email |
| Anti-bruteforce | 5 échecs → verrouillage progressif (max 15 min) |
| Sessions | jeton 5 min, session inactive 30 min |

Le realm est **déclaratif** (`compose/keycloak/import/realm-cr465.template.json`) ; les
secrets sont injectés au déploiement par `scripts/render-keycloak-realm.sh` — le realm
généré n'est jamais versionné.

## SSO Moodle — vérifié de bout en bout

```
Page de connexion Moodle → bouton « Keycloak »
  → 303 vers auth.cr465.test/realms/cr465/protocol/openid-connect/auth
      client_id=moodle
      redirect_uri=https://lms.cr465.test/admin/oauth2callback.php
      scope=openid profile email
  → authentification (utilisateur du realm)
  → 200 sur https://lms.cr465.test/my/ (« Tableau de bord »)
```

L'utilisateur est connecté à Moodle **sans aucun mot de passe Moodle**.

## Points techniques

| Sujet | Choix |
|---|---|
| Flow | Authorization Code (PKCE retiré : le plugin core de Moodle ne l'implémente pas) |
| Validation du jeton | signature JWKS, `iss`, `aud`, `exp` |
| Provisioning | La fiche est créée par n8n à l'achat (`username = email`), ou au premier login SSO si l'utilisateur arrive directement. Aucun mot de passe stocké. |
| Déconnexion | session Moodle fermée ; single logout non configuré (limite) |

## Difficultés résolues

1. Certificat Traefik non reconnu par Moodle → AC locale montée + `curl.cainfo`.
2. `auth.cr465.test` non résolvable depuis les conteneurs → alias DNS sur Traefik.
3. Moodle bloque les adresses privées (SSRF) → `curlsecurityblockedhosts` vidé, compensé par la segmentation.
4. `Missing parameter: code_challenge_method` → PKCE retiré du client `moodle` uniquement.

Détail complet : `docs/operations/sso-moodle.md`.

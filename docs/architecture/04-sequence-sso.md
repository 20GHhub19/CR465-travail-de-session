# Schéma 4 — Séquence SSO (Keycloak ↔ Moodle)

> **État au 19 octobre 2026.** Les neuf services sont déployés et vérifiés (le service de test
> `whoami` a été retiré). Les éléments encore non déployés — WAF, Redis, Loki — restent en
> pointillé. Mettre ce schéma à jour à chaque ajout réel de service.

**Objectif** : démontrer un SSO OIDC fonctionnel entre Keycloak et Moodle (minimum exigé par la grille).

```mermaid
sequenceDiagram
    autonumber
    actor U as Utilisateur
    participant M as Moodle
    participant K as Keycloak

    U->>M: Accède à une ressource protégée
    M-->>U: Redirection OIDC (Authorization Code + PKCE)
    U->>K: Authentification (identifiants · MFA possible)
    K-->>U: Redirection avec code d'autorisation
    U->>M: Callback avec le code
    M->>K: Échange code → id_token + access_token
    K-->>M: Jetons signés (RS256)
    M->>K: Récupère le JWKS (clés publiques, mises en cache)
    M->>M: Valide signature · iss · aud · exp
    K-->>M: Claims : sub, email, given_name, family_name, roles
    M->>M: Rattache le compte par email (aucun doublon créé)

    opt Premier accès de l'utilisateur
        M->>M: Auto-provisioning du compte (nom + email)
    end

    M->>M: Mappe le rôle Keycloak (etudiant / enseignant)<br/>vers le rôle Moodle et la cohorte correspondante
    Note over M,K: Authentification centralisée : aucun mot de passe stocké dans Moodle.<br/>Moodle conserve une fiche utilisateur (rattachement), pas des identifiants locaux.
    M-->>U: Session ouverte — SSO établi

    opt Déconnexion
        U->>M: Logout
        M-->>K: Front-channel logout
        K-->>M: Session SSO terminée
    end

    opt Bonification — SSO Drupal Commerce
        U->>K: Même flux OIDC depuis Drupal
        K-->>U: Session unifiée (shop + lms + auth)
    end
```

## Ce que le schéma démontre

| Élément | Pourquoi |
|---|---|
| **Authorization Code + PKCE** | Flow recommandé pour une application web derrière un reverse proxy |
| Échange code → jetons, **RS256** | Le jeton est signé : impossible à forger sans la clé privée |
| Validation **JWKS · iss · aud · exp** | Contrôle réel du jeton, pas seulement sa présence |
| Claims (`sub`, `email`, `given_name`…) | Nécessaires au provisioning et au mapping des rôles |
| Rattachement par courriel | Évite les doublons de comptes |
| Mapping `etudiant` / `enseignant` | Les rôles Keycloak pilotent les droits Moodle |
| **Logout / front-channel logout** | Fermer la session Keycloak en même temps que celle de Moodle |

## Précision technique importante

On ne dit **pas** « aucun compte local dans Moodle » : c'est inexact. Moodle conserve une fiche
utilisateur (identifiant, courriel, profil) ; il ne stocke simplement **aucun mot de passe**.
L'identité et les credentials sont centralisés dans Keycloak.

## État réel

À ce jour, `compose/keycloak/` ne contient aucun realm ni client OIDC : **le SSO est documenté,
pas encore configuré**. Il faut créer le realm `cr465`, le client `moodle`
(`redirectUris: https://lms.cr465.test/admin/oauth2callback.php`) et stocker le secret dans `.env`.

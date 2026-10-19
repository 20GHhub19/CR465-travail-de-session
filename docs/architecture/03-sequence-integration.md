# Schéma 3 — Séquence d'intégration Drupal Commerce → n8n → Moodle

> **État au 19 octobre 2026.** Les neuf services sont déployés et vérifiés (le service de test
> `whoami` a été retiré). Les éléments encore non déployés — WAF, Redis, Loki — restent en
> pointillé. Mettre ce schéma à jour à chaque ajout réel de service.

**Objectif** : démontrer le parcours fonctionnel exigé, avec ses contrôles de sécurité.

```mermaid
sequenceDiagram
    autonumber
    actor U as Utilisateur
    participant D as Drupal Commerce
    participant N as n8n
    participant M as Moodle
    participant K as Keycloak

    U->>D: Consulte l'offre de formation
    U->>D: Paiement simulé / sandbox
    D->>D: Commande confirmée — statut « paid »

    D->>N: POST /webhook/commande<br/>{order_id, email, course_id}<br/>+ signature HMAC-SHA256
    N->>N: Vérifie la signature du webhook
    N->>N: Vérifie l'idempotence (order_id déjà traité ?)

    alt Signature invalide
        N-->>D: 401 — requête rejetée et journalisée
    else Commande déjà traitée
        N-->>D: 200 — ignorée (idempotent, aucun double accès)
    else Signature valide
        N->>M: core_user_get_users_by_field(email)
        M-->>N: userid (ou vide)
        opt Utilisateur inexistant dans Moodle
            N->>M: core_user_create_users(email, prénom, nom)
            M-->>N: userid créé
        end
        N->>M: enrol_manual_enrol_users(userid, courseid, rôle « étudiant »)
        alt Inscription réussie
            M-->>N: warnings = []
            N->>M: core_course_get_enrolled_users (vérification)
            N-->>D: 200 — {status: "enrolled"}
        else Échec (cours absent, service indisponible)
            N->>N: Retry (3 tentatives, backoff)
            N-->>D: 500 — {status: "failed"} + alerte journalisée
        end
    end

    Note over N,M: Appels API avec un compte de service Moodle dédié<br/>rôle limité : webservice + enrol/manual:enrol<br/>(aucun privilège administrateur)

    U->>K: Authentification SSO (voir schéma 4)
    K-->>U: Jeton / session ouverte
    U->>M: Accède au cours — droits actifs
```

## Ce que le schéma démontre

| Élément | Pourquoi |
|---|---|
| Webhook **signé HMAC-SHA256** | Empêche un tiers de déclencher des inscriptions |
| **Idempotence** sur `order_id` | Un webhook rejoué ne crée pas de double accès |
| Résolution `email → userid` | `enrol_manual_enrol_users` exige un `userid`, pas un email |
| Création du compte si absent | Cas d'un achat avant la première connexion SSO |
| **Compte de service** à rôle limité | Moindre privilège : `webservice` + `enrol/manual:enrol` |
| Retry ×3 + erreur journalisée | Un client qui a payé ne doit pas rester sans accès |
| Appel de vérification | Prouve que l'inscription a réellement pris effet |

## Fonctions Moodle utilisées (vérifiables dans la documentation officielle)

`core_user_get_users_by_field` · `core_user_create_users` · `enrol_manual_enrol_users` · `core_course_get_enrolled_users`

## Décision à trancher

**Qui crée le compte Moodle ?** n8n à l'achat, ou le SSO à la première connexion — **jamais les deux**
(risque de doublons). Choix recommandé : n8n crée, le SSO rattache par courriel.

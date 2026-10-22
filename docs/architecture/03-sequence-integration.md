# Séquence d'intégration — Drupal Commerce → n8n → Moodle (v4)
 
> Flux d'attribution d'accès après achat (paiement fictif/sandbox autorisé).
> Sécurités démontrées : webhook signé (HMAC), anti-rejeu (idempotence),
> moindre privilège (compte de service), gestion d'erreur (retry).
> Fonctions Moodle réelles et vérifiables dans la référence des services web.
 
```mermaid
%% Schéma 3 - Séquence d'intégration (durcie)
sequenceDiagram
    autonumber
    participant U as Utilisateur
    participant D as Drupal Commerce
    participant N as n8n
    participant M as Moodle
 
    Note over U,D: 1. VENTE (paiement fictif / sandbox)
    U->>D: Consulte l'offre de formation
    U->>D: Paiement (fictif / simule)
 
    Note over D,N: 2. DECLENCHEMENT (sans codage avance)
    D->>N: Webhook signe HMAC-SHA256 {order_id, email, course_id}
    N->>N: Verifie signature HMAC + idempotence (order_id)
 
    alt signature invalide
        N-->>D: 401 - rejete et journalise (Loki/Portainer)
    else valide
        Note over N,M: 3. ATTRIBUTION - compte de service a role limite
        N->>M: core_user_get_users_by_field (email -> userid)
        opt utilisateur absent
            N->>M: core_user_create_users
        end
        N->>M: enrol_manual_enrol_users (inscription)
        N->>M: core_course_get_enrolled_users (verification)
        M-->>N: Confirmation de l'attribution
        N-->>D: Mise a jour du statut (optionnel)
    end
 
    Note over N,M: En cas d'echec : retry x3 + backoff, sinon 500 + alerte
    Note over U,M: 4. CONSOMMATION (apres SSO - voir schema 4)
    U->>M: Accede au cours
```
## Lecture du schéma

| Mécanisme | Ce qu'il fait | Menace couverte |
|---|---|---|
| Webhook signé HMAC-SHA256 | Drupal signe le message avec un secret partagé, n8n vérifie la signature | Quelqu'un qui connaît l'URL de n8n déclenche de fausses inscriptions |
| Idempotence (`order_id`) | Une commande déjà traitée n'est pas rejouée | Webhook envoyé deux fois, rejeu d'une requête interceptée |
| Compte de service à rôle limité | n8n utilise un compte Moodle qui ne peut que gérer les inscriptions | Compromission de n8n = accès administrateur à Moodle |
| Retry ×3 avec backoff, puis alerte | Les pannes temporaires ne perdent pas la commande | Moodle indisponible au moment de l'achat |
| Rejet 401 journalisé | Les signatures invalides sont refusées et tracées | Tentatives d'abus, utile pour l'investigation |

**Appels Moodle utilisés :** `core_user_get_users_by_field` (trouver l'utilisateur
par email), `core_user_create_users` (le créer s'il n'existe pas),
`enrol_manual_enrol_users` (l'inscrire), `core_course_get_enrolled_users`
(vérifier l'inscription).

<!-- ? Détails du workflow et captures : voir `gitbook/projet-realisation/08-workflow-n8n.md`. ? -->
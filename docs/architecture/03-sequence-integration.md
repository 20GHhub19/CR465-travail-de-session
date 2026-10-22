# Séquence d'intégration — Drupal Commerce → n8n → Moodle (v2)

> Flux d'attribution d'accès après un achat (paiement fictif/sandbox autorisé).
> Les 4 phases (VENTE, DÉCLENCHEMENT, ATTRIBUTION, CONSOMMATION) sont annotées.

```mermaid
%% ============================================================
%% Schéma 3 - Séquence d'intégration Drupal -> n8n -> Moodle
%% Flux d'attribution d'accès après achat (paiement sandbox OK)
%% Les "Note over" expliquent chaque phase (visibles au rendu)
%% ============================================================
sequenceDiagram
    autonumber
    participant U as Utilisateur
    participant D as Drupal Commerce
    participant N as n8n
    participant M as Moodle

    Note over U,D: 1. VENTE (paiement fictif / sandbox autorisé)
    U->>D: Consulte l'offre de formation
    U->>D: Paiement (fictif / simulé / sandbox)

    Note over D,N: 2. DÉCLENCHEMENT (sans codage avancé)
    D->>N: Webhook "commande confirmée" (email, cours)

    Note over N,M: 3. ATTRIBUTION via API REST Moodle
    N->>M: enrol_manual_enrol_users (inscription)
    M-->>N: Confirmation de l'attribution
    N-->>D: Mise à jour du statut (optionnel)

    Note over U,M: 4. CONSOMMATION du contenu
    U->>M: Accède au cours (après SSO - voir schéma 4)
```

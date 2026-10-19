# Schéma 1 — Architecture générale

> **État au 19 octobre 2026.** Déployé et vérifié dans le dépôt : Traefik + un service de test
> (`whoami`). Tout le reste est une **cible** : les éléments non encore déployés sont en
> pointillé et signalés « non déployé ». Mettre ce schéma à jour à chaque ajout réel de service.

**Objectif** : montrer le parcours métier complet (achat → automatisation → accès au cours),
les points d'exposition et la place de chaque service.

```mermaid
flowchart TB
    subgraph EDGE["RÉSEAU EDGE — exposé (ports 80/443 uniquement)"]
        USERS["Utilisateurs / Internet"]
        WAF["OpenAppSec WAF<br/>bonus · mode local<br/>— non déployé —"]
        TRAEFIK["Traefik<br/>TLS/HTTPS · point d'entrée unique<br/>exposedByDefault = false"]
    end

    subgraph APP["RÉSEAU APP — applicatif (aucun port publié)"]
        PORTAINER["Portainer CE<br/>admin.cr465.test"]
        DRUPAL["Drupal Commerce<br/>shop.cr465.test"]
        N8N["n8n<br/>flow.cr465.test"]
        MOODLE["Moodle<br/>lms.cr465.test"]
        KEYCLOAK["Keycloak — IAM / SSO<br/>auth.cr465.test"]
    end

    subgraph DATA["RÉSEAU DATA — internal: true (jamais exposé)"]
        PG[("PostgreSQL 1 instance<br/>1 base + 1 user par service<br/>drupal · moodle · keycloak · n8n")]
        REDIS[("Redis<br/>bonus")]
    end

    USERS -->|"HTTPS 443"| TRAEFIK
    USERS -.->|"bonus"| WAF
    WAF -.->|"filtrage applicatif"| TRAEFIK

    TRAEFIK -->|"admin"| PORTAINER
    TRAEFIK -->|"shop"| DRUPAL
    TRAEFIK -->|"lms"| MOODLE
    TRAEFIK -->|"auth"| KEYCLOAK
    TRAEFIK -->|"flow"| N8N

    DRUPAL -->|"base drupal"| PG
    MOODLE -->|"base moodle"| PG
    KEYCLOAK -->|"base keycloak"| PG
    N8N -->|"base n8n"| PG
    N8N -.->|"cache / sessions"| REDIS

    DRUPAL -.->|"① webhook commande confirmée<br/>après paiement simulé"| N8N
    N8N -.->|"② API REST · enrol_manual_enrol_users"| MOODLE
    KEYCLOAK -.->|"③ OIDC : authentification Moodle"| MOODLE
    KEYCLOAK -.->|"OIDC Drupal (bonification)"| DRUPAL

    subgraph LEG["LÉGENDE"]
        L1["Déployé et vérifiable dans le dépôt"]
        L2["Cible à déployer (phases suivantes)"]
        L3["Bonus / optionnel — non engagé"]
        L4[("Base de données")]
        L5["Trait plein = flux principal · pointillé = flux à venir ou bonus"]
    end
    class L1 deployed
    class L2 toBuild
    class L3 bonus
    class L4 toBuild
    class L5 zone

    classDef deployed fill:#b9e4bf,stroke:#1b5e20,stroke-width:3px,color:#0d3b12
    classDef toBuild fill:#ffe08a,stroke:#b26a00,stroke-width:2px,stroke-dasharray:6 4,color:#5a3600
    classDef bonus fill:#d6c8f5,stroke:#4527a0,stroke-width:2px,stroke-dasharray:3 3,color:#311b92
    classDef zone fill:#f2f3f7,stroke:#8a8fa3,stroke-width:2px

    class USERS,TRAEFIK deployed
    class PORTAINER,DRUPAL,N8N,MOODLE,KEYCLOAK,PG toBuild
    class WAF,REDIS bonus

    class EDGE,APP,DATA zone
```

## Lecture du schéma

- **Une seule porte d'entrée** : Traefik, en HTTPS. Aucun service n'est exposé directement.
- **Cinq services applicatifs** derrière la porte, chacun sur son sous-domaine.
- **PostgreSQL** en bas : jamais joignable depuis Internet, une base et un utilisateur par service.
- **Parcours métier** : ① achat → webhook · ② inscription via l'API Moodle · ③ authentification OIDC.
- **Trois états** : vert = déployé, jaune = cible, violet = bonus non engagé.

## Points d'attention

- Le WAF (bonus, +2 pts hors total) est **non déployé** : il reste en pointillé.
- Le SSO Drupal est une **bonification** : il n'est pas requis pour la note de base.

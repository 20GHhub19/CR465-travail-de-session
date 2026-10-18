# Segmentation réseau — v2 (enrichie)

> Trois réseaux Docker isolés. Seul Traefik est exposé à Internet.
> Le réseau « data » est en `internal: true` : aucun accès depuis l'extérieur.
> La zone jaune rappelle le durcissement appliqué à chaque service applicatif.

```mermaid
%% ============================================================
%% Schéma 2 - Segmentation réseau (défense en profondeur)
%% 3 réseaux Docker isolés. Seul Traefik est exposé.
%% data = internal:true (aucun accès Internet)
%% ============================================================
flowchart LR
    Internet["Utilisateurs / Internet"]

    subgraph Edge["Réseau edge (exposé)"]
        WAF["OpenAppSec WAF<br/>bonus - mode local"]
        Proxy["Traefik<br/>TLS/HTTPS - point unique"]
    end

    subgraph App["Réseau app (applicatif)"]
        Durc["DURCISSEMENT (tous services)<br/>non-root - no-new-privileges<br/>cap_drop ALL - ressources limitées<br/>runtime gVisor si compatible"]
        Drupal["Drupal Commerce"]
        Moodle["Moodle"]
        Keycloak["Keycloak"]
        N8N["n8n"]
        Portainer["Portainer CE"]
    end

    subgraph Data["Réseau data (internal: true)"]
        Postgres[("PostgreSQL<br/>1 base + 1 user / service")]
        Redis[("Redis - bonus")]
    end

    Internet -->|"HTTPS"| WAF
    WAF -.->|"bonus"| Proxy
    Internet -->|"HTTPS"| Proxy
    Proxy --> Drupal
    Proxy --> Moodle
    Proxy --> Keycloak
    Proxy --> N8N
    Proxy --> Portainer

    Drupal --> Postgres
    Moodle --> Postgres
    Keycloak --> Postgres
    N8N --> Postgres
    N8N -.->|"bonus"| Redis

    classDef optional stroke-dasharray:5,5,fill:#eee;
    classDef note fill:#FFF6DD,stroke:#D6B656,color:#555;
    class WAF,Redis optional;
    class Durc note;
```

# Défense en profondeur — 4 couches de protection

> Schéma de synthèse sécurité : chaque couche est une barrière indépendante.
> C'est le schéma de référence pour la vidéo et le document de synthèse.

```mermaid
%% ============================================================
%% Schéma 5 - Défense en profondeur (4 couches)
%% Couche 0 Hôte / 1 Périmètre / 2 Applicatif / 3 Données
%% ============================================================
flowchart TB
    subgraph L0["COUCHE 0 - Hôte (VM Linux, cloud-init)"]
        direction LR
        FW["Pare-feu UFW<br/>22/80/443 seulement"]
        SSH["SSH par clé<br/>root désactivé"]
        GV["Runtime gVisor<br/>(runsc)"]
    end

    Internet["Utilisateurs / Internet"]

    subgraph L1["COUCHE 1 - Périmètre (réseau edge)"]
        WAF["OpenAppSec WAF<br/>(bonus, mode local)"]
        TR["Traefik<br/>TLS / HTTPS<br/>point d'entrée unique"]
    end

    subgraph L2["COUCHE 2 - Applicatif (réseau app)"]
        direction LR
        APPS["Drupal / Moodle / Keycloak / n8n / Portainer<br/>non-root - no-new-privileges<br/>cap_drop ALL - ressources limitées"]
    end

    subgraph L3["COUCHE 3 - Données (réseau data, internal)"]
        DB["PostgreSQL / Redis<br/>jamais exposés<br/>1 base + 1 user par service"]
    end

    IAM["Keycloak<br/>IAM / SSO (OIDC)"]

    Internet -->|"HTTPS"| WAF
    WAF -->|"bonus"| TR
    Internet -->|"HTTPS"| TR
    TR --> APPS
    APPS --> DB
    APPS -. "auth OIDC" .-> IAM

    classDef host fill:#FFF2CC,stroke:#D6B656;
    classDef edge fill:#DAE8FC,stroke:#6C8EBF;
    classDef app fill:#D5E8D4,stroke:#82B366;
    classDef data fill:#F8CECC,stroke:#B85450;
    class L0 host;
    class L1 edge;
    class L2 app;
    class L3 data;
```

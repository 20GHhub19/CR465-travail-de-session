# Défense en profondeur — 7 couches (v4)
 
> Chaque couche suppose la précédente franchie : un attaquant doit réussir sept fois.
> États : **vert = vérifié dans les fichiers** · **jaune = prévu aux phases suivantes** · **violet = bonus** .
> gVisor (runsc) est appliqué de façon **sélective** aux services compatibles (pas une promesse globale).
 
```mermaid
%% Schéma 5 - Défense en profondeur (7 couches, états honnêtes)
graph TB
    Menace["Menace / Internet"]:::ext
 
    subgraph L0["Couche 0 - CONSTRUIRE"]
        B["shift-left - images epinglees<br/>scan local Trivy/Grype"]:::done
    end
    subgraph L1["Couche 1 - HÔTE"]
        H["cloud-init - UFW 22/80/443 - SSH par cle - root off<br/>MaxAuthTries 3 - fail2ban - unattended-upgrades - sysctl - logs bornes<br/>gVisor (runsc) disponible - demontre (bonus)"]:::done
    end
    subgraph L2["Couche 2 - PÉRIMÈTRE"]
        P["edge - Traefik TLS - point unique - exposedByDefault=false<br/>(WAF OpenAppSec - bonus)"]:::done
    end
    subgraph L3["Couche 3 - APPLICATIF"]
        A["app internal - non-root - no-new-privileges<br/>cap_drop ALL - ressources limitées"]:::todo
    end
    subgraph L4["Couche 4 - DONNEES"]
        D["data internal - PostgreSQL/Redis jamais expose<br/>1 base + 1 user par service"]:::todo
    end
    subgraph L5["Couche 5 - IDENTITE"]
        I["Keycloak OIDC - rôles - moindre privilège"]:::todo
    end
    subgraph L6["Couche 6 - OBSERVABILITÉ"]
        O["Portainer (états/logs) - Loki/Grafana (bonus)"]:::todo
    end
 
    Svc["Service / Donnee protégée"]:::goal
 
    Menace --> L0 --> L1 --> L2 --> L3 --> L4 --> L5 --> L6 --> Svc
 
    classDef done fill:#dafbe1,stroke:#1a7f37,color:#07320f;
    classDef todo fill:#fff8c5,stroke:#9a6700,color:#3d2c00;
    classDef ext fill:#ffe3e0,stroke:#b85450,color:#5a1b16;
    classDef goal fill:#DAE8FC,stroke:#6C8EBF,color:#0b2e45;
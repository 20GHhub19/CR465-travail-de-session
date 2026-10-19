# Schéma 2 — Segmentation réseau

> **État au 19 octobre 2026.** Les neuf services sont déployés et vérifiés (le service de test
> `whoami` a été retiré). Les éléments encore non déployés — WAF, Redis, Loki — restent en
> pointillé. Mettre ce schéma à jour à chaque ajout réel de service.

**Objectif** : démontrer que les services sont isolés en zones de confiance, et expliciter
**quels accès sont volontairement interdits** — exigence directe de l'énoncé.

```mermaid
flowchart TB
    subgraph EDGE["RÉSEAU EDGE — exposé · ports 80/443"]
        INET["Utilisateurs / Internet"]
        WAF["OpenAppSec WAF<br/>bonus · mode local<br/>— non déployé —"]
        TRAEFIK["Traefik<br/>TLS/HTTPS · point d'entrée unique"]
    end

    subgraph APP["RÉSEAU APP — internal: true"]
        DRUPAL["Drupal Commerce"]
        MOODLE["Moodle"]
        KC["Keycloak"]
        N8N["n8n"]
    end

    subgraph OPS["RÉSEAU OPS — internal: true<br/>administration & exploitation"]
        PORTAINER["Portainer CE<br/>accès via Traefik + allowlist IP"]
        SOCKP["docker-socket-proxy v0.5.0<br/>API Docker en lecture seule<br/>POST = 0"]
    end

    subgraph DATA["RÉSEAU DATA — internal: true<br/>aucune route vers l'extérieur"]
        PG[("PostgreSQL<br/>1 base + 1 user / service")]
        REDIS[("Redis<br/>bonus")]
    end

    subgraph EGR["RÉSEAU EGRESS — sortie contrôlée"]
        EGRN["Internet sortant<br/>uniquement Moodle (dépendances)<br/>et n8n (webhooks)"]
    end

    subgraph FORBID["⛔ FLUX VOLONTAIREMENT INTERDITS"]
        F1["Internet → PostgreSQL / Redis"]
        F2["Traefik → PostgreSQL"]
        F3["Service applicatif → Internet<br/>hors réseau egress"]
        F4["Traefik → socket Docker brut"]
        F5["Portainer hors allowlist IP"]
    end

    INET -->|"HTTPS 443"| TRAEFIK
    INET -.->|"bonus"| WAF
    WAF -.->|"filtrage"| TRAEFIK

    TRAEFIK -->|"web"| DRUPAL
    TRAEFIK -->|"web"| MOODLE
    TRAEFIK -->|"web"| KC
    TRAEFIK -->|"web"| N8N
    TRAEFIK -->|"admin · allowlist"| PORTAINER
    TRAEFIK -.->|"API Docker RO"| SOCKP

    DRUPAL -->|"SQL"| PG
    MOODLE -->|"SQL"| PG
    KC -->|"SQL"| PG
    N8N -->|"SQL"| PG
    N8N -.->|"cache"| REDIS

    MOODLE -.->|"sortie contrôlée"| EGRN
    DRUPAL -.->|"webhook commande"| N8N
    N8N -.->|"API REST"| MOODLE
    KC -.->|"OIDC"| MOODLE

    classDef exposed fill:#ffd6a5,stroke:#c2410c,stroke-width:3px,color:#7c2d12
    classDef app fill:#ffe08a,stroke:#b26a00,stroke-width:2px,stroke-dasharray:6 4,color:#5a3600
    classDef ops fill:#d6c8f5,stroke:#4527a0,stroke-width:2px,style dashed,color:#311b92
    classDef data fill:#b9e4bf,stroke:#1b5e20,stroke-width:3px,color:#0d3b12
    classDef bonus fill:#d6c8f5,stroke:#4527a0,stroke-width:2px,stroke-dasharray:3 3,color:#311b92
    classDef interdit fill:#ffcdd2,stroke:#b71c1c,stroke-width:2px,color:#7f0000
    classDef zone fill:#f2f3f7,stroke:#8a8fa3,stroke-width:2px

    class INET,TRAEFIK exposed
    class DRUPAL,MOODLE,KC,N8N app
    class PORTAINER,SOCKP app
    class PG data
    class WAF,REDIS bonus
    class F1,F2,F3,F4,F5 interdit
    class EGRN exposed
    class EDGE,APP,OPS,DATA,EGR,FORBID zone

    subgraph LEG["LÉGENDE"]
        L1["Déployé et vérifiable dans le dépôt"]
        L2["Cible à déployer (phases suivantes)"]
        L3["Bonus / optionnel"]
        L4[("Base de données")]
        L5["⛔ Accès refusé par conception"]
    end
    class L1 exposed
    class L2 app
    class L3 bonus
    class L4 data
    class L5 interdit
    class LEG zone
```

## Les quatre zones

| Zone | Contenu | Règle |
|---|---|---|
| `edge` | Traefik (+ WAF bonus) | Seule zone avec des ports publiés (80/443) |
| `app` | Drupal, Moodle, Keycloak, n8n | `internal: true` — aucune sortie Internet |
| `ops` | Portainer, socket-proxy | Administration isolée, accès restreint par IP |
| `data` | PostgreSQL (+ Redis bonus) | `internal: true`, jamais exposé, jamais routé par Traefik |
| `socket` | Traefik ↔ socket-proxy, Portainer ↔ socket-proxy-admin | `internal: true` |
| `egress` | Moodle, n8n | **Sortie Internet contrôlée** : seuls les services qui en ont besoin |

## Flux volontairement interdits

1. Internet → PostgreSQL / Redis
2. Traefik → PostgreSQL
3. Service applicatif → Internet **hors réseau `egress`** (les autres réseaux sont `internal: true`)
4. Traefik → socket Docker brut (passage obligé par le socket-proxy, en lecture seule)
5. Portainer hors de la liste d'IP autorisées

## État d'implémentation (mis à jour)

| Élément | État |
|---|---|
| `app` en `internal: true` | ✅ appliqué dans `compose/docker-compose.yml` |
| `data` en `internal: true` | ✅ appliqué |
| Réseau `socket` + `docker-socket-proxy` (`POST: 0`) | ✅ appliqué |
| Portainer restreint par IP | 🔶 à faire au déploiement de Portainer |

**Exception documentée** : Moodle a besoin d'Internet **pendant son installation** (dépendances
Composer) et n8n en aura besoin pour ses webhooks sortants. Un réseau `egress` dédié a donc été
créé et n'est rattaché qu'à ces deux services. Les autres restent strictement internes.

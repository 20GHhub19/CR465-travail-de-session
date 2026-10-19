# Schéma 5 — Défense en profondeur

> **État au 19 octobre 2026.** Déployé et vérifié dans le dépôt : Traefik + un service de test
> (`whoami`). Tout le reste est une **cible** : les éléments non encore déployés sont en
> pointillé et signalés « non déployé ». Mettre ce schéma à jour à chaque ajout réel de service.

**Objectif** : montrer que la sécurité est répartie en couches indépendantes — un attaquant doit
réussir sept fois de suite.

```mermaid
flowchart TB
    MENACE["Menace : accès non autorisé · service compromis · fuite de données"]

    C0["COUCHE 0 — BUILD (shift-left)<br/>images épinglées · scan Trivy : script fourni · aucun secret versionné"]
    C1["COUCHE 1 — HÔTE (cloud-init)<br/>UFW 22/80/443 · SSH par clé, root off · fail2ban · unattended-upgrades"]
    C2["COUCHE 2 — PÉRIMÈTRE (edge)<br/>Traefik TLS ≥ 1.2 · exposedByDefault=false · HSTS · WAF bonus non déployé"]
    C3["COUCHE 3 — APPLICATIF (app · internal)<br/>non-root · no-new-privileges · cap_drop ALL · read_only · limites · healthcheck"]
    C4["COUCHE 4 — DONNÉES (data · internal)<br/>PostgreSQL 17.11 · 1 base + 1 user par service · jamais exposé"]
    C5["COUCHE 5 — IDENTITÉ<br/>Keycloak 26.8 · realm cr465 · clients Moodle et Drupal"]
    C6["COUCHE 6 — OBSERVABILITÉ<br/>Portainer CE · access log JSON · Loki / Grafana — bonus"]

    SERVICE["Service rendu à l'utilisateur légitime"]

    MENACE --> C0 --> C1 --> C2 --> C3 --> C4 --> C5 --> C6 --> SERVICE

    subgraph LEG["LÉGENDE"]
        direction LR
        G1["Déployé et vérifiable"]
        G2["Prévu — à vérifier"]
        G3["Absent — à implémenter"]
        G4["Bonus — non engagé"]
    end

    classDef deployed fill:#b9e4bf,stroke:#1b5e20,stroke-width:3px,color:#0d3b12
    classDef partial fill:#ffe08a,stroke:#b26a00,stroke-width:2px,color:#5a3600
    classDef toBuild fill:#ffd6a5,stroke:#c2410c,stroke-width:2px,stroke-dasharray:6 4,color:#7c2d12
    classDef bonus fill:#d6c8f5,stroke:#4527a0,stroke-width:2px,stroke-dasharray:3 3,color:#311b92
    classDef zone fill:#f2f3f7,stroke:#8a8fa3,stroke-width:2px
    classDef bookend fill:#eceff1,stroke:#37474f,stroke-width:2px,color:#263238

    class C1,C4 deployed
    class C2,C3,C5 partial
    class C0,C4,C6 toBuild
    class MENACE,SERVICE bookend
    class G1 deployed
    class G2 partial
    class G3 toBuild
    class G4 bonus
    class LEG zone
```

## Les sept couches

| Couche | Contrôles | État vérifié |
|---|---|---|
| 0 — BUILD | Images épinglées, scan local, aucun secret versionné | **Script fourni**, rapport à produire |
| 1 — HÔTE | UFW 22/80/443, SSH par clé, root off, fail2ban, unattended-upgrades, sysctl, logs Docker bornés | **Déployé** (cloud-init) |
| 2 — PÉRIMÈTRE | Traefik TLS ≥ 1.2, `exposedByDefault=false`, HSTS, WAF bonus | **Partiel** (WAF absent) |
| 3 — APPLICATIF | non-root, `no-new-privileges`, `cap_drop: ALL`, `read_only`, limites, healthcheck | **Appliqué** dans le compose |
| 4 — DONNÉES | PostgreSQL jamais exposé, 1 base + 1 user par service | Cible |
| 5 — IDENTITÉ | Keycloak OIDC, rôles, MFA possible | Cible (non configuré) |
| 6 — OBSERVABILITÉ | Portainer, access log JSON, Loki/Grafana | Cible (absent) |

## Risque résiduel à documenter

- L'utilisateur `adminops` appartient au groupe `docker` : sur l'hôte, cela équivaut à **root**.
- Le socket Docker n'est **plus** monté dans Traefik : il passe par `docker-socket-proxy`
  en lecture seule (`POST: 0`), sur un réseau `socket` isolé.
- `whoami` n'a pas de healthcheck : image `scratch` sans binaire interne. Le healthcheck de
  Traefik et `scripts/test-routing.sh` couvrent la vérification.

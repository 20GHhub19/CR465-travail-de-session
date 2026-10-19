# Plateforme pédagogique conteneurisée sécurisée — CR465

Documentation du travail de session (Polytechnique Montréal, CR465, groupe D).

**Objectif** : concevoir, automatiser et sécuriser une plateforme de formation en ligne
auto-hébergée sur une VM unique, avec un parcours métier complet : achat d'une formation →
attribution automatique de l'accès → consommation du cours.

## Parcours métier

```
Drupal Commerce (achat) → n8n (orchestration) → Moodle (accès au cours)
                     ↘ Keycloak (identité unique, SSO)
```

## En un coup d'œil

| Élément | Choix retenu |
|---|---|
| Provisionnement | cloud-init (`cloud-init/user-data.yaml`) sur Ubuntu 24.04 |
| Orchestration | Docker Compose, 9 services |
| Point d'entrée | Traefik (HTTPS, unique) |
| Identité | Keycloak, realm `cr465`, SSO Moodle fonctionnel |
| Données | PostgreSQL unique, une base + un utilisateur par service |
| Domaines | `*.cr465.test` (réservé RFC 2606) |

## Plan de la documentation

1. [Présentation du projet](projet-realisation/01-presentation.md)
2. [Architecture réelle déployée](projet-realisation/02-architecture.md)
3. [VM as Code — cloud-init](projet-realisation/03-vm-cloud-init.md)
4. [Déploiement Docker Compose](projet-realisation/04-deploiement-compose.md)
5. [Segmentation réseau](projet-realisation/05-segmentation-reseau.md)
6. [Mesures de sécurité](projet-realisation/06-securite.md)
7. [Identité et SSO](projet-realisation/07-sso.md)
8. [Workflow n8n](projet-realisation/08-workflow-n8n.md)
9. [Observabilité](projet-realisation/09-observabilite.md)
10. [Limites et risques résiduels](projet-realisation/10-limites-risques.md)
11. [Contribution des membres](projet-realisation/11-contributions.md)

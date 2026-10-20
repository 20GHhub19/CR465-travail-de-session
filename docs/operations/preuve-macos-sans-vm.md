# Preuve d'exécution — macOS 27, Apple Silicon, sans machine virtuelle

> Objectif : démontrer que la plateforme complète fonctionne sur macOS sans Multipass, ni VM.
> Toutes les sorties ci-dessous sont **réelles**, relevées le 19 octobre 2026 sur un Mac Studio
> M1 Ultra (arm64, macOS 27.0.1), avec Docker Engine 29.8.2.

## Pourquoi ce mode existe

Multipass 1.16.4 ne peut pas démarrer de VM sur macOS 27 : le processus QEMU reste figé à
**0,02 s de CPU** dès l'activation de `-nic vmnet-shared` (voir `tests-plateformes.md`).
La stack reste néanmoins **entièrement fonctionnelle en Docker direct**, ce qui permet
d'inspecter, démontrer et filmer la plateforme sur cette machine.

## Conteneurs

```
cr465-drupal              Up (healthy)
cr465-keycloak            Up (healthy)
cr465-moodle              Up (healthy)
cr465-n8n                 Up (healthy)
cr465-postgres            Up (healthy)
cr465-traefik             Up (healthy)
cr465-portainer           Up
cr465-socket-proxy        Up
cr465-socket-proxy-admin  Up
```

## Réponses HTTP et TLS

| Domaine | Code | Contenu servi |
|---|---|---|
| `shop.cr465.test` | **200** | `<title>Welcome! | CR465 Formation</title>` |
| `lms.cr465.test` | **303** | redirection Moodle (session non ouverte) |
| `auth.cr465.test` | **302** | redirection Keycloak vers la console |
| `flow.cr465.test` | **200** | `<title>n8n.io - Workflow Automation</title>` |
| `admin.cr465.test` | **307** | redirection Portainer |

Redirection HTTP → HTTPS :

```
HTTP -> 301 vers https://shop.cr465.test/
```

Temps de réponse : 7 à 85 ms selon le service.

## Durcissement constaté

| Conteneur | Utilisateur | Capacités | Racine en lecture seule | privilégié |
|---|---|---|---|---|
| `cr465-traefik` | `1000:1000` | `[ALL]` supprimées | **oui** | non |
| `cr465-postgres` | (image) | `[ALL]` supprimées | **oui** | non |
| `cr465-moodle` | `nobody` | `[ALL]` supprimées | non | non |
| `cr465-drupal` | (image) | `[ALL]` supprimées | non | non |

Tous : `no-new-privileges:true`.

**Socket Docker** : aucun montage brut de `/var/run/docker.sock` dans Traefik — il passe par
`socket-proxy` en lecture seule.

## Preuve d'intégration (base de données)

```
acheteur2@cr465.test | CR465-DEMO
etudiant1@cr465.test | CR465-DEMO
```

Ces deux lignes sont créées dans `mdl_user_enrolments` : la première par le webhook Drupal → n8n,
la seconde par le parcours SSO. Elles prouvent que le flux métier fonctionne réellement.

## Conclusion

| Élément | Vérifié sur ce Mac |
|---|---|
| Stack Compose complète | ✅ |
| Routage Traefik + TLS | ✅ |
| Durcissement à l'exécution | ✅ |
| Intégration achat → Moodle | ✅ |
| VM as Code (cloud-init) | ❌ impossible sur macOS 27 — à démontrer sur Windows ou Linux |

Ce mode **ne remplace pas** la démonstration VM as Code : il prouve que la couche applicative
est portable et fonctionnelle, indépendamment de l'hyperviseur.

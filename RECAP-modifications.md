# Récapitulatif complet des modifications

> Depuis le **premier commit du dépôt** jusqu'à l'état actuel.
> Généré le 19 octobre 2026. Détail chronologique dans `CHANGELOG.md`.

## Bilan chiffré

| Indicateur | Valeur |
|---|---|
| Commits dans l'historique | 41 |
| Fichiers modifiés depuis l'origine | 108 |
| Lignes ajoutées / supprimées | +5 811 / −875 |
| Fichiers ajoutés | 94 |
| Services déployés au départ | 0 |
| Services déployés aujourd'hui | **9** |

---

## 1. Point de départ

Le dépôt contenait : la licence, un README minimal, la structure de dossiers, un `cloud-init`
fonctionnel (socle VM), un `docker-compose.yml` avec **Traefik + un service de test `whoami`**,
et 11 pages de GitBook vides (« Statut : à compléter »).

Le socle était bon mais **aucun service métier n'existait** : ni base de données, ni identité,
ni boutique, ni LMS, ni intégration.

---

## 2. Sprint A — Cohérence du dépôt

**Problème** : trois conventions de domaine coexistaient (`exemple.lan`, `example.lan`,
`cr465.lan`), les docs affirmaient être « conformes au déploiement réel » alors que 6 services
sur 8 étaient absents, `.gitignore` contenait une commande shell, et `Contributions.md` était vide.

| Fichier | Modification |
|---|---|
| `.gitignore` | commande `docker run … gitleaks` retirée ; ajout `*.log`, `*.iso`, `*.crt`, `*.p12`, `acme.json` |
| `compose/.env.example` | domaine unifié `cr465.test` ; commentaires sortis des valeurs |
| `compose/docker-compose.yml` | `whoami.cr465.lan` → `whoami.cr465.test` |
| `scripts/test-routing.sh` | hôte de test aligné |
| `docs/architecture/01` à `05` | réécriture : zones de confiance, flux interdits, webhook signé, SSO, 7 couches + bandeau d'état honnête |
| `docs/architecture/README.md` | guide de lecture des 5 schémas (nouveau) |
| `docs/architecture/img/*.png` | 5 rendus PNG (nouveaux) |
| `md/Contributions.md` | relevé Git réel et répartition des verticales |

---

## 3. Sprint B — Durcissement de la stack

| Fichier | Modification |
|---|---|
| `compose/docker-compose.yml` | `cap_drop: ALL`, `no-new-privileges`, `read_only` + `tmpfs`, utilisateurs non-root, `cap_add` ciblés, limites CPU/RAM, healthcheck, logs bornés 3×10 Mo |
| idem | socket Docker remplacé par **`docker-socket-proxy`** (`POST: 0`) sur réseau `socket` |
| idem | réseau `app` passé en `internal: true` |
| idem | images épinglées : `traefik:v3.7.15`, `whoami:v1.12.0`, `socket-proxy:v0.5.0` |
| idem | `accessLog` JSON activé |
| `scripts/scan-images.sh` | scan Trivy local (nouveau) |
| `docs/security/01..03` | politique images, durcissement, rapport de scan (nouveaux) |
| `docs/operations/incident-api-docker.md` | diagnostic 404 Traefik / API Docker (nouveau) |

**Résultat vérifié** : traefik 0 HIGH / 0 CRITICAL ; routage HTTPS 200 ; redirection 301.

---

## 4. Sprint C — Données et identité

| Fichier | Modification |
|---|---|
| `compose/postgres/init/01-create-databases.sh` | 4 bases + 4 utilisateurs dédiés (nouveau) |
| `compose/docker-compose.yml` | services `postgres` et `keycloak`, volumes, healthchecks |
| `compose/keycloak/import/realm-cr465.template.json` | realm `cr465` : rôles, clients OIDC Moodle et Drupal (nouveau) |
| `scripts/render-keycloak-realm.sh` | injection des secrets dans le realm (nouveau) |
| `.gitignore` | realm généré exclu |
| `docs/operations/deploiement.md` | ordre des opérations (nouveau) |
| `CHANGELOG.md` | journal des modifications (nouveau) |

**Résultat vérifié** : 4 rôles PostgreSQL, découverte OIDC 200, clients importés, secret conforme.

---

## 5. Sprint D — Moodle, Portainer, sortie contrôlée

| Fichier | Modification |
|---|---|
| `compose/docker-compose.yml` | service `moodle`, service `portainer`, `socket-proxy-admin` (écriture), réseau `egress`, noms de réseaux explicites |
| `.env.example` | `ADMIN_ALLOWLIST` |
| Schémas 01, 02, 05 | Moodle et Portainer passés en « déployé », réseau `egress` représenté |

**Résultat vérifié** : Moodle installé (499 tables), page de connexion FR, Portainer 307, `lms` 303.

---

## 6. Sprint E — SSO Moodle ↔ Keycloak

| Fichier | Modification |
|---|---|
| `scripts/gen-certs.sh` | AC locale + certificat wildcard `*.cr465.test` (nouveau) |
| `compose/traefik/dynamic/tls.yml` | certificat par défaut de Traefik (nouveau) |
| `compose/moodle/php/99-cr465.ini` | `curl.cainfo` (nouveau) |
| `scripts/configure-moodle-sso.sh` + `compose/moodle/sso/configure-oidc.php` | fournisseur OIDC et découverte d'endpoints (nouveaux) |
| `compose/docker-compose.yml` | provider fichier Traefik, alias DNS internes, montage de l'AC |
| `compose/keycloak/import/realm-cr465.template.json` | PKCE retiré du client `moodle` |
| `docs/operations/sso-moodle.md` | procédure et 4 pièges (nouveau) |

**Résultat vérifié** : bouton Keycloak, 303 vers Keycloak, **session Moodle ouverte** (`/my/`).

---

## 7. Sprint F — n8n et attribution d'accès

| Fichier | Modification |
|---|---|
| `compose/docker-compose.yml` | service `n8n`, volume `n8n_data` |
| `compose/n8n/workflows/commande-moodle.template.json` | webhook → recherche → `enrol_manual_enrol_users` (nouveau) |
| `scripts/render-n8n-workflow.sh` | injection du jeton au déploiement (nouveau) |
| `scripts/configure-moodle-webservice.sh` + `compose/moodle/webservice/*.php` | service web REST, compte `svc-n8n`, rôle limité, jeton, cours démo (nouveaux) |
| `docs/operations/integration-n8n.md` | procédure et 3 pièges Moodle (nouveau) |

**Résultat vérifié** : `POST /webhook/commande` → `{"status":"enrolled"}` → ligne d'inscription.

---

## 8. Sprint G — Drupal Commerce

| Fichier | Modification |
|---|---|
| `compose/drupal/Dockerfile` | image dérivée : bcmath, intl, drush, Commerce baké (nouveau) |
| `compose/drupal/entrypoint.sh` | persistance de `settings.php` (nouveau) |
| `compose/drupal/modules/cr465_notify/` | module de notification n8n avec HMAC (nouveau) |
| `compose/drupal/scripts/*.php` | configuration Commerce et simulation d'achat (nouveaux) |
| `compose/drupal/php/99-cr465.ini` | confiance TLS (nouveau) |
| `compose/docker-compose.yml` | service `drupal`, volumes, capacités ciblées |
| `scripts/configure-drupal.sh` | installation reproductible (nouveau) |
| `docs/operations/drupal-commerce.md` | procédure et 3 pièges (nouveau) |

**Résultat vérifié** : boutique 200, produit 49.00, commande complétée → n8n HTTP 200 →
**inscription Moodle créée pour un nouvel apprenant**.

---

## 9. Livrables

| Fichier | Modification |
|---|---|
| `gitbook/README.md` | page d'accueil (nouveau) |
| `gitbook/projet-realisation/01..11` | 11 pages remplies (≈3 500 mots) |
| `gitbook/assets/*.png` | 5 schémas copiés dans le GitBook (nouveaux) |
| `CR465-synthese-groupe-D.docx` | document de synthèse, 8 pages (nouveau) |
| `docs/operations/video-script.md` | script vidéo minuté 13 min (nouveau) |

---

## 10. Sprint H — Nettoyage

| Élément | Modification |
|---|---|
| `compose/docker-compose.yml` | suppression du service `whoami` et de son alias DNS |
| `scripts/test-routing.sh` | cible désormais Moodle |
| `docs/security/scans/traefik_whoami_v1.12.0.txt` | supprimé |
| Documentation | README, GitBook, pages d'architecture, rapport de scan, script vidéo alignés |

**Vérifié** : 9 services, `whoami.cr465.test` → 404, tous les endpoints métier répondent.

---

## 11. État final par domaine

| Domaine | Avant | Après |
|---|---|---|
| Services | 2 (proxy + test) | **9** |
| Base de données | absente | 4 bases, 4 utilisateurs dédiés |
| Identité | absente | realm `cr465`, 2 clients OIDC |
| SSO Moodle | absent | **fonctionnel, testé de bout en bout** |
| Boutique | absente | Drupal Commerce, produit, paiement simulé |
| Intégration | absente | **achat → n8n → inscription Moodle** |
| Réseaux | 3 déclarés, 1 utilisé | 5 réseaux, 2 internes + egress contrôlé |
| Durcissement | `no-new-privileges` seul | `cap_drop ALL`, non-root, `read_only`, limites, healthchecks |
| Scan d'images | aucun | Trivy local + rapports |
| TLS | certificat auto-signé interne | AC locale + certificat distribué et vérifié |
| Documentation | 11 pages vides | GitBook complet + 8 pages Word + script vidéo |

## 12. Ce qui reste à faire

1. **Enregistrer la vidéo** (≤ 15:59) avec le script fourni.
2. Compléter la page « Contributions » du GitBook par les autres membres.
3. Améliorations optionnelles : vérification HMAC côté n8n, création automatique de
   l'utilisateur Moodle, Loki/Grafana, sauvegardes des volumes.

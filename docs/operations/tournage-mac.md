# Kit de tournage — segments filmables sur le Mac

> Segments **1, 3, 4 et 5** (le segment 2, VM as Code, se filme sur Windows).
> Objectif : 10 min 30 de vidéo ici, 2 min sur Windows, soit **12 min 30** au total — sous la
> limite de 15:59.

---

## Avant d'enregistrer

### 1. Préparer le navigateur (une seule fois, demande ton mot de passe)

```bash
sudo tee -a /etc/hosts >/dev/null <<'EOF'

# CR465 — demonstration locale
127.0.0.1 shop.cr465.test
127.0.0.1 lms.cr465.test
127.0.0.1 auth.cr465.test
127.0.0.1 flow.cr465.test
127.0.0.1 admin.cr465.test
EOF
sudo dscacheutil -flushcache
```

Vérification : `ping -c1 shop.cr465.test` doit répondre depuis `127.0.0.1`.

### 2. Démarrer et vérifier la plateforme

```bash
bash scripts/demo-prep.sh
```

Attendu : 9 conteneurs, 6 `healthy`, et les 5 domaines en 200/3xx.

### 3. Récupérer les identifiants pour la démo

```bash
grep -E "^(KC_ADMIN|MOODLE_ADMIN_USER|DRUPAL_ADMIN_USER)=" compose/.env
```

> Ne jamais afficher les mots de passe à l'écran : les taper hors champ ou flouter.

### 4. Réglages d'enregistrement

| Paramètre | Valeur |
|---|---|
| Résolution | 1920 × 1080 |
| Police du terminal | 18 pt minimum |
| Zoom navigateur | 110 % |
| Micro | testé, niveau constant |
| Notifications | désactivées (Ne pas déranger) |
| Onglets ouverts | boutique, Moodle, Keycloak, Portainer |

---

## Segment 1 — Introduction et architecture (2 min 30)

**Écran** : `gitbook/assets/01-architecture-generale.png` puis `02-segmentation-reseau.png`.

**Plan** :
1. Se présenter, annoncer le parcours métier en une phrase
2. Montrer les 3 zones (EDGE / APP / DATA) et la légende à 3 états
3. Montrer les 5 réseaux et les flux interdits
4. Annoncer : « je montre ensuite la VM, la sécurité, l'identité, puis le parcours en direct »

---

## Segment 3 — Sécurité (2 min 30)

**Commandes à exécuter en direct** :

```bash
# 1. Durcissement
docker inspect cr465-traefik --format 'user={{.Config.User}} capdrop={{.HostConfig.CapDrop}} readonly={{.HostConfig.ReadonlyRootfs}} nnp={{index .HostConfig.SecurityOpt 0}}'

# 2. Aucun conteneur privilégié
docker ps --filter "name=cr465-" --format '{{.Names}}' | xargs -I{} docker inspect {} --format '{{.Name}} privileged={{.HostConfig.Privileged}}'

# 3. Réseaux
docker network ls | grep cr465

# 4. Socket Docker jamais monté brut
docker inspect cr465-traefik --format '{{range .Mounts}}{{.Source}}{{"\n"}}{{end}}' | grep docker.sock || echo "aucun socket brut"

# 5. Scan d'images (résultat déjà produit)
cat docs/security/03-rapport-scan.md | head -25
```

**À dire** : capacités supprimées, non-root, racine en lecture seule, socket proxifié, images
épinglées, zéro vulnérabilité HIGH sur l'image exposée.

---

## Segment 4 — Identité et SSO (2 min)

**Écran** : `https://auth.cr465.test/admin/` → realm `cr465` → Clients → `moodle`.

Puis la démonstration :

1. Ouvrir `https://lms.cr465.test/` (page de connexion Moodle)
2. Cliquer sur **Keycloak**
3. Redirection visible vers `auth.cr465.test/realms/cr465/protocol/openid-connect/auth?...`
4. S'authentifier avec un compte de démonstration
5. Retour sur Moodle, tableau de bord affiché

**À dire** : realm déclaratif, deux clients OIDC, secrets jamais versionnés, aucun mot de passe
stocké dans Moodle, signature du jeton vérifiée.

---

## Segment 5 — Parcours complet (3 min 30)

### 5a. Achat (1 min)

`https://shop.cr465.test/` → produit → panier → courriel de l'apprenant → paiement simulé.

### 5b. Webhook (45 s)

```bash
docker logs cr465-drupal --tail 8 | grep cr465_notify
```

Attendu : la ligne de notification avec le code HTTP 200.

### 5c. Orchestration n8n (45 s)

`https://flow.cr465.test/` → workflow → dernière exécution (nœuds verts).

### 5d. Résultat en base (1 min)

```bash
docker exec cr465-postgres psql -U pgadmin -d moodle -c \
"SELECT u.email, c.shortname FROM mdl_user_enrolments ue
  JOIN mdl_enrol e ON e.id=ue.enrolid
  JOIN mdl_user u ON u.id=ue.userid
  JOIN mdl_course c ON c.id=e.courseid ORDER BY ue.id DESC LIMIT 3;"
```

**À dire** : l'inscription vient d'être créée par n8n, sans intervention manuelle.

### 5e. Observabilité (30 s)

`https://admin.cr465.test/` → conteneurs → logs d'un service.

### 5f. Limites (30 s)

Énoncer 3 limites assumées (paiement simulé, pas de SMTP, signature HMAC non vérifiée côté n8n).

---

## Après le tournage

```bash
docker compose -p cr465test --env-file compose/.env -f compose/docker-compose.yml down
```

Assemblage : segments dans l'ordre 1 → 2 (Windows) → 3 → 4 → 5.
Export 1080p, sous-titres si possible, hébergement Microsoft 365 / Stream.
Vérifier la durée finale : **≤ 15:59**.

---

## Ce qu'il ne faut jamais montrer

- Le contenu de `compose/.env`
- Un mot de passe tapé à l'écran
- Le terminal avec l'historique de commandes contenant des secrets
- Une fenêtre de messagerie ou de notification

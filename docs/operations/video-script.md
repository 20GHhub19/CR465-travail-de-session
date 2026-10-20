# Script de la vidéo de démonstration (13 min — limite 15:59)

> Support de préparation. Chaque bloc indique **ce qu'on montre à l'écran**, **ce qu'on dit**, et
> la **durée cible**. Prévoir 2 prises maximum : une répétition complète, puis l'enregistrement.

## Avant d'enregistrer — checklist (10 min)

1. Stack démarrée : `docker compose -p cr465 --env-file compose/.env -f compose/docker-compose.yml up -d`
2. Tous les services sains : `docker compose ... ps`
3. Onglets ouverts dans l'ordre :
   - terminal à la racine du dépôt
   - `https://shop.cr465.test/`
   - `https://lms.cr465.test/`
   - `https://auth.cr465.test/admin/` (console Keycloak)
   - `https://admin.cr465.test/` (Portainer)
   - `https://flow.cr465.test/` (n8n)
4. Zoom navigateur à 110 %, terminal en police 18.
5. Vérifier que la stack ne contient plus de service de test.
6. Préparer deux comptes : `etudiant1@cr465.test` (déjà inscrit), `acheteur3@cr465.test` (nouveau).
7. Fermer les notifications système.

---

## Bloc 1 — Introduction (0:00 → 1:00) · 1 min

**À l'écran** : page de garde du document de synthèse.

**À dire** :
> « Bonjour, nous sommes le groupe D du cours CR465. Nous avons construit une plateforme de
> formation en ligne complète, auto-hébergée sur une seule machine virtuelle, entièrement
> automatisée et sécurisée. Le parcours métier est simple : un visiteur achète une formation,
> un workflow l'inscrit automatiquement, et il accède au cours avec une identité unique.
> Je vais vous montrer l'infrastructure, puis le parcours en direct, puis les mécanismes de
> sécurité et l'exploitation. »

## Bloc 2 — VM as Code (1:00 → 2:30) · 1 min 30

**À l'écran** : `cloud-init/user-data.yaml`, puis la VM.

**À dire** :
> « Tout part d'un fichier cloud-init. Il crée un compte d'administration par clé SSH, interdit
> root et les mots de passe, applique UFW en n'ouvrant que 22, 80 et 443, active fail2ban avec
> un bannissement d'une heure après trois essais, installe Docker depuis le dépôt officiel et
> durcit le démon. »

**Montrer** :
```bash
multipass list
ssh adminops@$(multipass info plateforme | awk '/IPv4/{print $2}')
sudo ufw status verbose
sudo fail2ban-client status sshd
cloud-init status --long
```

> « La VM a été détruite et recréée à l'identique en cours de projet : c'est ça, le VM as Code. »

## Bloc 3 — Architecture (2:30 → 4:00) · 1 min 30

**À l'écran** : `docs/architecture/01-architecture-generale.png` puis `02-segmentation-reseau.png`.

**À dire** :
> « Neuf services conteneurisés. Un seul point d'entrée : Traefik, en HTTPS. Derrière, cinq
> services applicatifs, chacun sur son nom de domaine. En bas, PostgreSQL, jamais exposé.
> Cinq réseaux : exposition, applicatif, données, socket et un réseau de sortie contrôlée
> réservé à Moodle, n8n et Drupal. Le réseau applicatif est interne : un conteneur compromis
> ne peut pas exfiltrer de données.
> Et les flux interdits sont explicites : Internet ne parle jamais à la base, Traefik non plus,
> et Traefik n'accède pas au socket Docker directement — il passe par un proxy filtrant en
> lecture seule. »

## Bloc 4 — Déploiement et durcissement (4:00 → 5:30) · 1 min 30

**À l'écran** : `docker compose ps`, puis `docker inspect` sur Traefik.

**Montrer** :
```bash
docker compose -p cr465 ps
docker inspect cr465-traefik --format 'user={{.Config.User}} capdrop={{.HostConfig.CapDrop}} readonly={{.HostConfig.ReadonlyRootfs}}'
docker exec cr465-traefik id
```

**À dire** :
> « Tous les conteneurs tournent avec les capacités supprimées, `no-new-privileges`, et pour
> plusieurs en système de fichiers en lecture seule. Traefik tourne en utilisateur non-root :
> il ne garde qu'une seule capacité, celle qui lui permet d'ouvrir les ports 80 et 443.
> Les images sont toutes épinglées, et un scan Trivy local a été exécuté : zéro vulnérabilité
> haute ou critique sur l'image exposée. »

## Bloc 5 — Le parcours métier en direct (5:30 → 9:00) · 3 min 30

### 5a. Achat (5:30 → 6:30)
**À l'écran** : `https://shop.cr465.test/` → produit → panier.

> « Voici la boutique Drupal Commerce. La formation est à 49 dollars. J'ajoute au panier, je
> renseigne un courriel — celui de l'apprenant — et je valide avec la passerelle de paiement
> simulée. Aucun encaissement réel : l'énoncé l'autorise, l'objectif est la cohérence du
> parcours. »

### 5b. Webhook et orchestration (6:30 → 7:30)
**À l'écran** : journal Drupal puis n8n (exécution).

```bash
docker logs cr465-drupal --tail 5 | grep cr465_notify
```

> « Dès que la commande passe à l'état "completed", notre module Drupal envoie un webhook signé
> à n8n. n8n retrouve l'apprenant dans Moodle, puis l'inscrit au cours via l'API REST, avec un
> compte de service qui n'a que les droits d'inscription — aucun accès administrateur. »

**Montrer** dans n8n : les trois nœuds et l'exécution verte.

### 5c. Résultat dans Moodle (7:30 → 8:15)
**À l'écran** : `https://lms.cr465.test/` → connexion → cours.

> « Je me connecte sur Moodle. Notez qu'il n'y a pas de mot de passe Moodle : je clique sur
> "Keycloak", je m'authentifie, et me voilà dans mon tableau de bord, avec le cours auquel je
> viens d'être inscrit automatiquement. »

### 5d. Preuve en base (8:15 → 9:00)
```bash
docker exec cr465-postgres psql -U pgadmin -d moodle -c \
 "SELECT u.email, c.shortname, ue.status FROM mdl_user_enrolments ue
  JOIN mdl_enrol e ON e.id=ue.enrolid
  JOIN mdl_user u ON u.id=ue.userid
  JOIN mdl_course c ON c.id=e.courseid ORDER BY ue.id DESC LIMIT 3;"
```

> « L'inscription est bien en base, créée à l'instant par n8n. »

## Bloc 6 — Sécurité et SSO (9:00 → 10:30) · 1 min 30

**À l'écran** : console Keycloak (realm `cr465`, rôles, clients), puis `docs/architecture/04-sequence-sso.png`.

**À dire** :
> « Keycloak est notre fournisseur d'identité. Le realm est déclaratif : deux rôles, etudiant et
> enseignant, une politique de mot de passe de douze caractères, une protection contre le
> bruteforce. Deux clients OIDC, un pour Moodle, un pour la boutique.
> Le point important : les secrets ne sont jamais dans le dépôt. Le realm est généré au
> déploiement à partir d'un modèle.
> Le flux est un Authorization Code classique, avec validation de la signature du jeton, de
> l'émetteur et de l'audience. »

## Bloc 7 — Observabilité (10:30 → 11:45) · 1 min 15

**À l'écran** : Portainer → conteneurs → logs d'un conteneur.

> « Portainer nous donne la vue d'exploitation : neuf conteneurs, leur santé, les réseaux, les
> volumes. Ici les journaux de Drupal, avec la notification envoyée à n8n et son code de retour.
> Traefik journalise aussi les accès en JSON, sans les en-têtes sensibles.
> Scénario de diagnostic : si j'arrête n8n et que je repasse une commande, Drupal journalise une
> erreur et l'inscription n'a pas lieu — les deux sont visibles ici. »

*(Optionnel : le faire en direct si le temps le permet.)*

## Bloc 8 — Limites et conclusion (11:45 → 13:00) · 1 min 15

**À l'écran** : page « Limites et risques résiduels » du document.

**À dire** :
> « Ce que nous assumons : le paiement est simulé, il n'y a pas de serveur mail, et la
> signature du webhook est envoyée mais pas encore vérifiée côté n8n.
> Enfin, le service de test sera retiré avant la remise.
> Ce que nous retenons : une plateforme simple, reproductible, où chaque choix est justifié,
> et dont les limites sont écrites noir sur blanc. Merci. »

---

## Règles à respecter pendant l'enregistrement

- **Ne jamais dépasser 15:59** : viser 13 minutes. Si un bloc déborde, couper le bloc 7.
- Ne pas montrer de mot de passe à l'écran (flouter ou taper hors champ).
- Ne jamais montrer de mot de passe à l'écran.
- Énoncer chaque commande avant de la lancer : la vidéo doit être compréhensible sans son.
- Héberger sur **Microsoft 365 / Stream** de l'université et vérifier les droits d'accès.

## Répartition de la parole (suggestion)

| Bloc | Intervenant |
|---|---|
| 1, 3, 8 | Coordination / architecture |
| 2 | Socle VM as Code |
| 4, 6 | Sécurité et identité |
| 5 | Intégration et applications |
| 7 | Exploitation |

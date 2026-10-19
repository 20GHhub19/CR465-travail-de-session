# Limites et risques résiduels

## Limites fonctionnelles

| Limite | Détail |
|---|---|
| Paiement **simulé** | Passerelle `example_onsite` de Drupal Commerce ; aucun encaissement réel. Autorisé par l'énoncé. |
| Devise **USD** | Le référentiel de devises de cette installation ne contient que l'USD ; le produit est donc en USD et non en CAD. |
| Pas de SMTP | Aucun serveur de mail dans la stack : Drupal journalise un échec d'envoi, sans impact sur le parcours. |
| Création de compte Moodle | n8n n'inscrit que des utilisateurs **déjà connus** de Moodle (provisionnés par le premier login SSO). La création automatique par n8n reste à ajouter. |
| Signature du webhook | Drupal envoie un HMAC (`X-CR465-Signature`) mais n8n ne le **vérifie pas encore**. |
| Single logout | La déconnexion Moodle ne ferme pas la session Keycloak. |

## Risques résiduels assumés

| Risque | Justification / compensation |
|---|---|
| `adminops` dans le groupe `docker` | Équivaut à root sur l'hôte. Compte à clé SSH, root SSH désactivé, fail2ban. |
| `socket-proxy-admin` en écriture | Nécessaire à Portainer. Réseau `socket` isolé, service non exposé, UI restreinte par IP. |
| Certificat auto-signé | Pas de domaine public ; AC locale générée par script et distribuée aux conteneurs. |
| Réseau `egress` ouvert | Limité à Moodle, n8n et Drupal (installation et webhooks). |
| `curlsecurityblockedhosts` vidé dans Moodle | Protection SSRF désactivée ; compensée par la segmentation réseau. |
| Aucun WAF | Bonus OpenAppSec non engagé (+2 hors total). |

## Limites techniques

- Une **seule VM** : pas de haute disponibilité, pas de répartition de charge.
- Aucune sauvegarde automatisée des volumes (PostgreSQL, Moodle, Drupal).
- Pas de supervision des ressources (CPU, mémoire) au-delà des limites Docker.
- Pas de CI/CD : les scripts sont exécutés manuellement.

## Améliorations prioritaires

1. Vérifier la signature HMAC dans n8n et rendre le workflow **idempotent**.
2. Créer automatiquement l'utilisateur Moodle s'il n'existe pas (`core_user_create_users`).
3. Déployer Loki + Grafana et exporter les journaux Traefik.
4. Retirer `whoami` et verrouiller les versions par digest (`@sha256:`).
5. Mettre en place des sauvegardes (dump PostgreSQL chiffré, export des volumes).

# Drupal Commerce — boutique et déclenchement du parcours

## Rôle dans l'architecture

```
Utilisateur → Drupal Commerce (achat, paiement simulé)
                    │ webhook signé (module cr465_notify)
                    ▼
                  n8n → API Moodle → inscription au cours
```

## Déploiement

```bash
./scripts/configure-drupal.sh
```

Le script installe le site si nécessaire, active les modules Commerce, crée la
boutique, le produit et la passerelle de paiement simulé, puis configure le webhook.

## Pourquoi une image Drupal dérivée

`compose/drupal/Dockerfile` part de `drupal:10.6.19-php8.4-apache` et ajoute :

| Ajout | Raison |
|---|---|
| `bcmath` | Obligatoire pour Drupal Commerce (calculs de prix) — absent de l'image officielle |
| `intl` | Internationalisation |
| `drush` | Administration en ligne de commande |
| `drupal/commerce` | **Baké dans l'image** : aucun téléchargement au démarrage, déploiement reproductible |
| `cr465_notify` | Module custom qui appelle n8n quand une commande est payée |
| `entrypoint.sh` | Recrée `settings.php` au premier démarrage (le dossier `sites/default` est un volume) |

## Le module `cr465_notify`

Sur `hook_entity_update` d'une commande, si l'état passe à `completed` :

1. récupère l'email du client ;
2. construit un payload `{order_id, email, total, currency}` ;
3. ajoute un en-tête `X-CR465-Signature` (HMAC-SHA256) si un secret est configuré ;
4. poste sur `https://flow.cr465.test/webhook/commande` ;
5. journalise le résultat dans le log Drupal (`cr465_notify`).

Configuration :

```bash
docker exec -w /opt/drupal cr465-drupal vendor/bin/drush config:set \
  cr465_notify.settings webhook_url "https://flow.cr465.test/webhook/commande" -y
```

## Simuler un achat (démonstration)

```bash
docker exec -w /opt/drupal cr465-drupal vendor/bin/drush php:script \
  scripts/simulate-purchase.php acheteur@cr465.test
```

Le script crée une commande, y ajoute la formation, puis la passe à `completed`
(paiement simulé). Le webhook part immédiatement.

## Trois pièges rencontrés

### 1. `cap_drop: ALL` empêchait l'installation

Sans `CAP_DAC_OVERRIDE`, root ne peut pas écrire dans les dossiers appartenant à
`www-data` — l'installation échouait sur `copy(settings.php)`. Les capacités
`CHOWN`, `DAC_OVERRIDE`, `FOWNER`, `SETUID`, `SETGID` ont été ajoutées au service.

### 2. `settings.php` perdu à chaque recréation

Le code est dans l'image, mais `settings.php` est généré. Solution : volume
`drupal_settings` + `entrypoint.sh` qui le recrée depuis un modèle baké.

### 3. Devise `CAD` introuvable

Cette installation ne connaît que `USD` (le référentiel de devises n'est pas
importé). Le produit et la boutique utilisent donc **USD** — à remplacer par CAD
après import du référentiel de devises.

## État vérifié

| Élément | Résultat |
|---|---|
| Boutique `https://shop.cr465.test/` | **200** — « CR465 Formation » |
| Page produit | **200** — « Formation CR465 - Initiation aux conteneurs », 49.00 |
| Panier | **200** |
| Commande complétée | notification n8n **HTTP 200** |
| Chaîne complète | achat → n8n → **inscription Moodle créée** |

## Limites

- **Paiement** : passerelle `example_onsite` (simulation). Aucun encaissement réel.
- **Checkout** : le parcours panier → paiement est fonctionnel côté Commerce, mais
  la démonstration automatisée passe par `simulate-purchase.php`.
- **Email** : aucun serveur SMTP dans la stack ; Drupal journalise un échec d'envoi
  (sans impact sur le parcours).
- **Signature** : l'en-tête HMAC est envoyé, mais n8n ne le vérifie pas encore.

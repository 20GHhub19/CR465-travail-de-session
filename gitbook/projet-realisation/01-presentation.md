# Présentation du projet

## Mandat

Déployer sur **une seule VM Linux**, initialisée par **cloud-init** et orchestrée par
**Docker Compose**, une plateforme de formation en ligne composée de services open source
intégrés :

- **Drupal Commerce** — catalogue et vente des formations ;
- **n8n** — orchestration visuelle entre la vente et l'accès ;
- **Moodle** — plateforme de consommation des cours ;
- **Keycloak** — identité unique et SSO ;
- **PostgreSQL** — base unique, une base logique par service ;
- **Traefik** — point d'entrée HTTPS unique ;
- **Portainer CE** — exploitation graphique des conteneurs.

## Parcours fonctionnel démontré

1. Un visiteur consulte une offre de formation sur la boutique.
2. Il « achète » la formation (paiement **simulé**, aucun encaissement réel).
3. La commande passe à l'état *completed* ; un webhook est envoyé à n8n.
4. n8n retrouve l'apprenant dans Moodle et l'inscrit au cours correspondant.
5. L'apprenant se connecte à Moodle via **Keycloak** (SSO) et accède au cours.

## Ce que le projet démontre

| Domaine | Démonstration |
|---|---|
| Infrastructure as Code | VM entièrement reproductible depuis un fichier cloud-init |
| Sécurité des images | versions épinglées, scan local Trivy |
| Sécurité à l'exécution | non-root, `cap_drop: ALL`, `no-new-privileges`, `read_only`, limites |
| Segmentation réseau | 5 réseaux, services de données non exposés |
| Identité | realm Keycloak déclaratif, SSO OIDC Moodle vérifié |
| Intégration | parcours achat → inscription démontré de bout en bout |
| Observabilité | Portainer CE, journaux d'accès Traefik en JSON |

## Approche

Le projet privilégie **la simplicité maîtrisée** : chaque service est déployé, configuré et
expliqué, plutôt que multiplié. Les écarts et limites sont documentés explicitement
(voir [Limites et risques résiduels](10-limites-risques.md)).

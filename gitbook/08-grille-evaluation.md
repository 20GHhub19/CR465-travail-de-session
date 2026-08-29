# 8. Grille d'évaluation

Voici comment votre travail sera évalué. Ce tableau est un résumé condensé — pour la répartition détaillée par critère (barèmes Excellent / Satisfaisant / Fragile / Insuffisant), consultez `md/grille_correction_travail_session_containers.md`, qui fait foi en cas de divergence.

| Critère | Ce qui est évalué | Points |
|---|---|---:|
| VM as Code avec cloud-init | Présence d'un vrai fichier cloud-init, utilité réelle, automatisation de l'utilisateur, SSH, mises à jour, Docker, pare-feu hôte, préparation de l'hôte | 5 |
| Architecture et schéma | Lisibilité, cohérence, zones de confiance, flux, exposition, parcours métier | 5 |
| Déploiement conteneurisé | Qualité de la stack Docker Compose, structure, dépendances, reproductibilité (bonus qualitatif si Opencast ou Redis intégrés) | 3 |
| Sécurité des images | Versions explicites, choix d'images, scan local/hors-ligne (ex. Trivy, Grype) sans dépendance à un service cloud, provenance | 3 |
| Sécurité à l'exécution | Non-root, absence de mode privilégié, réduction des privilèges, options de sécurité, montages prudents, ressources | 5 |
| Segmentation réseau | Réseaux d'exposition, applicatifs, données, exposition minimale, flux justifiés | 3 |
| Intégration Drupal Commerce → n8n → Moodle | Cohérence du parcours métier, vente, automatisation, attribution d'accès, démonstration | 3 |
| IAM et SSO | Keycloak, SSO Moodle, compréhension des flux d'authentification | 3 |
| Reverse proxy | Rôle de Traefik, centralisation de l'exposition | 3 |
| Observabilité et exploitation | Usage de Portainer CE, états des conteneurs, journaux, diagnostic, éventuellement Grafana/Loki | 3 |
| Qualité des livrables | Vidéo M365 conforme, GitBook, GitHub, document Word/PPT, cohérence globale, traçabilité des contributions individuelles | 4 |
| **Total** |  | **40** |
| **Bonus — WAF (OpenAppSec)** | Ajout d'un WAF fonctionnel en frontal de Traefik, configuré en mode local et expliqué — voir [6. Bonus — WAF](06-bonus-waf-openappsec.md) | **+2 (hors total)** |

## Pénalités majeures

Certaines situations (secrets committés, conteneurs privilégiés, services sensibles exposés publiquement, etc.) entraînent des pénalités importantes — voir [9. Pénalités majeures](09-penalites-majeures.md) pour la liste complète.

# 02 — Comprendre et étendre le Taskfile

## Pourquoi Task plutôt que des commandes copiées-collées

`Taskfile.yml` centralise les commandes répétitives dans un seul fichier YAML lisible, plutôt que
de les faire circuler dans un README ou un historique de terminal. C'est un outil optionnel, non noté
dans la grille — il vous sert seulement à démontrer proprement votre déploiement en vidéo.

## Commandes fournies

```
task --list       # affiche toutes les tâches disponibles avec leur description
task up           # démarre la stack (docker compose up -d)
task down         # arrête la stack
task restart      # redémarre la stack
task logs         # journaux en continu
task ps           # état des conteneurs
task pull         # télécharge les dernières images
task validate     # valide la syntaxe du docker-compose.yml
task scan         # scan de vulnérabilité local (voir 04-scan-vulnerabilites.md)
task clean        # arrête la stack ET supprime les volumes (irréversible)
```

## Ajouter une tâche pour un nouveau service

Au fil du projet, vous ajouterez Keycloak, n8n, Moodle, etc. à `compose/docker-compose.yml`.
Vous pouvez ajouter des tâches dédiées dans `Taskfile.yml`, par exemple :

```yaml
  logs-keycloak:
    desc: Journaux du service Keycloak uniquement
    dir: '{{.COMPOSE_DIR}}'
    cmds:
      - docker compose logs -f keycloak
```

## Limites à connaître

- Task ne remplace pas Docker Compose : il ne fait qu'appeler les commandes `docker compose ...`
  pour vous.
- N'utilisez pas les fonctionnalités avancées de Task (templating complexe, `includes` multi-fichiers,
  cache par somme de contrôle) pour ce projet — elles ajoutent de la complexité sans bénéfice pour
  les critères notés.

# 04 — Scan de vulnérabilité local

## Pourquoi un scan local et hors-ligne

La contrainte #10 de l'énoncé exige que les mécanismes de scan d'images utilisent des outils
locaux ou hors-ligne (ex. Trivy, Grype) plutôt qu'un service cloud, pour respecter l'exigence de
souveraineté du projet. `task scan` répond directement à cette exigence et au critère
« Sécurité des images ».

## Ce que fait `task scan`

Pour chaque image utilisée par `docker-compose.yml`, la tâche lance un conteneur **Trivy**
(`ghcr.io/aquasecurity/trivy:0.74.0`) qui scanne l'image localement, sans envoyer de données à un
service externe, et n'affiche que les vulnérabilités de sévérité **HIGH** ou **CRITICAL**.

```
task scan
```

## Interpréter les résultats

- Chaque ligne du rapport indique un paquet vulnérable, sa version, la CVE associée et la sévérité.
- `--exit-code 0` signifie que le scan ne fait pas échouer la commande même en cas de vulnérabilité
  trouvée — c'est volontaire pour ce kit pédagogique. Une fois à l'aise, vous pouvez changer cette
  valeur à `1` pour bloquer un déploiement si des vulnérabilités critiques sont détectées.

## Documenter dans vos livrables

Montrez au moins une exécution de `task scan` dans votre vidéo ou votre GitBook, et expliquez
comment vous avez réagi aux résultats (mise à jour d'une image, changement de version, acceptation
justifiée d'un risque résiduel). C'est ce que le correcteur cherche pour le critère
« Sécurité des images » : une démonstration réelle, pas seulement une affirmation.

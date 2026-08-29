# 02 — gVisor vs runc : quand l'utiliser, comment vérifier, quelles limites

## Pourquoi seul `whoami` utilise `runtime: runsc`

Dans `compose/docker-compose.yml`, Traefik reste sur le runtime standard (`runc`) et `whoami`
utilise `runtime: runsc`. Le principe : sandboxez les **conteneurs applicatifs qui traitent des
entrées non fiables** (dans votre projet complet : Drupal Commerce, Moodle, n8n), pas votre
reverse proxy de confiance. Le réseau de gVisor passe par une pile réseau en espace utilisateur
(« netstack »), ce qui ajoute une latence — acceptable pour la plupart des applications web, mais à
éviter sur un composant aussi sensible à la performance que le point d'entrée de toute la stack.

## Ajouter `runtime: runsc` à un nouveau service

```yaml
  mon-service:
    image: mon-image:1.0.0
    runtime: runsc
    networks:
      - edge
```

## Vérifier qu'un conteneur tourne bien sous gVisor

```
task verify-sandbox
```

Une vérification alternative existe via `dmesg` à l'intérieur du conteneur :

```
docker run --runtime=runsc -it ubuntu dmesg
```

**Important** — la documentation officielle de gVisor précise que cette sortie `dmesg` est
facilement imitée par un attaquant : ne vous fiez jamais à `dmesg` seul pour confirmer l'isolation
dans un contexte réellement sensible à la sécurité. Utilisez plutôt `docker inspect` (voir
`task verify-sandbox`) ou la configuration du démon (`/etc/docker/daemon.json`) comme preuve
recevable dans votre GitBook.

## Limites à connaître avant d'étendre l'usage de gVisor

- **Compatibilité applicative incomplète** : gVisor ne réimplémente pas 100 % de la surface
  d'appels système Linux. Certaines applications (accès matériel spécifique, certaines
  fonctionnalités de `ptrace`, etc.) peuvent ne pas fonctionner sans adaptation. Consultez la liste
  de compatibilité officielle avant d'appliquer `runtime: runsc` à un service critique de votre
  stack.
- **Surcoût de performance** : attendez-vous à un surcoût sur les charges réseau ou syscall-intensives.
  Testez chaque service individuellement après l'avoir basculé sur `runsc`.
- **Un seul type de sandbox parmi d'autres** : gVisor complète mais ne remplace pas les autres
  bonnes pratiques déjà en place (non-root, `no-new-privileges`, segmentation réseau). Documentez-le
  comme une couche additionnelle de défense en profondeur, pas comme la seule protection.

## Documenter dans vos livrables

Montrez `task verify-sandbox` dans votre vidéo ou GitBook pour au moins un service applicatif réel
(pas seulement `whoami`), et expliquez votre choix des services à sandboxer ainsi que les limites
que vous avez rencontrées.

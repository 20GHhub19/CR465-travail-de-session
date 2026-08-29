# 02 — Limites et dépannage du mode rootless

## Limites connues à anticiper

- **Réseau plus lent** : `slirp4netns` ajoute un surcoût de traduction réseau par rapport au mode
  rootful. Pour cette stack minimale (Traefik + un service de test), l'impact est négligeable, mais
  gardez ce compromis en tête si vous étendez fortement la stack.
- **Fonctionnalités réseau avancées indisponibles** : pas de pilote `macvlan`, par exemple. Pour ce
  projet (une seule VM, réseaux Docker de type bridge), ce n'est pas une contrainte.
- **Certaines images supposent un contexte root classique** : la plupart des images officielles
  fonctionnent normalement en rootless, mais si un service de votre stack échoue de façon
  inattendue, vérifiez d'abord s'il tente une opération qui suppose des privilèges root sur l'hôte
  (rare, mais à envisager avant de perdre du temps ailleurs).
- **Dépendance à systemd et à `loginctl enable-linger`** : sans cette étape, le démon rootless
  s'arrête à la déconnexion de la session SSH.

## Dépannage rapide

| Symptôme | Piste |
|---|---|
| `docker: command not found` en SSH | Le profil `.bashrc` n'a pas été rechargé — reconnectez-vous ou lancez `source ~/.bashrc`. |
| `Cannot connect to the Docker daemon` | Vérifiez `echo $DOCKER_HOST` et `systemctl --user status docker`. |
| Traefik ne démarre pas sur le port 80 | Vérifiez `sysctl net.ipv4.ip_unprivileged_port_start` (doit être ≤ 80). |
| Le démon s'arrête après déconnexion SSH | Vérifiez `loginctl show-user admin \| grep Linger` (doit être `yes`). |

## Alternative à considérer si le rootless complet ajoute trop de friction

Si votre équipe veut réduire le risque « root du conteneur = root de l'hôte » sans gérer toute la
configuration rootless ci-dessus, `userns-remap` (remappage des espaces de noms utilisateur) est
une option plus simple : le démon Docker reste root, mais le UID root *à l'intérieur* des conteneurs
est mappé vers un UID non privilégié côté hôte. Consultez la documentation officielle Docker sur
`userns-remap` si vous choisissez cette voie intermédiaire — elle n'est pas couverte par ce kit.

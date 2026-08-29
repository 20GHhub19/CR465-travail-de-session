# 00 — Introduction au kit de démarrage

## Ce que ce kit fournit

Ce kit couvre uniquement la « plomberie » suivante :

- un fichier cloud-init qui prépare une VM Ubuntu (utilisateur, SSH, mises à jour, pare-feu, Docker, Task);
- un `docker-compose.yml` minimal avec **Traefik** (reverse proxy) et un service de test **whoami**;
- un `Taskfile.yml` avec des commandes courantes (`up`, `down`, `logs`, `scan`, etc.);
- une tâche `task scan` qui exécute **Trivy** localement, hors-ligne, sur les images de la stack.

## Ce que ce kit ne fournit PAS

Tout le reste du mandat reste à réaliser par votre équipe : Drupal Commerce, Moodle, Keycloak, n8n,
Opencast (optionnel), Redis (bonus), Portainer CE, OpenAppSec, la segmentation réseau complète,
le SSO, l'observabilité avancée, etc. Ce kit ne résout aucun des critères notés — il évite seulement
de réécrire la même plomberie de base que chaque équipe referait de toute façon.

## Traçabilité de vos contributions

L'énoncé exige que les contributions individuelles soient identifiables. Indiquez clairement dans
votre README/GitBook ce qui provient de ce kit de démarrage (inchangé) et ce que votre équipe a
ajouté ou modifié, pour que le correcteur puisse juger votre travail réel.

## Ordre de lecture suggéré

1. `01-cloud-init-et-vm.md` — comprendre et démarrer la VM.
2. `02-taskfile.md` — comprendre Task et étendre les tâches au fil du projet.
3. `03-traefik.md` — comprendre la stack Traefik/whoami et y ajouter vos propres services.
4. `04-scan-vulnerabilites.md` — comprendre et utiliser le scan de vulnérabilité local.

## Variantes disponibles

Deux variantes de ce même kit existent, si vous souhaitez pousser le durcissement de l'hôte plus
loin (facultatif, non requis par l'énoncé) :

- `starter-kit-rootless/` — Docker en mode rootless.
- `starter-kit-podman/` — Podman (rootless par défaut), désormais accepté comme moteur équivalent
  à Docker Compose selon la contrainte #2 de l'énoncé.

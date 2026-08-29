# 00 — Introduction (variante gVisor)

## Ce que gVisor ajoute

gVisor (`runsc`) est un runtime de conteneur qui intercepte les appels système entre un conteneur
et le noyau de l'hôte, via un composant en espace utilisateur appelé le **Sentry**. Concrètement,
un conteneur exécuté avec `runtime: runsc` ne parle plus directement au noyau Linux : gVisor
réimplémente une bonne partie de la surface d'appels système, ce qui réduit fortement l'impact
d'une vulnérabilité noyau exploitée depuis l'intérieur d'un conteneur compromis.

## Un axe différent de rootless / Podman

Ce kit ne remplace pas `starter-kit-rootless/` ni `starter-kit-podman/` — il agit sur un axe
différent :

| Kit | Ce qu'il durcit |
|---|---|
| `starter-kit-rootless/`, `starter-kit-podman/` | Le **privilège du démon** (root ou non sur l'hôte) |
| `starter-kit-gvisor/` | La **surface d'appels système** entre le conteneur et le noyau |

Ces deux axes sont complémentaires et combinables (gVisor fonctionne aussi avec Podman ou en mode
rootless) — ce kit reste construit sur la base Docker « rootful » de `starter-kit/` pour rester
simple à suivre.

## Ce que ce kit ne fournit toujours pas

Comme les autres kits : Drupal Commerce, Moodle, Keycloak, n8n, Opencast, Redis, Portainer CE,
OpenAppSec restent à réaliser par votre équipe.

## Ordre de lecture suggéré

1. `01-cloud-init-et-vm.md` — installation de gVisor sur la VM.
2. `02-gvisor-vs-runc.md` — quand utiliser `runtime: runsc`, ses limites, comment vérifier.

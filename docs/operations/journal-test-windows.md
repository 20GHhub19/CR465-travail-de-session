# Journal de test — Windows 11 + Hyper-V

> À remplir au fur et à mesure. Chaque case cochée doit être appuyée par la sortie réelle
> de la commande, à coller dans le tableau. Ce journal alimente la section « tests » du GitBook
> et le segment 2 de la vidéo.

## Informations machine

| Élément | Valeur |
|---|---|
| Version de Windows | |
| Architecture | |
| RAM | |
| Date du test | |
| Testeur | |

## Étape 1 — Virtualisation

- [ ] Virtualisation active dans le BIOS/UEFI (VT-x ou AMD-V)
- [ ] Hyper-V activé (fonctionnalité Windows)
- [ ] Plateforme d'hyperviseur Windows activée
- [ ] Redémarrage effectué

**Vérification** (PowerShell administrateur) :

```powershell
systeminfo | Select-String "Hyper-V"
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V | Select State
```

Sortie obtenue :
```
(coller ici)
```

## Étape 2 — Outils

- [ ] Git pour Windows installé
- [ ] Multipass installé
- [ ] Terminal ouvert en **Git Bash** (pas cmd, pas PowerShell)

**Vérification** :

```bash
git --version
multipass version
multipass networks
```

Sortie obtenue :
```
(coller ici)
```

## Étape 3 — Contrôle du poste

```bash
cd /c/Users/<utilisateur>/CR465-travail-de-session
bash scripts/check-platform.sh
```

Attendu : `Windows (Git Bash)`, `linux/amd64`, `Hyper-V : active`, 8 images `OK`.

Sortie obtenue :
```
(coller ici)
```

## Étape 4 — Création de la VM par cloud-init

```bash
bash scripts/launch-vm.sh vm-cr465-d
multipass info vm-cr465-d
```

Attendu : `State: Running`, IPv4 renseignée, 4 CPU, 8 Go, 60 Go.

Sortie obtenue :
```
(coller ici)
```

**Preuve que cloud-init a fait le travail** :

```bash
multipass exec vm-cr465-d -- cloud-init status --long
multipass exec vm-cr465-d -- sudo ufw status verbose
multipass exec vm-cr465-d -- sudo fail2ban-client status sshd
multipass exec vm-cr465-d -- docker --version
multipass exec vm-cr465-d -- id adminops
```

Sortie obtenue :
```
(coller ici)
```

## Étape 5 — Déploiement

```bash
bash scripts/mount-compose.sh vm-cr465-d
cp compose/.env.example compose/.env     # renseigner les secrets
bash scripts/deploy-stack.sh vm-cr465-d
```

Attendu : 9 conteneurs `Up`, dont 6 `(healthy)`.

Sortie obtenue :
```
(coller ici)
```

## Étape 6 — Routage et parcours

```bash
bash scripts/test-routing.sh vm-cr465-d
```

Attendu : HTTPS répond `200` ou `303`, HTTP redirige `301`.

Sortie obtenue :
```
(coller ici)
```

## Étape 7 — Accès navigateur (optionnel)

Les domaines `*.cr465.test` ne sont pas résolus par le DNS public. Pour ouvrir la boutique
dans un navigateur Windows, ajouter les entrées suivantes dans
`C:\Windows\System32\drivers\etc\hosts` (bloc-notes **en administrateur**) :

```
<IP_DE_LA_VM>  shop.cr465.test
<IP_DE_LA_VM>  lms.cr465.test
<IP_DE_LA_VM>  auth.cr465.test
<IP_DE_LA_VM>  flow.cr465.test
<IP_DE_LA_VM>  admin.cr465.test
```

- [ ] Boutique accessible
- [ ] Moodle accessible
- [ ] Keycloak accessible

## Incident éventuel

| Symptôme | Cause probable | Résolution |
|---|---|---|
| `multipass launch` échoue | Hyper-V inactif | activer + redémarrer |
| chemin `/opt/...` transformé | Git Bash convertit les chemins | lancer depuis Git Bash (MSYS_NO_PATHCONV déjà présent) |
| montage refusé | montages privilégiés désactivés | `multipass set local.privileged-mounts=true` en PowerShell admin |
| VM lente | premier téléchargement d'image | attendre 5 à 10 min |

## Conclusion

| Critère | Résultat |
|---|---|
| VM créée par cloud-init | ☐ oui ☐ non |
| Stack complète opérationnelle | ☐ oui ☐ non |
| Parcours achat → Moodle | ☐ oui ☐ non |
| Remarques | |

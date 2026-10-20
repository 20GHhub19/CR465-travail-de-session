# Windows — commandes à exécuter dans l'ordre

> À suivre dans **Git Bash** (jamais `cmd`, jamais PowerShell — sauf mention contraire).
> Chaque bloc indique le résultat attendu. Si un bloc ne donne pas le résultat attendu,
> arrête-toi et note la sortie.

## 0. Préparation (une seule fois)

**a. PowerShell en administrateur** :

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -All
```

Redémarrer le PC.

**b. Vérification après redémarrage** (PowerShell) :

```powershell
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V | Select State
```

Attendu : `Enabled`.

**c. Installer** :
- Git pour Windows : https://git-scm.com/download/win
- Multipass : https://multipass.run/install

## 1. Récupérer le dépôt

```bash
cd /c/Users/$USERNAME
git clone https://github.com/20GHhub19/CR465-travail-de-session.git
cd CR465-travail-de-session
git checkout Projet-CR465-D-Maxime
```

Attendu : la branche `Projet-CR465-D-Maxime` est active.

## 2. Contrôle du poste

```bash
bash scripts/check-platform.sh
```

Attendu :

```
Systeme                      Windows (Git Bash)
Architecture                 amd64
git                          OK
multipass                    OK
Hyper-V                      active
Images epinglees — support linux/amd64 : 8 × OK
Bilan : ... manquant(s) : 0
```

**Envoie cette sortie** — c'est le premier point de contrôle.

## 3. Les secrets

Le fichier `compose/.env` n'est pas versionné. Deux choix :

**Option A — copier depuis le Mac** (recommandé, 2 min)
Copier `compose/.env` du Mac vers le même chemin sur le PC (clé USB, OneDrive, AirDrop).

**Option B — générer sur place**
```bash
cp compose/.env.example compose/.env
```

Puis renseigner chaque valeur. Les secrets peuvent être générés ainsi :

```bash
for k in POSTGRES_PASSWORD DRUPAL_DB_PASSWORD MOODLE_DB_PASSWORD KEYCLOAK_DB_PASSWORD \
         N8N_DB_PASSWORD N8N_ENCRYPTION_KEY MOODLE_OIDC_CLIENT_SECRET \
         MOODLE_WS_TOKEN KC_ADMIN_PASSWORD DRUPAL_ADMIN_PASSWORD; do
  echo "$k=$(openssl rand -hex 24)"
done
```

> ⚠️ Ne jamais committer ce fichier. Il est déjà dans `.gitignore`.

## 4. Créer la VM (cloud-init)

```bash
bash scripts/launch-vm.sh vm-cr465-d
```

Attendu : progression `Retrieving image` puis `Launched: vm-cr465-d`.

```bash
multipass info vm-cr465-d
```

Attendu : `State: Running`, une IPv4, 4 CPU, 8 Go, 60 Go.

## 5. Preuve que cloud-init a travaillé

```bash
multipass exec vm-cr465-d -- cloud-init status --long
multipass exec vm-cr465-d -- sudo ufw status verbose
multipass exec vm-cr465-d -- sudo fail2ban-client status sshd
multipass exec vm-cr465-d -- docker --version
multipass exec vm-cr465-d -- id adminops
```

Attendu :

| Commande | Résultat attendu |
|---|---|
| `cloud-init status --long` | `status: done` |
| `ufw status verbose` | `Status: active`, ports 22/80/443 autorisés |
| `fail2ban-client status sshd` | `Currently banned: 0` |
| `docker --version` | Docker installé par cloud-init |
| `id adminops` | utilisateur présent, groupes `sudo docker` |

**C'est la preuve VM as Code** — à filmer pour le segment 2.

## 6. Monter le compose et déployer

```bash
bash scripts/mount-compose.sh vm-cr465-d
```

Si le script demande une élévation : PowerShell **administrateur** →
`multipass set local.privileged-mounts=true`, puis relancer.

```bash
cp compose/.env.example compose/.env    # seulement si option B
bash scripts/deploy-stack.sh vm-cr465-d
```

Attendu : 9 conteneurs `Up`.

## 7. Vérifier le routage

```bash
bash scripts/test-routing.sh vm-cr465-d
```

Attendu : HTTPS `200` ou `303`, HTTP `301` vers HTTPS.

## 8. Navigateur (facultatif)

Récupérer l'IP :

```bash
multipass info vm-cr465-d | grep IPv4
```

Éditer `C:\Windows\System32\drivers\etc\hosts` **en administrateur** (Bloc-notes → Ouvrir →
chemin complet) et ajouter, avec l'IP réelle :

```
192.168.64.X  shop.cr465.test
192.168.64.X  lms.cr465.test
192.168.64.X  auth.cr465.test
192.168.64.X  flow.cr465.test
192.168.64.X  admin.cr465.test
```

Puis `ipconfig /flushdns` et ouvrir `https://shop.cr465.test/`.

Le certificat est signé par l'AC locale : accepter l'avertissement du navigateur.

## Ce qu'il faut rapporter

1. Sortie de `check-platform.sh`
2. Sortie de `multipass info`
3. Sortie des 5 commandes de l'étape 5
4. Sortie de `test-routing.sh`
5. Une capture de la boutique

→ à consigner dans `docs/operations/journal-test-windows.md`.

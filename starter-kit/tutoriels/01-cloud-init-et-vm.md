# 01 — Cloud-init et démarrage de la VM

## Ce que fait `cloud-init/user-data.yaml`

| Section | Rôle |
|---|---|
| `users` | Crée l'utilisateur `admin`, membre des groupes `sudo` et `docker`, avec sudo sans mot de passe et connexion **par clé SSH uniquement** (`lock_passwd: true`). |
| `ssh_pwauth: false` | Désactive l'authentification SSH par mot de passe sur toute la VM. |
| `package_update` / `package_upgrade` | Applique les mises à jour de sécurité disponibles au premier démarrage. |
| `packages` | Installe les prérequis (`curl`, `gnupg`, `ufw`, etc.). |
| `write_files` | Dépose un `README.txt` dans `/opt/stack` pour rappeler la suite des étapes. |
| `runcmd` | Installe Docker Engine (dépôt officiel), Task (dépôt officiel Cloudsmith), configure le pare-feu `ufw` et prépare `/opt/stack`. |

## Avant de démarrer une VM avec ce fichier

Remplacez la ligne `ssh_authorized_keys` par votre propre clé publique :

```
ssh-keygen -t ed25519 -C "votre-email"
cat ~/.ssh/id_ed25519.pub
```

Collez le résultat à la place de `AAAAC3NzaC1lZDI1NTE5AAAA... remplacez-moi-par-votre-cle-publique`.

## Démarrer la VM

La méthode dépend de votre fournisseur (le fichier `user-data.yaml` est un cloud-config standard,
compatible avec la plupart des hyperviseurs et fournisseurs cloud) :

- **Fournisseur cloud (ex. interface web ou CLI)** : collez le contenu du fichier dans le champ
  « User data » / « Cloud-init » lors de la création de la VM.
- **Test local avec Multipass** :
  ```
  multipass launch --name starter-kit-vm --cloud-init cloud-init/user-data.yaml
  ```

## Vérifier que cloud-init a terminé

```
ssh admin@<IP_DE_LA_VM>
cloud-init status --wait
docker --version
task --version
```

## Étape suivante

Copiez (ou clonez) le contenu de `compose/` et `Taskfile.yml` dans `/opt/stack` sur la VM, puis
lancez `task up` — voir `03-traefik.md`.

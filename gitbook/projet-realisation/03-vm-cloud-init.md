# VM as Code — cloud-init

## Fichier

`cloud-init/user-data.yaml` — transforme une Ubuntu Server 24.04 vierge en hôte durci prêt
à exécuter la stack, sans étape manuelle.

## Ce que cloud-init configure automatiquement

| Domaine | Configuration |
|---|---|
| Utilisateur | `adminops`, clé SSH uniquement, mot de passe verrouillé, groupes `sudo` et `docker` |
| SSH | `PermitRootLogin no`, `PasswordAuthentication no`, `MaxAuthTries 3`, `X11Forwarding no` |
| Mises à jour | mise à jour complète au premier démarrage + `unattended-upgrades` |
| Docker | Docker Engine + Compose depuis le dépôt officiel (clé GPG vérifiée) |
| Démon Docker | `no-new-privileges` par défaut, logs bornés (3 × 10 Mo) |
| Pare-feu | UFW : tout refusé en entrée sauf 22, 80, 443 |
| Anti-bruteforce | fail2ban : 3 essais → bannissement 1 h |
| Noyau | anti-spoofing, pas de redirections ICMP, SYN cookies, ASLR |
| Répertoires | `/opt/cr465-groupe-d/compose` |

## Reproduction

```bash
./scripts/launch-vm.sh          # Multipass + cloud-init
multipass info vm-cr465-d
ssh adminops@<IP>
```

Vérification dans la VM :

```bash
cloud-init status --long          # doit afficher "done"
sudo ufw status verbose           # seuls 22, 80, 443
sudo sshd -T | grep permitrootlogin
sudo fail2ban-client status sshd
```

## Limites de l'automatisation

- La **clé SSH publique** doit être renseignée dans le fichier avant le lancement :
  c'est le seul élément propre à chaque poste.
- Le projet suppose une architecture `amd64` ou `arm64` avec images multi-arch.
- `adminops` appartient au groupe `docker`, ce qui équivaut à **root sur l'hôte** :
  risque résiduel assumé (voir [Limites](10-limites-risques.md)).
- La reproductibilité a été démontrée par destruction/recréation complète de la VM.

## Preuve de reproductibilité

Un incident Multipass/Hyper-V sous Windows a détruit la VM en cours de projet ; elle a été
reconstruite à l'identique depuis le même `user-data.yaml`. Cet incident est documenté dans
`docs/operations/incident-multipass-windows.md`.

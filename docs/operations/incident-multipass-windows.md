# Incident — Multipass sur Windows (contournement)

## Symptômes
- `exec/info failed: Failed to resolve hostname <vm>.mshome.net`
- VM en `Running` mais `IPv4: N/A`
- `cannot connect to the multipass socket` (daemon figé)
- `launch failed: Failed to copy ...vhdx` après bascule de moteur

## Cause
Conflit entre **Hyper-V** (moteur Multipass par défaut) et **VirtualBox**
installé en parallèle : réseau Hyper-V instable, puis image en cache au
format `.vhdx` incompatible avec VirtualBox.

## Contournement appliqué
1. Réinstaller Multipass en choisissant le moteur **VirtualBox**.
2. Désactiver Hyper-V : `bcdedit /set hypervisorlaunchtype off` + redémarrage.
3. Vider le cache Multipass (PowerShell admin) :
   - `Stop-Service Multipass`
   - supprimer `C:\ProgramData\Multipass\data\vault\instances\<vm>`
   - supprimer `C:\ProgramData\Multipass\cache\*`
   - `Start-Service Multipass`
4. Relancer : `bash scripts/launch-vm.sh <nom>`.

## Leçon
L'approche VM as Code (cloud-init) a permis de tout reconstruire à
l'identique après ces incidents — la VM est jetable et reproductible.

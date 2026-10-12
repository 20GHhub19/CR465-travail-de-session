# Incident — Multipass sur Windows (contournement)

## Symptômes
- `exec/info failed: Failed to resolve hostname <vm>.mshome.net`
- VM en `Running` mais `IPv4: N/A`
- `cannot connect to the multipass socket` (daemon figé)
- `launch failed: Failed to copy ...vhdx` après bascule de moteur

## Cause
1- Conflit entre **Hyper-V** (moteur Multipass par défaut) et **VirtualBox**
installé en parallèle : réseau Hyper-V instable, puis image en cache au
format `.vhdx` incompatible avec VirtualBox.
2- Une VM installée sur Hyper-V non fonctionnelle et bloquant toute nouvelle installation de 
   de VM et toute autre exécution avec multipass

## Contournement appliqué
1. Désintallation de **`Multipass`** et **`VirtualBox`**, puis réinstallation de **`Multipass`**.
2. Suppression de la VM **`vm-cr465-d`**  sur **Hyper-V**.
3. Vidage du cache Multipass (PowerShell admin) :
   - `Stop-Service Multipass`
   - supprimer `C:\ProgramData\Multipass\data\vault\instances\<vm>`
   - supprimer `C:\ProgramData\Multipass\cache\*`
   - `Start-Service Multipass`
4. Relancer : `./scripts/launch-vm.sh`.

## Leçon
L'approche VM as Code (cloud-init) a permis de tout reconstruire à
l'identique après ces incidents — la VM est jetable et reproductible.

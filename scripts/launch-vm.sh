#!/usr/bin/env bash
# ============================================================
# Lancement d'une VM avec Multipass + cloud-init
# Usage : bash scripts/launch-vm.sh [nom_de_la_vm]
#   - si un nom est passe en argument, il est utilise
#   - sinon, le script le demande (défaut : vm-cr465-d)
# ============================================================
set -euo pipefail

# --- Nom de la VM : argument, sinon demande, sinon defaut ---
VM_NAME="${1:-}"
if [ -z "$VM_NAME" ]; then
  read -r -p "Nom de la VM a creer [vm-cr465-d] : " VM_NAME
  VM_NAME="${VM_NAME:-vm-cr465-d}"
fi

# --- Parametres ---
CPUS=4
MEMORY="8G"
DISK="60G"
RELEASE="24.04"
CLOUD_INIT="cloud-init/user-data.yaml"

# --- Verifications prealables ---
command -v multipass >/dev/null 2>&1 || { echo "ERREUR : multipass introuvable."; exit 1; }
[ -f "$CLOUD_INIT" ] || { echo "ERREUR : $CLOUD_INIT introuvable (lancez depuis la racine)."; exit 1; }

# --- Idempotence ---
if multipass list | grep -qw "$VM_NAME"; then
  echo "La VM '$VM_NAME' existe deja. Etat :"
  multipass info "$VM_NAME"
  exit 0
fi

# --- Lancement ---
echo ">> Lancement de la VM '$VM_NAME' (Ubuntu $RELEASE)..."
multipass launch "$RELEASE" \
  --name "$VM_NAME" \
  --cpus "$CPUS" \
  --memory "$MEMORY" \
  --disk "$DISK" \
  --cloud-init "$CLOUD_INIT"

echo ">> VM lancee. Informations :"
multipass info "$VM_NAME"
echo ""
echo ">> Entrer dans la VM :    multipass shell $VM_NAME"
echo ">> Verifier cloud-init :  multipass exec $VM_NAME -- cloud-init status --wait"

# Les caracteres accentues n'ont pas ete appliques en pour conserver une certaine coherence
# lors de l'execution des scription sur certains systemes qui ne les prend pas en compte

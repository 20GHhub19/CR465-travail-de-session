#!/usr/bin/env bash
# ============================================================
# Installe gVisor (runsc) DANS une VM Multipass et le teste
# Usage : bash scripts/install-gvisor.sh [nom_de_la_vm]
# ============================================================
set -euo pipefail

VM_NAME="${1:-}"
while true; do
  if [ -z "$VM_NAME" ]; then
    echo "VM existantes :"; multipass list
    read -r -p "Nom de la VM cible (ou q ou quit pour quitter): " VM_NAME
  fi
  
  # Sortie volontaire si on ne veut plus continuer
  if [ "$VM_NAME" = "q" ] || [ "$VM_NAME" = "quit" ]; then
    echo "Sortie ..."
    exit 0
  fi

  # Si le nom de la VM est vide, on redemande
  if [ -z "$VM_NAME" ]; then
    echo "Aucun nom fourni. Réessayez."
    continue
  fi

  # Si le nom entré n'est pas valide --> on redemande ou 
  # on quitte ou on sort de la boucle si le nom entré est valide
  if multipass list | grep -qw "$VM_NAME"; then
    break
  else
    echo "VM '$VM_NAME' introuvable. Réessayez (ou 'q' ou 'quit'pour quitter)."
    VM_NAME=""
  fi
done

### --------------- Confirmation de l'installation de gvisor avant son lancement ---------
read -r -p "Installer gVisor dans '$VM_NAME' ? (oui / non) " go
if [ "$go" != "oui" ]; then
  echo "Installation annulée. Sortie"
  exit 0
fi
# Lancement de l'installation de gVisor
echo ">> Installation de gVisor dans '$VM_NAME'..."

# Les commandes ci-dessous s'executent DANS la VM, en root.
# Le heredoc '<<SCRIPT' (quote) : $(...) est evalue dans la VM, pas sur le poste.
# Le script est passe comme ARGUMENT de bash -c (entre apostrophes).
# $(dpkg ...) est évalué DANS la VM car protege par les apostrophes.
multipass exec "$VM_NAME" -- sudo bash -c '
set -eu
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg
curl -fsSL https://gvisor.dev/archive.key | gpg --dearmor -o /usr/share/keyrings/gvisor-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/gvisor-archive-keyring.gpg] https://storage.googleapis.com/gvisor/releases release main" > /etc/apt/sources.list.d/gvisor.list
apt-get update
apt-get install -y runsc
runsc install
systemctl restart docker
echo "gVisor installe dans la VM."
'

echo ">> Test : execution d'\''un conteneur sous gVisor..."
multipass exec "$VM_NAME" -- sudo docker run --runtime=runsc --rm ubuntu dmesg | head -1
echo ">> Si vous voyez '\''Starting gVisor...'\'' ci-dessus, c'\''est reussi."

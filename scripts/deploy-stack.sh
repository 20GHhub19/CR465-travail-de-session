#!/usr/bin/env bash
# ============================================================
# Deploie / met a jour la stack Docker Compose dans la VM
# Usage : bash scripts/deploy-stack.sh [vm-cr465-d]
# ============================================================
export MSYS_NO_PATHCONV=1
set -euo pipefail

VM_NAME="${1:-}"
COMPOSE="/opt/cr465-groupe-d/compose/docker-compose.yml"

while [ -z "$VM_NAME" ]; do
  read -r -p "Nom de la VM cible [vm-cr465-d] : " VM_NAME
  VM_NAME="${VM_NAME:-vm-cr465-d}"
done

echo "VM      : $VM_NAME"
echo "Compose : $COMPOSE"
read -r -p "Deployer la stack ? (oui/non) : " REP
[ "$REP" = "oui" ] || { echo "Annule."; exit 0; }

multipass exec "$VM_NAME" -- sudo docker compose -f "$COMPOSE" up -d

echo "=== Conteneurs ==="
multipass exec "$VM_NAME" -- sudo docker compose -f "$COMPOSE" ps
echo "=== Reseaux Docker ==="
multipass exec "$VM_NAME" -- sudo docker network ls

#!/usr/bin/env bash
# ============================================================
# Teste le routage Traefik : HTTPS + redirection HTTP -> HTTPS
# Usage : bash scripts/test-routing.sh [vm-cr465-d]
# ============================================================
export MSYS_NO_PATHCONV=1
set -euo pipefail

VM_NAME="${1:-}"
HOST="whoami.cr465.lan"

while [ -z "$VM_NAME" ]; do
  read -r -p "Nom de la VM cible [vm-cr465-d] : " VM_NAME
  VM_NAME="${VM_NAME:-vm-cr465-d}"
done

# IP de la VM (ligne "IPv4:" de multipass info)
IP="$(multipass info "$VM_NAME" | awk '/IPv4/ {print $2; exit}')"
echo "IP de la VM : $IP"

echo
echo "=== Test 1 : HTTPS (doit afficher la page whoami) ==="
curl -k -s --resolve "$HOST:443:$IP" "https://$HOST" | head -20

echo
echo "=== Test 2 : redirection HTTP -> HTTPS (doit renvoyer 301/308 + Location https) ==="
curl -k -s -o /dev/null -D - --resolve "$HOST:80:$IP" "http://$HOST" | head -8

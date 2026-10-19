#!/usr/bin/env bash
# ============================================================
# Teste le routage Traefik : HTTPS + redirection HTTP -> HTTPS
# Cible : Moodle (le service de test whoami a ete retire avant la remise)
# Usage : bash scripts/test-routing.sh [vm-cr465-d]
# ============================================================
export MSYS_NO_PATHCONV=1
set -euo pipefail

VM_NAME="${1:-}"
HOST="lms.cr465.test"

while [ -z "$VM_NAME" ]; do
  read -r -p "Nom de la VM cible [vm-cr465-d] : " VM_NAME
  VM_NAME="${VM_NAME:-vm-cr465-d}"
done

# IP de la VM (ligne "IPv4:" de multipass info)
IP="$(multipass info "$VM_NAME" | awk '/IPv4/ {print $2; exit}')"
echo "IP de la VM : $IP"

echo
echo "=== Test 1 : HTTPS (Moodle doit repondre 200 ou 303) ==="
curl -k -s -o /dev/null -w "HTTPS -> %{http_code}\n" --resolve "$HOST:443:$IP" "https://$HOST"

echo
echo "=== Test 2 : redirection HTTP -> HTTPS (doit renvoyer 301/308 + Location https) ==="
curl -k -s -o /dev/null -D - --resolve "$HOST:80:$IP" "http://$HOST" | head -8

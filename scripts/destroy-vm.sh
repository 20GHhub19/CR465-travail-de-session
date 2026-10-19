#!/usr/bin/env bash
# ============================================================
# Suppression d'une VM (Multipass)
# Usage : bash scripts/destroy-vm.sh [nom_de_la_vm]
# ============================================================
set -euo pipefail

# --- Nom de la VM : argument, sinon demande ---
VM_NAME="${1:-}"
if [ -z "$VM_NAME" ]; then
  echo "VM existantes :"
  multipass list
  read -r -p "Nom de la VM a supprimer : " VM_NAME
fi
[ -n "$VM_NAME" ] || { echo "Aucun nom fourni. Annule."; exit 1; }

# --- Verification d'existence ---
if ! multipass list | grep -qw "$VM_NAME"; then
  echo "La VM '$VM_NAME' n'existe pas. Rien a supprimer."
  exit 0
fi

# --- Confirmation (securite) ---
read -r -p "Supprimer DEFINITIVEMENT la VM '$VM_NAME' ? (oui/non) " reponse
if [ "$reponse" != "oui" ]; then
  echo "Annule."
  exit 0
fi

# --- Suppression + purge ---
echo ">> Suppression de '$VM_NAME'..."
multipass delete "$VM_NAME"
multipass purge
echo ">> VM '$VM_NAME' supprimee definitivement."
multipass list

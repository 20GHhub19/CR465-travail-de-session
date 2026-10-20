#!/usr/bin/env bash
# ============================================================
# Monte le dossier compose/ du depot dans la VM (dev iteratif)
# Active au besoin les montages Multipass (desactives par defaut sur Windows)
# Usage : bash scripts/mount-compose.sh [vm-cr465-d]
# A lancer depuis la RACINE du depot.
# ============================================================
export MSYS_NO_PATHCONV=1          # empeche Git Bash de mangler les chemins /opt
set -euo pipefail

VM_NAME="${1:-}"
TARGET="/opt/cr465-groupe-d/compose"

while [ -z "$VM_NAME" ]; do
  read -r -p "Nom de la VM cible [vm-cr465-d] : " VM_NAME
  VM_NAME="${VM_NAME:-vm-cr465-d}"
done

# On doit etre a la racine du repo (presence du compose)
if [ ! -f compose/docker-compose.yml ]; then
  echo "Erreur : compose/docker-compose.yml introuvable."
  echo "Lancez ce script depuis la racine du depot."
  exit 1
fi

# --- Montages privilegies : reglage specifique a Windows (Hyper-V), ignore ailleurs ---
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    CUR="$(multipass get local.privileged-mounts 2>/dev/null || echo '')"
    if [ "$CUR" != "true" ] && [ "$CUR" != "Yes" ]; then
      echo "Montages desactives -> activation (local.privileged-mounts=true)…"
      if ! multipass set local.privileged-mounts=true 2>/dev/null; then
        echo
        echo "!! Activation impossible depuis ce shell (droits insuffisants)."
        echo "   Ouvrez PowerShell en ADMINISTRATEUR, lancez :"
        echo "       multipass set local.privileged-mounts=true"
        echo "   puis relancez ce script."
        exit 1
      fi
      echo "Montages actives."
    fi
    SRC="$(pwd -W)/compose"        # Git Bash : chemin Windows du dossier source
    ;;
  *)
    SRC="$(pwd)/compose"           # macOS / Linux
    ;;
esac
echo "Source (hote) : $SRC"
echo "Cible   (VM)  : $VM_NAME:$TARGET"
read -r -p "Monter ce dossier ? (oui/non) : " REP
[ "$REP" = "oui" ] || { echo "Annule."; exit 0; }

# Idempotence : si deja monte, on demonte d'abord
if multipass info "$VM_NAME" | grep -q "$TARGET"; then
  echo "Deja monte -> demontage prealable."
  multipass umount "$VM_NAME:$TARGET" || true
fi

multipass mount "$SRC" "$VM_NAME:$TARGET"
echo "--- Contenu monte dans la VM ---"
multipass exec "$VM_NAME" -- ls -la "$TARGET"

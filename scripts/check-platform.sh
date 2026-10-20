#!/usr/bin/env bash
# ============================================================
# Controle du poste avant de deploiement
# Verifie l'OS, l'architecture, les outils requis et, si Docker
# est disponible, la disponibilite des images pour cette architecture.
# Usage : bash scripts/check-platform.sh
# Aucune modification du systeme : uniquement des lectures.
# ============================================================
set -uo pipefail

ok=0; ko=0
say()  { printf '%-28s %s\n' "$1" "$2"; }
good() { say "$1" "OK  ($2)"; ok=$((ok+1)); }
bad()  { say "$1" "MANQUANT — $2"; ko=$((ko+1)); }

echo "============================================================"
echo " Controle du poste — CR465"
echo "============================================================"
echo

# --- Systeme et architecture ---
OS="$(uname -s)"
ARCH="$(uname -m)"
case "$OS" in
  Darwin) OSNAME="macOS" ;;
  Linux)  OSNAME="Linux" ;;
  MINGW*|MSYS*|CYGWIN*) OSNAME="Windows (Git Bash)" ;;
  *) OSNAME="$OS" ;;
esac
say "Systeme" "$OSNAME"
say "Architecture" "$ARCH"
echo

# --- Outils ---
command -v git      >/dev/null && good "git"      "$(git --version | awk '{print $3}')" || bad "git" "installez Git"
command -v bash     >/dev/null && good "bash"     "$(bash --version | head -1 | awk '{print $4}')" || bad "bash" "installez bash"
command -v multipass >/dev/null && good "multipass" "$(multipass version 2>/dev/null | head -1 | awk '{print $NF}')" || bad "multipass" "https://multipass.run"

# Docker facultatif : requis seulement pour le scan d'images
if command -v docker >/dev/null 2>&1; then
  if docker info >/dev/null 2>&1; then
    good "docker" "$(docker version --format '{{.Server.Version}}' 2>/dev/null)"
  else
    say "docker" "present mais daemon arrete (scan Trivy indisponible)"
  fi
else
  say "docker" "absent — facultatif (scan d'images uniquement)"
fi
echo

# --- Virtualisation (ce dont Multipass a besoin) ---
case "$OS" in
  Darwin)
    sysctl -n kern.hv_support 2>/dev/null | grep -q "^1$" \
      && good "virtualisation" "Hypervisor.framework" \
      || bad "virtualisation" "non disponible"
    ;;
  Linux)
    if [ -r /dev/kvm ]; then good "virtualisation" "/dev/kvm"; else
      grep -qE 'vmx|svm' /proc/cpuinfo 2>/dev/null \
        && say "virtualisation" "CPU compatible mais /dev/kvm absent (groupe kvm ?)" \
        || bad "virtualisation" "VT-x/AMD-V absent du CPU"
    fi
    ;;
  MINGW*|MSYS*|CYGWIN*)
    powershell -NoProfile -Command \
      "(Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V).State" 2>/dev/null \
      | grep -qi "Enabled" \
      && good "Hyper-V" "active" \
      || say "Hyper-V" "verifiez : Windows Features > Hyper-V (redemarrage requis)"
    ;;
esac
echo

# --- Images : support de l'architecture courante ---
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  case "$ARCH" in
    arm64|aarch64) WANT="arm64" ;;
    x86_64|amd64)  WANT="amd64" ;;
    *)             WANT="$ARCH" ;;
  esac
  echo "Images epinglees — support linux/$WANT :"
  IMAGES="
tecnativa/docker-socket-proxy:v0.5.0
traefik:v3.7.15
postgres:17.11-alpine
quay.io/keycloak/keycloak:26.8.1
portainer/portainer-ce:2.45.2
erseco/alpine-moodle:v5.3.0
n8nio/n8n:1.123.85
drupal:10.6.19-php8.4-apache
"
  missing=0
  for img in $IMAGES; do
    if docker manifest inspect "$img" 2>/dev/null | grep -q "\"architecture\": \"$WANT\""; then
      printf "  %-45s OK\n" "$img"
    else
      printf "  %-45s INDISPONIBLE pour $WANT\n" "$img"; missing=$((missing+1))
    fi
  done
  [ "$missing" -eq 0 ] && echo "  -> toutes les images existent pour cette architecture."
  echo
fi

# --- Resultat ---
echo "============================================================"
echo " Bilan : $ok controle(s) OK, $ko manquant(s)"
if [ "$ko" -eq 0 ]; then
  echo " Le poste est pret. Suite : ./scripts/launch-vm.sh"
else
  echo " Installez les elements manquants avant de continuer."
fi
echo "============================================================"

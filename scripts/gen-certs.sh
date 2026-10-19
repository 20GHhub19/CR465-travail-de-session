#!/usr/bin/env bash
# ============================================================
# Genere une AC locale et un certificat wildcard pour *.cr465.test
#
# Pourquoi : Traefik sert du HTTPS. Moodle (plugin OAuth2) refuse tout
# endpoint qui n'est pas en https et valide le certificat. Il faut donc
# un certificat signe par une AC que Moodle reconnait.
#
# Sortie : compose/traefik/certs/
#   cr465-ca.crt      AC publique  -> montee dans Moodle comme autorite de confiance
#   cr465-ca.key      cle de l'AC  (jamais distribuee)
#   cr465.crt/.key    certificat serveur wildcard pour Traefik
#
# Les fichiers sont exclus du depot par .gitignore (*.crt, *.key).
# ============================================================
set -euo pipefail

DOMAIN="${BASE_DOMAIN:-cr465.test}"
OUT="compose/traefik/certs"
DAYS=825

mkdir -p "$OUT"

if [ -f "$OUT/cr465.crt" ] && [ -f "$OUT/cr465-ca.crt" ]; then
  echo "Certificats deja presents dans $OUT (rien a faire)."
  echo "Pour les regenerer : supprimer le dossier $OUT puis relancer."
  exit 0
fi

echo ">> AC locale"
openssl req -x509 -newkey rsa:4096 -sha256 -days "$DAYS" -nodes \
  -keyout "$OUT/cr465-ca.key" -out "$OUT/cr465-ca.crt" \
  -subj "/C=CA/ST=QC/O=CR465 Groupe D/CN=CR465 Local CA" >/dev/null 2>&1

echo ">> Cle et CSR du serveur"
openssl req -newkey rsa:2048 -sha256 -nodes \
  -keyout "$OUT/cr465.key" -out "$OUT/cr465.csr" \
  -subj "/C=CA/ST=QC/O=CR465 Groupe D/CN=*.${DOMAIN}" >/dev/null 2>&1

echo ">> Signature du certificat serveur (SAN wildcard)"
cat > "$OUT/san.cnf" <<EOF
subjectAltName = DNS:*.${DOMAIN}, DNS:${DOMAIN}
extendedKeyUsage = serverAuth
EOF
openssl x509 -req -in "$OUT/cr465.csr" -CA "$OUT/cr465-ca.crt" -CAkey "$OUT/cr465-ca.key" \
  -CAcreateserial -out "$OUT/cr465.crt" -days "$DAYS" -sha256 \
  -extfile "$OUT/san.cnf" >/dev/null 2>&1

rm -f "$OUT/cr465.csr" "$OUT/san.cnf" "$OUT/cr465-ca.srl"
chmod 600 "$OUT"/*.key

echo "Certificats generes dans $OUT :"
ls -1 "$OUT"
echo
echo "Verification :"
openssl x509 -in "$OUT/cr465.crt" -noout -subject -issuer -dates

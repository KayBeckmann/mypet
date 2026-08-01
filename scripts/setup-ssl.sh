#!/usr/bin/env bash
# Einmaliges Setup für TLS via Let's Encrypt/Certbot (Rest von Phase 20).
#
# Voraussetzung: Eine echte Domain mit A-Records für alle Subdomains, die
# bereits auf diesen Server zeigen (DNS-Propagation kann etwas dauern) —
# ohne Domain kann Let's Encrypt keine Zertifikate ausstellen, siehe TODO.md.
#
# Verwendung:
#   1. In .env eintragen: DOMAIN_OWNER, DOMAIN_VET, DOMAIN_PROVIDER,
#      DOMAIN_ADMIN, DOMAIN_API, CERTBOT_EMAIL (siehe .env.example)
#   2. ./scripts/setup-ssl.sh
#
# Danach läuft die automatische Erneuerung über den certbot-Container in
# docker-compose.ssl.yml von selbst weiter — dieses Skript muss nur einmal
# laufen (bzw. erneut, falls eine Domain hinzukommt/sich ändert).

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [ ! -f .env ]; then
  echo "FEHLER: .env nicht gefunden! cp .env.example .env && nano .env"
  exit 1
fi
set -a
source .env
set +a

for var in DOMAIN_OWNER DOMAIN_VET DOMAIN_PROVIDER DOMAIN_ADMIN DOMAIN_API CERTBOT_EMAIL; do
  if [ -z "${!var:-}" ]; then
    echo "FEHLER: $var ist in .env nicht gesetzt."
    echo "        Ohne Domain kein Let's Encrypt-Zertifikat möglich."
    exit 1
  fi
done

COMPOSE="docker compose -f docker-compose.yml -f docker-compose.ssl.yml"
TEMPLATE="deploy/nginx/reverse-proxy.conf.template"
CONF="deploy/nginx/reverse-proxy.conf"

echo "==> [1/4] Config ohne HTTPS-Server-Blöcke rendern (Zertifikate existieren noch nicht)..."
sed '/#SSL_BLOCKS_START/,/#SSL_BLOCKS_END/d' "$TEMPLATE" | envsubst \
  '${DOMAIN_OWNER} ${DOMAIN_VET} ${DOMAIN_PROVIDER} ${DOMAIN_ADMIN} ${DOMAIN_API}' \
  > "$CONF"

echo "==> [2/4] Reverse-Proxy + restlichen Stack starten (HTTP-only, für ACME-Challenge)..."
$COMPOSE up -d

echo "==> [3/4] Zertifikate holen (certbot certonly --webroot) für alle Domains..."
for domain in "$DOMAIN_OWNER" "$DOMAIN_VET" "$DOMAIN_PROVIDER" "$DOMAIN_ADMIN" "$DOMAIN_API"; do
  echo "    -> $domain"
  $COMPOSE run --rm certbot certonly \
    --webroot -w /var/www/certbot \
    --non-interactive --agree-tos \
    -m "$CERTBOT_EMAIL" \
    -d "$domain"
done

echo "==> [4/4] Vollständige Config mit HTTPS-Server-Blöcken rendern und Proxy neu laden..."
envsubst \
  '${DOMAIN_OWNER} ${DOMAIN_VET} ${DOMAIN_PROVIDER} ${DOMAIN_ADMIN} ${DOMAIN_API}' \
  < "$TEMPLATE" > "$CONF"
$COMPOSE exec reverse-proxy nginx -s reload

echo ""
echo "Fertig. Alle Apps sollten jetzt per HTTPS erreichbar sein:"
echo "  https://$DOMAIN_OWNER  https://$DOMAIN_VET  https://$DOMAIN_PROVIDER  https://$DOMAIN_ADMIN  https://$DOMAIN_API"
echo ""
echo "Nicht vergessen: API_BASE_URL / ANDROID_API_URL in .env auf https://$DOMAIN_API umstellen"
echo "und die betroffenen Apps neu bauen (GitHub Actions Repository-Variable API_BASE_URL anpassen)."

#!/usr/bin/env bash
# Produktionsumgebung starten
#
# HINWEIS: Auf Servern mit < 2 GB RAM bitte stattdessen verwenden:
#   make deploy   oder   bash scripts/deploy.sh
#
# Dieses Skript startet den Stack ohne Rebuild (setzt bereits gebaute Images voraus).

set -euo pipefail

if [ ! -f .env ]; then
  echo "FEHLER: .env nicht gefunden! cp .env.example .env && nano .env"
  exit 1
fi

docker compose up -d

echo ""
echo "Stack-Status:"
docker compose ps

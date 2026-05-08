#!/usr/bin/env bash
# Deployment-Skript für Server mit wenig RAM (< 2 GB RAM)
#
# Problem: flutter build web --release benötigt ~500 MB RAM pro App.
#          4 Flutter-Apps parallel = ~2 GB Bedarf → OOM-Kill auf 1-GB-Servern.
# Lösung:  Jede App einzeln bauen — nie alle gleichzeitig.
#
# Verwendung:
#   cd ~/mypet && git pull && bash scripts/deploy.sh
#   oder einfach: make deploy

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# ── Voraussetzungen prüfen ─────────────────────────────────────────────────
if [ ! -f .env ]; then
  echo "FEHLER: .env nicht gefunden!"
  echo "       cp .env.example .env && nano .env"
  exit 1
fi

echo "==> [1/6] Backend bauen..."
docker compose build backend

echo "==> [2/6] web-owner bauen..."
docker compose build web-owner

echo "==> [3/6] web-vet bauen..."
docker compose build web-vet

echo "==> [4/6] web-provider bauen..."
docker compose build web-provider

echo "==> [5/6] web-admin bauen..."
docker compose build web-admin

echo "==> [6/6] Stack starten..."
docker compose up -d

echo ""
echo "Stack-Status:"
docker compose ps

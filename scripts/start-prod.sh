#!/bin/bash
# Produktionsumgebung starten

set -e

echo "🚀 Starte Produktionsumgebung..."

# .env prüfen
if [ ! -f .env ]; then
    echo "❌ .env nicht gefunden!"
    echo "   Bitte .env.example nach .env kopieren und anpassen."
    exit 1
fi

# Container bauen und starten
docker-compose up -d --build

echo ""
echo "✅ Produktionsumgebung gestartet!"
echo ""
echo "📦 Services:"
echo "   - Backend:      http://localhost:${BACKEND_PORT:-8080}"
echo "   - Besitzer-App: http://localhost:${OWNER_PORT:-3001}"
echo "   - Tierarzt-App: http://localhost:${VET_PORT:-3002}"
echo "   - Dienstleister-App: http://localhost:${PROVIDER_PORT:-3003}"
echo ""

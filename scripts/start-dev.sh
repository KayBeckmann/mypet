#!/bin/bash
# Entwicklungsumgebung starten (nur Datenbank)

set -e

echo "🚀 Starte Entwicklungsumgebung..."

# .env prüfen
if [ ! -f .env ]; then
    echo "⚠️  .env nicht gefunden, kopiere .env.example..."
    cp .env.example .env
fi

# Container starten
docker-compose -f docker-compose.dev.yml up -d

echo ""
echo "✅ Entwicklungsumgebung gestartet!"
echo ""
echo "📦 Services:"
echo "   - PostgreSQL: localhost:5432"
echo "   - pgAdmin:    http://localhost:5050"
echo "     Login: admin@mypet.local / admin"
echo ""
echo "🔧 Backend starten:"
echo "   cd backend && dart run bin/server.dart"
echo ""
echo "🌐 Frontend starten:"
echo "   cd web_owner && flutter run -d chrome"
echo ""

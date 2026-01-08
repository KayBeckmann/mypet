#!/bin/bash
# Datenbank zurücksetzen (Entwicklung)

set -e

echo "⚠️  WARNUNG: Dies löscht alle Daten in der Entwicklungs-Datenbank!"
read -p "Fortfahren? (y/N) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🗑️  Lösche Datenbank-Volume..."

    docker-compose -f docker-compose.dev.yml down -v

    echo "🚀 Starte Datenbank neu..."
    docker-compose -f docker-compose.dev.yml up -d db

    echo ""
    echo "✅ Datenbank zurückgesetzt!"
    echo "   Führe Migrationen erneut aus."
else
    echo "❌ Abgebrochen."
fi

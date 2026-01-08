#!/bin/bash
# Entwicklungsumgebung stoppen

set -e

echo "🛑 Stoppe Entwicklungsumgebung..."

docker-compose -f docker-compose.dev.yml down

echo "✅ Entwicklungsumgebung gestoppt!"

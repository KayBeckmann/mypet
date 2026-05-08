.PHONY: deploy pull up down logs ps build

# ── Produktions-Deploy (Server mit wenig RAM) ──────────────────────────────
# Images werden via GitHub Actions gebaut und im GHCR bereitgestellt.
# Kein lokales Build nötig — einfach pullen und starten.
#
#   make deploy
deploy: pull
	docker compose pull
	docker compose up -d
	@echo ""
	@docker compose ps

pull:
	git pull --ff-only

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f --tail=50

ps:
	docker compose ps

# ── Lokales Build (nur für Entwicklung, braucht > 2 GB RAM) ───────────────
# Baut alle Services nacheinander um OOM-Kill zu vermeiden.
build:
	@echo "==> [1/5] backend"
	docker compose build backend
	@echo "==> [2/5] web-owner"
	docker compose build web-owner
	@echo "==> [3/5] web-vet"
	docker compose build web-vet
	@echo "==> [4/5] web-provider"
	docker compose build web-provider
	@echo "==> [5/5] web-admin"
	docker compose build web-admin

.PHONY: deploy pull build up down logs ps

# Haupt-Deploy-Target: sequenzieller Build + Start
# Auf RAM-armen Servern (< 2 GB) verhindert dies OOM-Kills durch parallele Flutter-Builds.
# Verwendung: make deploy
deploy: pull build up
	@echo ""
	@docker compose ps

pull:
	git pull --ff-only

# Jede Flutter-App einzeln bauen — nie alle gleichzeitig
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

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f --tail=50

ps:
	docker compose ps

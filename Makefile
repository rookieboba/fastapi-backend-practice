DOCKER_COMPOSE := $(shell command -v docker-compose > /dev/null 2>&1 && echo docker-compose || echo docker compose)
ENV_FILE ?= .env
include $(ENV_FILE)
export

# ===================
# 🐳 Docker Compose
# ===================

run-dev:
	$(DOCKER_COMPOSE) -f docker-compose.dev.yml up --build

run-prod:
	$(DOCKER_COMPOSE) -f docker-compose.prod.yml up -d --build

down-dev:
	-$(DOCKER_COMPOSE) -f docker-compose.dev.yml down

down-prod:
	-$(DOCKER_COMPOSE) -f docker-compose.prod.yml down

restart-dev: down-dev run-dev
restart-prod: down-prod run-prod

# ===================
# ✅ Testing
# ===================

test:
	$(DOCKER_COMPOSE) -f docker-compose.dev.yml run --rm web \
		env PYTHONPATH=/app pytest --cov=app --cov-report=term tests/

test-cov:
	$(DOCKER_COMPOSE) -f docker-compose.dev.yml run --rm web \
		env PYTHONPATH=/app pytest --cov=app --cov-report=html tests/

clean-cov:
	rm -rf .coverage htmlcov .pytest_cache
	@echo "[INFO] 커버리지 리포트 및 캐시 삭제 완료"

# ===================
# 🚀 Kubernetes
# ===================

deploy-blue:
	kubectl apply -f manifests/
	kubectl apply -f k8s/blue-deployment.yaml

deploy-green:
	kubectl apply -f manifests/
	kubectl apply -f k8s/green-deployment.yaml

logs:
	kubectl logs -l app=fastapi -c fastapi --tail=100 -f

# ===================
# 🗃 SQLite 관련
# ===================

reset-db:
	rm -f ./scripts/sqlite3/*.db
	@echo "[INFO] SQLite DB 초기화 완료"

init-db:
	$(DOCKER_COMPOSE) -f docker-compose.dev.yml exec web \
		python scripts/init_db.py

# ===================
# 🔁 CI 용도
# ===================

lint:
	flake8 app scripts tests

ci-check:
	make lint && make test

.PHONY: run-dev run-prod down-dev down-prod restart-dev restart-prod test test-cov clean-cov deploy-blue deploy-green logs reset-db init-db lint ci-chec
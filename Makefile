# 🛠 Makefile - 최신 정리 버전
DOCKER_COMPOSE := $(shell command -v docker-compose > /dev/null 2>&1 && echo docker-compose || echo docker compose)
ENV_FILE ?= .env
include $(ENV_FILE)
export

# ===================
# 🐳 Docker Compose
# ===================
run-dev:
	$(DOCKER_COMPOSE) -f docker-compose.dev.yml up --build

down-dev:
	-$(DOCKER_COMPOSE) -f docker-compose.dev.yml down

restart-dev: down-dev run-dev

# ===================
# ✅ Testing & Linting
# ===================
test:
	$(DOCKER_COMPOSE) -f docker-compose.dev.yml run --rm web \
		env PYTHONPATH=/app pytest --cov=app --cov-report=term tests/

test-cov:
	$(DOCKER_COMPOSE) -f docker-compose.dev.yml run --rm web \
		env PYTHONPATH=/app pytest --cov=app --cov-report=html tests/

lint:
	flake8 app scripts tests

ci-check:
	make lint && make test

clean-cov:
	rm -rf .coverage htmlcov .pytest_cache
	@echo "[INFO] 커버리지 리포트 및 캐시 삭제 완료"

# ===================
# ☸️ Kubernetes
# ===================
k8s-apply:
	kubectl apply -k k8s/

logs:
	kubectl logs -l app=fastapi -n default --tail=100 -f

# ===================
# 🗃 SQLite 관련
# ===================
reset-db:
	rm -f ./data/db.sqlite3
	@echo "[INFO] SQLite DB 초기화 완료"

init-db:
	$(DOCKER_COMPOSE) -f docker-compose.dev.yml run --rm web \
		python scripts/init_db.py

# ===================
# ℹ️ 도움말
# ===================
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {{FS = ":.*?## "}}; {{printf "\\033[36m%-20s\\033[0m %s\\n", $$1, $$2}}'

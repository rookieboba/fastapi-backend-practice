# Makefile for DOCKER COMPOSE?
DOCKER_COMPOSE := $(shell command -v docker-compose > /dev/null 2>&1 && echo docker-compose || echo docker compose)

# 개발 환경 실행 (hot reload 포함)
run-dev:
	$(DOCKER_COMPOSE) -f docker-compose.dev.yml up --build

# 운영 환경 실행 (백그라운드)
run-prod:
	$(DOCKER_COMPOSE) -f docker-compose.prod.yml up -d --build

# 모든 컨테이너 종료
down:
	$(DOCKER_COMPOSE) down

# pytest 실행 (커버리지 포함)
test:
	$(DOCKER_COMPOSE) exec fastapi-dev pytest --cov=app tests/

# newman 테스트 실행 (Postman 기반 API 시나리오)
newman:
	docker run --rm -v $(PWD):/etc/newman postman/newman run \
	  /etc/newman/tests/api-collection.postman.json \
	  -e /etc/newman/tests/dev-environment.postman.json


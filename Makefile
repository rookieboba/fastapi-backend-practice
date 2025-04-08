DOCKER_COMPOSE := $(shell command -v docker-compose > /dev/null 2>&1 && echo docker-compose || echo docker compose)

# 개발 환경 실행
run-dev:
	$(DOCKER_COMPOSE) -f docker-compose.dev.yml up --build

# 운영 환경 실행
run-prod:
	$(DOCKER_COMPOSE) -f docker-compose.prod.yml up -d --build

# 개발 환경 종료
down-dev:
	-$(DOCKER_COMPOSE) -f docker-compose.dev.yml down

# 운영 환경 종료
down-prod:
	-$(DOCKER_COMPOSE) -f docker-compose.prod.yml down

# 개발 환경 재시작
restart-dev: down-dev run-dev

# 운영 환경 재시작
restart-prod: down-prod run-prod

# pytest 실행 (커버리지 포함, run 방식으로 실행 후 자동 제거)
test:
	$(DOCKER_COMPOSE) -f docker-compose.dev.yml run --rm web \
		env PYTHONPATH=/app pytest --cov=app --cov-report=$$(COV_REPORT) tests/

# Postman 기반 newman 테스트 실행 (web과 동일 네트워크)
newman:
	$(DOCKER_COMPOSE) -f docker-compose.dev.yml run --rm newman

# SQLite DB 파일 삭제 (완전 초기화)
reset-db:
	rm -f ./data/db.sqlite3
	@echo "[INFO] SQLite DB 초기화 완료 (db.sqlite3 삭제됨)"

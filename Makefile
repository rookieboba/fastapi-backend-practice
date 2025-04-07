# Makefile - FastAPI 프로젝트 실행 명령 모음

# 개발 환경 실행 (hot reload 포함)
run-dev:
	docker-compose -f docker-compose.dev.yml up --build

# 운영 환경 실행 (백그라운드)
run-prod:
	docker-compose -f docker-compose.prod.yml up -d --build

# 모든 컨테이너 종료
down:
	docker-compose down

# pytest 실행 (커버리지 포함)
test:
	docker-compose exec backend pytest --cov=app tests/

# newman 테스트 실행 (Postman 기반 API 시나리오)
newman:
	docker run --rm -v $(PWD):/etc/newman postman/newman run \
	  /etc/newman/tests/api-collection.postman.json \
	  -e /etc/newman/tests/dev-environment.postman.json


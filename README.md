# fastapi-backend-practice

FastAPI + Docker 기반 백엔드 프로젝트 
RESTful API 개발, DB 연동, 단위 테스트 및 자동화 테스트(Newman)까지 포함된 실전 지향 구조입니다.

| 범주         | 기술                                           |
|--------------|------------------------------------------------|
| Backend      | FastAPI, Python 3.11                           |
| Database     | SQLite3                                        |
| DevOps       | Docker, Docker Compose, Makefile               |
| Testing      | Pytest, Coverage, Postman, Newman              |
| API 문서화   | Swagger UI, ReDoc                              |

# 개발 환경
```bash
git clone https://github.com/rookieboba/fastapi-backend-practice.git
```

# 시간 동기화 데몬 활성화 및 즉시 시간 동기화
```bash
sudo systemctl enable --now chronyd
sudo chronyc makestep
```

# 빌드
```bash
cd fastapi-backend-practice
make run-dev
```

# MakeFile 명령어
```bash
make run-dev	# 개발 환경 실행 (hot reload)
make run-prod	# 운영 환경 실행 (백그라운드)
make down-dev	# 개발 환경 종료
make down-prod	#운영 환경 종료
make restart-dev	# 개발 환경 재시작
make restart-prod	# 운영 환경 재시작
make test #	단위 테스트 실행 (Pytest)
make newman	# API 시나리오 테스트 (Postman 기반
```

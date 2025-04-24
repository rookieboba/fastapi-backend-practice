# fastapi-bluegreen-deploy

FastAPI 기반의 백엔드 서버를 Docker, Kubernetes 환경에서 배포
RESTful API 개발, DB 연동, 단위 테스트 및 자동화 테스트(Newman)까지 포함된 실전 지향 구조입니다.

| 범주         | 기술                                           |
|--------------|------------------------------------------------|
| Backend      | FastAPI, Python 3.11                           |
| Database     | SQLite3 (InitContainer 기반 초기화 포함)       |
| DevOps       | Docker, Docker Compose, Makefile, Kubernetes   |
| 배포 전략    | Blue/Green Deployment, InitContainer 활용       |
| Testing      | Pytest, Coverage, Postman, Newman              |
| API 문서화   | Swagger UI, ReDoc                              |

---

## 🚀 개발 환경 실행
```bash
git clone https://github.com/rookieboba/fastapi-backend-practice.git
cd fastapi-backend-practice
make run-dev
```

#  Docker 이미지 빌드 & 푸시
```bash
# 버전 1
docker build -f Dockerfile.dev -t sungbin/fastapi-app:v1 .
docker push sungbin/fastapi-app:v1

# 버전 2
docker build -f Dockerfile.dev -t sungbin/fastapi-app:v2 .
docker push sungbin/fastapi-app:v2
```

# Kubernetes 배포 (Blue/Green + InitContainer)
``` bash
kubectl apply -f k8s/bluegreen-init/pvc.yaml
kubectl apply -f k8s/bluegreen-init/configmap-init-sql.yaml
kubectl apply -f k8s/bluegreen-init/blue-deployment.yaml
kubectl apply -f k8s/bluegreen-init/service.yaml

# 새로운 버전(green) 배포 + DB 초기화
kubectl apply -f k8s/bluegreen-init/green-deployment.yaml

# 서비스 전환: blue → green
kubectl patch service fastapi-service -p '{"spec":{"selector":{"app":"fastapi","version":"green"}}}'
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

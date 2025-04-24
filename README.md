# FastAPI Blue/Green Deployment Practice

FastAPI 기반의 REST API 애플리케이션으로, Blue/Green 배포 전략과 CI/CD 자동화 파이프라인 구축을 중심으로 실습합니다.

---

## 📌 주요 기술 스택

| 범주       | 기술                                      |
|------------|-------------------------------------------|
| Web API    | FastAPI, Pydantic                         |
| DB         | SQLite3 (InitContainer 초기화 방식 사용)  |
| CI/CD      | GitHub Actions, Jenkins                   |
| 배포       | Docker, Kubernetes                        |
| 테스트     | Pytest, Postman, Newman                   |

---

## 🔧 개발 환경 실행

```bash
git clone https://github.com/rookieboba/fastapi-bluegreen-deploy.git
cd fastapi-bluegreen-deploy
make run-dev
```

---

## 🚀 배포 전략: Blue/Green Deployment

1. 기존 버전(`v1`)을 Blue로 배포
2. 새 버전(`v2`)을 Green으로 병렬 배포
3. 트래픽 스위칭으로 무중단 업데이트 수행

```bash
# 사전 작업 (SQLite 데이터베이스를 위한 디렉토리를 모든 Worker 노드에 직접 생성)
sudo mkdir -p /mnt/data/sqlite
sudo chmod 777 /mnt/data/sqlite  # 테스트 목적의 퍼미션, 운영 환경에서는 제한 필요

# Master node 초기 배포
kubectl apply -f k8s/blue-deployment.yaml
kubectl apply -f k8s/service.yaml

# 신규 버전 배포
kubectl apply -f k8s/green-deployment.yaml

# 서비스 트래픽 전환
kubectl patch service fastapi-service -p '{"spec":{"selector":{"app":"fastapi", "version":"green"}}}'
```

---

## 📂 Kubernetes 구성

| 파일명                           | 설명                                 |
|----------------------------------|--------------------------------------|
| `blue-deployment.yaml`          | 기존 버전 배포 설정 (v1)             |
| `green-deployment.yaml`         | 신규 버전 배포 설정 (v2)             |
| `service.yaml`                  | 공통 서비스 정의                     |
| `configmap-init-sql.yaml`       | 초기 SQL 데이터 삽입                 |
| `pvc.yaml`                      | SQLite3용 영속 볼륨 설정             |

---

## ✅ GitHub Actions

`.github/workflows/fastapi-dev-pipeline.yml`  
- 테스트 → 빌드 → 배포 파이프라인 구축  
- main 브랜치 푸시 시 자동 실행

---

## 🧪 테스트

```bash
make test    # 단위 테스트 (pytest)
make newman  # API 시나리오 테스트 (Postman + Newman)
```

---

## 📁 기타 유틸리티

| 디렉토리         | 설명                            |
|------------------|---------------------------------|
| `scripts/`       | DB 초기화 스크립트              |
| `sqlite3/`        | SQL 스크립트 + entrypoint       |
| `Jenkins/`       | Jenkins 배포 자동화 스크립트    |

---

## 💡 핵심 학습 포인트

- Kubernetes 환경에서의 무중단 배포 실습
- InitContainer를 통한 DB 초기화 방식
- GitHub Actions 및 Jenkins를 활용한 자동화

---

## 🔗 참고

- DockerHub: `docker.io/sungbin/fastapi-app:v1`, `v2`
- GitHub Actions CI: `.github/workflows/`

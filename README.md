# FastAPI Blue/Green Deployment Practice

FastAPI 기반 REST API 애플리케이션을 Kubernetes 환경에서 Blue/Green 배포 전략으로 무중단 전환하며, CI/CD 자동화를 실습합니다.

---

## 🧑‍💻 개발자 관점 (Dev)

### ✅ 기술 스택

| 분야     | 내용                      |
|----------|---------------------------|
| Web API  | FastAPI, Pydantic         |
| Database | SQLite3 (`/data/db.sqlite3`) |
| 테스트   | Pytest, Postman, Newman   |
| 문서화   | Swagger, ReDoc            |
| Dev Tool | Makefile, Docker Compose  |

### 🔧 개발 환경 실행

```bash
git clone https://github.com/rookieboba/fastapi-bluegreen-deploy.git
cd fastapi-bluegreen-deploy
make run-dev
```

> `make run-dev`는 `docker-compose.dev.yml`을 기반으로 FastAPI 앱을 실행합니다.

### 🧪 테스트

```bash
make test    # pytest 기반 단위 테스트
make newman  # Postman 시나리오 기반 API 테스트 (newman)
```

---

## 👷‍♂️ 인프라 엔지니어 관점 (Ops)

### ⚙️ 기술 스택

| 항목         | 내용                                               |
|--------------|----------------------------------------------------|
| Container    | Docker, DockerHub (`sungbin/fastapi-app`)         |
| Orchestration | Kubernetes (v1.30+)                               |
| 배포 전략     | Blue/Green Deployment                             |
| 자동화 도구  | GitHub Actions, Jenkins                           |
| DB 초기화     | InitContainer + ConfigMap + PVC                   |

---

## 🚀 배포 절차 (Blue → Green)

### 🛠 사전 준비

> 모든 **Worker Node**에 SQLite DB용 디렉토리를 수동 생성

```bash
sudo mkdir -p /mnt/data/sqlite
sudo chmod 777 /mnt/data/sqlite
```

### 📦 배포 명령어 (Master Node 기준)

```bash
# 1. 초기 SQL 설정 (ConfigMap)
kubectl apply -f k8s/v1/configmap-init-sql.yaml

# 2. PV/PVC 설정
kubectl apply -f k8s/v1/sqlite-volume.yaml

# 3. 초기 버전 배포 (v1, track=blue)
kubectl apply -f k8s/v1/blue-deployment.yaml

# 4. Service 생성
kubectl apply -f k8s/v1/service.yaml

# 5. 신규 버전 배포 (v2, track=green)
kubectl apply -f k8s/v1/green-deployment.yaml

# 6. 트래픽 전환 (Service Selector 변경)
kubectl patch service fastapi-service -p '{"spec":{"selector":{"app":"fastapi", "track":"green"}}}'
```

### 🔍 상태 확인 명령어

```bash
kubectl get pods -o wide
kubectl get svc
kubectl get endpoints
```

---

## 📂 Kubernetes 구성 파일

| 파일명                          | 설명                                 |
|----------------------------------|--------------------------------------|
| `blue-deployment.yaml`          | 기존 버전 (v1), `track: blue`        |
| `green-deployment.yaml`         | 신규 버전 (v2), `track: green`       |
| `service.yaml`                  | 공통 서비스 (Selector에 따라 전환)  |
| `configmap-init-sql.yaml`       | 초기 SQL 실행용 ConfigMap            |
| `sqlite-volume.yaml`            | PVC/PV 구성 (SQLite 파일 저장용)     |

---

## ⚙️ GitHub Actions (CI/CD)

`.github/workflows/fastapi-dev-pipeline.yml`  
- `main` 브랜치에 푸시 시 실행  
- Pytest → Docker 빌드 → DockerHub 푸시 순으로 자동화 처리

---

## 💡 학습 포인트

- Blue/Green 전략으로 무중단 배포 전환  
- InitContainer로 DB 초기화 처리  
- GitHub Actions + Jenkins 기반 자동화 구성  
- Pod 상태, Endpoints 확인 등 실무 환경 대응 능력 배양

---

## 🔗 관련 링크

- DockerHub: `docker.io/sungbin/fastapi-app:v1`, `v2`
- GitHub Actions: `.github/workflows/`

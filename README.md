# fastapi-bluegreen-deploy

FastAPI 기반 API 백엔드 프로젝트.  
Kubernetes + Argo Rollouts 환경에서 **Blue/Green 무중단 배포** 실습을 위한 구조로 구성됨.

---

## 기술 스택

| 구분 | 기술 |
|------|------|
| 언어 | Python 3.11 |
| 프레임워크 | FastAPI |
| 데이터베이스 | SQLite |
| 인프라 | Kubernetes v1.30 |
| GitOps | ArgoCD, Argo Rollouts |
| 모니터링 | Prometheus Operator |
| 기타 | GitHub Actions, DockerHub, Makefile 기반 자동화 |


---

## 📁 디렉토리 구조 (요약)

```
.
├── app/                    # FastAPI 앱 소스코드
├── sqlite3/                # 초기화 SQL 및 entrypoint
├── k8s/                    # Kubernetes 리소스 구성
├── docker-compose.*.yml    # 개발/운영용 Docker Compose 설정
├── Makefile                # 자주 쓰는 명령어 단축어
└── README.md
```

## 빠른 시작

### 1. git repo 받아오기

```bash
git clone https://github.com/rookieboba/fastapi-bluegreen-deploy
cd fastapi-bluegreen-deploy/
```

### 2. 개발환경 구축

2-1) 로컬 기반
```bash
make run-dev
```

2-2) 컨테이너 기반
```bash
make docker-dev
```

2-3) 컨테이너 종료
```bash
make docker-down
```

### 3. DockerHub로 이미지 Push

```bash
docker build -t terrnabin/fastapi_app:v1 .
docker push terrnabin/fastapi_app:v1
```

### 4. test

```bash
make test
```

### 5. coverage test

```bash
make test-cov
```

---

## ☸Kubernetes 배포 (Argo Rollouts 포함)

### 1. 전체 리소스 배포

```bash
make deploy
```

💡 생성되는 리소스:
- `ConfigMap`, `Secret`  
- `PersistentVolumeClaim`  
- `Service (active / preview)`  
- `Rollout`  
- `Ingress`  
- `HPA`  
- `ServiceMonitor`  
- `NetworkPolicy`

### 2. 트래픽 전환 (Blue → Green)

```bash
make promote
```

---

## 🔁 전체 리소스 초기화 (테스트 재시작용)

```bash
make clean
```

또는 수동 초기화:

```bash
kubectl delete all --all
kubectl delete pvc --all
kubectl delete rollout fastapi-rollout
```

---

## 💡 Blue/Green 배포 전략

이 프로젝트는 `Argo Rollouts`를 사용해 다음을 실현합니다:

- 새로운 버전(예: v2)을 미리 배포 (preview)
- 문제 없을 경우 수동 프로모션으로 트래픽 전환
- 기존 버전(v1)은 롤백용으로 대기

```yaml
strategy:
  blueGreen:
    activeService: fastapi-service-active
    previewService: fastapi-service-preview
    autoPromotionEnabled: false
```


### ✅ 참고

- 실제 `DockerHub 이미지` → `terrnabin/fastapi_app:v1`
- SQLite DB는 `/data/db.sqlite3` 위치로 PVC에 마운트됨
- 초기 데이터는 `/sqlite3/*.sql` 통해 InitContainer에서 삽입

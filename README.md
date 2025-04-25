
# FastAPI Blue/Green Deployment with Argo Rollouts

본 프로젝트는 FastAPI 기반의 백엔드 애플리케이션을 Kubernetes 환경에서 **무중단 배포(Blue/Green)** 방식으로 운영하기 위한 실습 예제입니다.  
CI/CD 자동화는 GitHub Actions + DockerHub를 통해 구성되며, 실시간 트래픽 전환은 Argo Rollouts를 통해 수행됩니다.

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

## 프로젝트 구조

```bash
.
├── app/                      # FastAPI 앱 디렉토리
├── tests/                   # pytest 기반 테스트 코드
├── sqlite3/                 # 초기 SQLite 스키마 및 entrypoint
├── k8s/                     # Kubernetes 관련 리소스 (아래 참고)
├── Makefile                 # 로컬 실행 및 배포 자동화 명령어
└── Dockerfile               # 운영용 이미지 빌드
```

---

## Blue/Green 배포 방식 설명

- `blue` = 현재 사용 중인 프로덕션 환경
- `green` = 신규 버전의 애플리케이션 (사전 테스트 및 배포 대상)
- Argo Rollouts는 preview/stable 서비스로 두 환경을 동시에 띄우고, 트래픽 전환을 제어합니다.
- `kubectl argo rollouts promote` 명령으로 green → blue 전환 (무중단 적용)

---

## 주요 명령어 (Makefile 기반)

```bash
# 로컬 개발 서버 실행 (SQLite 사용)
make run-dev

# 로컬에서 도커 이미지 빌드 및 실행
make docker-dev

# CI 환경에서 도커 이미지 빌드 및 DockerHub에 push
make docker-push

# K8s에 전체 리소스 배포 (Argo Rollouts 포함)
make deploy

# Blue/Green 트래픽 전환
make promote
```

---

## Kubernetes 리소스 구조 (`/k8s/` 디렉토리)

| 경로 | 설명 |
|------|------|
| `k8s/config/` | ConfigMap, Secret (DB 파일 경로, 환경설정 등) 생성 |
| `k8s/service/` | `fastapi-service-active`, `fastapi-service-preview` 두 개의 서비스 리소스 생성 |
| `k8s/rollout/` | `Rollout` 리소스 생성. Blue/Green 전략 적용 |
| `k8s/ingress/` | 외부 인그레스 경로 설정 (IngressClass 필요 시 수정) |
| `k8s/hpa/` | HorizontalPodAutoscaler (CPU 기반 자동 스케일링) |
| `k8s/policy/` | 네트워크 정책: 허용된 포트 및 네임스페이스 정의 |
| `k8s/monitoring/` | Prometheus `ServiceMonitor` 리소스 등록 (CRD 필요) |

> `make deploy` 명령으로 위 모든 리소스가 자동 적용됩니다.

---

## 초기화 방법

```bash
make clean

# 또는 수동 초기화
kubectl delete all --all
kubectl delete pvc --all
kubectl delete rollout fastapi-rollout
```

---

## Health Check

- `/health` 엔드포인트가 readinessProbe로 등록되어 있어, Argo Rollouts에서 트래픽 분기 시 상태 판단 기준으로 사용됩니다.

---

## 참고 명령어

```bash
# 상태 확인
kubectl argo rollouts get rollout fastapi-rollout

# 수동 트래픽 전환
kubectl argo rollouts promote fastapi-rollout

# 실패 시 재시도
kubectl argo rollouts restart rollout fastapi-rollout
```

---

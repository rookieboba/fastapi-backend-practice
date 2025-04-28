# FastAPI Blue-Green Deployment with Argo Rollouts

> 개발 파트
- FastAPI 엔드포인트와 Pydantic 모델을 설계·구현
- Docker 기반 개발환경(Dockerfile.dev, docker-compose.dev.yml) 및 pytest 테스트 스위트를 구축
- sqlite3 이용 DB

> 운영 파트
  - Kubernetes 매니페스트(k8s/)와 Argo Rollouts Blue-Green 전략을 작성·자동화(Makefile, CI 워크플로우)
  - Prometheus 모니터링 및 즉시 롤백 체계를 구성

---

## 목차

1. [Developer Quick Start](#developer-quick-start)  
2. [Operations Quick Start](#operations-quick-start)  
3. [개발팀 파트](#개발팀-파트)  
4. [운영팀 파트](#운영팀-파트)  
5. [배포 워크플로우](#배포-워크플로우)  
6. [Makefile 주요 명령](#makefile-주요-명령)  
7. [UI 접속](#ui-접속)  
8. [롤백 & 클린업](#롤백--클린업)  
9. [Troubleshooting](#troubleshooting)  

---

## Developer Quick Start

1. 코드 클론 & 디렉터리 이동  
   ```bash
   git clone https://github.com/rookieboba/fastapi-bluegreen-deploy.git
   cd fastapi-bluegreen-deploy
   ```
2. 로컬 개발 환경 기동  
   ```bash
   make docker-dev       # Docker 컨테이너에서 FastAPI 실행 (hot-reload)
   make run-dev          # 로컬에서 uvicorn 직접 실행
   ```
3. 단위 테스트  
   ```bash
   make test
   ```
4. 로컬 브라우저 확인  
   ```
   http://localhost:8000/docs
   ```

---

## Operations Quick Start

1. 클러스터에 리소스 최초 배포  
   ```bash
   make first-deploy
   make deploy-dashboard
   ```
2. Rollouts Dashboard, Workflows, ArgoCD UI 포트포워딩  
   ```bash
   make port-all
   ```
3. 신규 버전 프로모션  
   ```bash
   # 도커 이미지 태깅·푸시 후
   make rollout-promote IMAGE=your-repo/fastapi_app:v2
   make rollout-monitor
   ```
4. 서비스 상태 확인  
   ```bash
   kubectl get pods,svc,rollout -l app=fastapi
   ```

---

## 개발팀 파트

- **디렉터리**  
  - `app/` : FastAPI 코드  
  - `tests/` : pytest  
- **명령어**  
  ```bash
  make docker-dev    # 개발 컨테이너
  make run-dev       # uvicorn 로컬 실행
  make test          # 테스트
  ```
- **이미지**  
  - `Dockerfile.dev` : 개발용  
  - `Dockerfile` : 프로덕션용  

---

## 운영팀 파트

- **매니페스트** (`k8s/`)  
  - ConfigMap, Secret, PVC, Ingress, NetworkPolicy, HPA  
  - Blue-Green Services: `fastapi-active`, `fastapi-preview`  
  - Rollout CRD: `fastapi-rollout.yaml`  
- **자동화**  
  - Makefile: 배포, 프로모션, 포트포워딩, 클린업  
  - CI: GitHub Actions 워크플로우  
- **모니터링 & 복구**  
  - Prometheus ServiceMonitor  
  - Rollouts Dashboard  
  - 롤백: `kubectl argo rollouts undo rollout/fastapi-rollout`  

---

## 배포 워크플로우

1. **초기 배포**  
   ```bash
   make first-deploy
   make deploy-dashboard
   ```
2. **버전 업데이트**  
   ```bash
   make rollout-promote IMAGE=your-repo/fastapi_app:v2
   make rollout-monitor
   ```
3. **프로모션**  
   ```bash
   kubectl argo rollouts promote fastapi-rollout
   ```

---

## Makefile 주요 명령

|명령                   |설명                              |
|----------------------|---------------------------------|
|`make first-deploy`     |리소스 최초 배포                       |
|`make deploy-dashboard`|Rollouts Dashboard 설치              |
|`make rollout-promote`  |Green→Active 트래픽 전환               |
|`make rollout-monitor`  |Rollout 상태 실시간 모니터링           |
|`make port-all`         |UI 포트포워딩 (Rollouts/Workflows/ArgoCD) |
|`make clean`            |관련 리소스 일괄 삭제                  |
|`make reset`            |clean→first-deploy→deploy-dashboard→port-all 자동 실행 |

---

## UI 접속

- **서버 내부**:  
  ```bash
  make port-all
  ```
  - Rollouts Dashboard → http://localhost:3100  
  - Workflows UI       → http://localhost:2746  
  - ArgoCD UI          → http://localhost:8080  

- **외부 개발 PC**:  
  ```bash
  ssh -L 3100:localhost:3100 -L 2746:localhost:2746 -L 8080:localhost:8080 user@SERVER_IP
  ```

---

## 롤백 & 클린업

- **롤백**:  
  ```bash
  kubectl argo rollouts undo rollout/fastapi-rollout
  ```
- **전체 정리**:  
  ```bash
  make clean
  ```

---

## Troubleshooting

|증상               |원인                         |조치                                           |
|------------------|----------------------------|----------------------------------------------|
|노드 NotReady       |kubelet CSR CN mismatch      |`rm /var/lib/kubelet/pki/* && systemctl restart kubelet` 후 CSR 승인|
|Pod CrashLoopBackOff|CMD/Probe 포트 불일치        |Rollout manifest에 `command` 명시 & Probe 포트 수정|
|ImagePullBackOff  |이미지명/태그 오류             |`make rollout-promote IMAGE=…` 또는 매니페스트 수정|
|포트포워딩 실패     |포트 점유 중                  |`pkill -f port-forward` 후 `make port-all`           |

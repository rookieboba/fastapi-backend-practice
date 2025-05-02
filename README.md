# FastAPI Blue-Green Deployment with Argo Rollouts

> FastAPI 애플리케이션을 Kubernetes + Argo Rollouts 블루-그린 전략으로 자동 배포하는 예제
> Makefile 이용 간편화

![image](https://github.com/user-attachments/assets/1e66861f-0cc5-4402-a2db-5fd4c0a3a7c0)


---

## 목차

1. [Prerequisites (사전 요구사항)](#prerequisites-사전-요구사항)  
2. [Developer Quick Start (개발자 안내)](#developer-quick-start-개발자-안내)  
3. [Operator Quick Start (운영자 안내)](#operator-quick-start-운영자-안내)  
4. [프로젝트 구조](#프로젝트-구조)  
5. [CI/CD 워크플로우](#cicd-워크플로우)  
6. [Makefile 주요 명령](#makefile-주요-명령)  
7. [Troubleshooting (문제 해결)](#troubleshooting-문제-해결)  
8. [참고자료](#참고자료)  

---

## Prerequisites (사전 요구사항)

- **로컬 개발**  
  - Docker, Docker Compose  
  - Python 3.10+  
- **클러스터 환경**  
  - Kubernetes v1.24+ 클러스터  
  - `kubectl` CLI  
  - Argo Rollouts Controller & CRD 설치  
  - (옵션) Argo CD, Prometheus, Ingress Controller  

---

## Developer Quick Start (개발자 안내)

1. **레포 클론 & 디렉터리 이동**  
   ```bash
   git clone https://github.com/rookieboba/fastapi-bluegreen-deploy.git
   cd fastapi-bluegreen-deploy
   ```

2. **개발 컨테이너 기동 (hot-reload)**  
   ```bash
   make docker-dev
   # → http://localhost:8000/docs 에서 API 확인
   ```

3. **로컬 서버 직접 실행**  
   ```bash
   make run-dev
   # → http://localhost:8000/docs
   ```

4. **단위 테스트 & 커버리지**  
   ```bash
   make test
   make test-cov    # HTML 리포트는 htmlcov/index.html
   ```

---

## Operator Quick Start (운영자 안내)

1. **클러스터에 리소스 최초 배포**  
   ```bash
   make deploy
   ```
2. **Roll out 상태 확인**  
   ```bash
   make rollout-monitor
   ```
3. **새 이미지 적용**  
     ```bash
    kubectl argo rollouts set image fastapi-rollout fastapi=terrnabin/fastapi_app:v2 -n fastapi
    kubectl apply -k k8s/ -n fastapi
    docker images
    ```
4. 버전 승격 (새 이미지 적용)
   ```bash
   make rollout-promote
   ```
5. **이전 버전 번복**  
   ```bash
   make rollout-undo
   ```
6. **재시작**  
   ```bash
   make rollout-restart
   ```

![image](https://github.com/user-attachments/assets/df4693c8-43ee-49db-9f59-c701fbc6bec0)

---

## CI/CD 워크플로우

1. **개발 빌드**  
2. **QA 테스트 통과 시**  
   - Docker Hub에 이미지 태그 `vX.Y.Z` 푸시  
3. **클러스터에 새 이미지 롤아웃**  
   ```bash
   docker pull terrnabin/fastapi_app:v2
   kubectl argo rollouts set image fastapi-rollout fastapi=terrnabin/fastapi_app:v2 -n fastapi
   kubectl argo rollouts get rollout fastapi-rollout -n fastapi
   ```
4. **검증 후** `make rollout-promote` 로 Active 서비스 전환  
5. **Github Action 이용** Slack Alert / Email Alert / Sync ArgoCD 설정 
---

---

## 프로젝트 구조

```
.
├── app/                      # FastAPI 애플리케이션 코드
├── tests/                    # pytest 테스트 코드
├── Dockerfile                # 프로덕션 이미지
├── Dockerfile.dev            # 개발 이미지 (hot-reload)
├── docker-compose.dev.yml    # 개발용 Compose 설정
├── k8s/                      # Kubernetes 매니페스트
│   ├── namespace.yaml
│   ├── argo/                 # Argo Rollouts Controller 설치
│   ├── install.yaml          # Rollouts CRD 설치
│   ├── config/               # PV, PVC, ConfigMap, Secret
│   ├── rollout/              # fastapi-rollout.yaml
│   ├── hpa/                  # HPA 설정
│   ├── ingress/              # Ingress 설정
│   └── policy/               # NetworkPolicy
├── Makefile                  # 배포 자동화 스크립트
└── README.md
```

## Makefile 주요 명령

|명령                         |설명                                 |
|----------------------------|------------------------------------|
|`make deploy`               |전체 네임스페이스·리소스 최초 배포           |
|`make rollout-promote`      |Blue→Green 서비스 전환                 |
|`make rollout-monitor`      |Rollout 상태 실시간 모니터링             |
|`make undeploy`             |네임스페이스·PVC·PV·CRD 등 전체 삭제       |
|`make docker-dev`           |개발용 Docker Compose 기동 (hot-reload)|
|`make run-dev`              |로컬 uvicorn 서버 기동                  |
|`make test` / `make test-cov`|단위 테스트 및 커버리지 측정            |

---

## Troubleshooting (문제 해결)

|증상                      |원인                                      |조치                                                    |
|-------------------------|-----------------------------------------|-------------------------------------------------------|
|Pod CrashLoopBackOff      |Liveness/Readiness Probe 경로 불일치           |`k8s/argo/argo-rollouts-install.yaml`의 `path` 수정         |
|PVC 삭제 지연              |Finalizer로 삭제 블록                         |`kubectl patch pvc … {"metadata":{"finalizers":[]}}` 실행 |
|롤아웃 세컨드 서비스 미노출|Service selector 레이블 누락                  |`fastapi-active` / `fastapi-preview` 의 `selector` 점검    |
|ImagePullBackOff          |이미지명·태그 오타 혹은 레지스트리 인증 실패      |`docker pull` / `docker tag` / `docker push` 재확인       |

---

## 참고자료

- Argo Rollouts 공식문서 https://argoproj.github.io/argo-rollouts  
- Kubernetes Blue-Green 배포 패턴 https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#blue-green-deployments  
- GitHub Actions CI 예제 https://docs.github.com/actions


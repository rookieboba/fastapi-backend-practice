# FastAPI Blue/Green Deployment Practice

> **목표**: FastAPI 백엔드 서버를 로컬 개발부터 Kubernetes Blue/Green 무중단 배포까지 체계적으로 구성합니다.

---

## 프로젝트 개요

- **FastAPI** 기반 웹 애플리케이션 개발
- **SQLite3**를 사용한 경량 DB 구성
- **Docker**로 이미지 빌드 및 관리
- **GitHub Actions**를 통한 CI 파이프라인 구축
- **Argo Rollouts**를 활용한 Blue/Green 배포 전략 구현
- **Kubernetes** 위에서 운영 환경 구성


## 디렉토리 구조 (중요 파일만)

```bash
fastapi-bluegreen-deploy/
├── app/                  # FastAPI 앱 디렉토리
├── k8s/                  # Kubernetes 리소스 매니페스트
│   ├── config/           # ConfigMap, Secret
│   ├── rollout/          # Rollout 리소스 (Argo Rollouts)
│   ├── service/          # Active/Preview 서비스 정의
│   ├── ingress/          # Ingress 설정
│   ├── hpa/              # Horizontal Pod Autoscaler 설정
│   ├── policy/           # NetworkPolicy 설정
│   ├── monitoring/       # ServiceMonitor 설정
│   └── kustomization.yaml
├── Dockerfile            # 운영용 Dockerfile
├── Dockerfile.dev        # 개발용 Dockerfile
├── docker-compose.dev.yml # 로컬 개발용 Compose 파일
├── docker-compose.prod.yml # 운영용 Compose 파일
├── requirements.txt      # Python 의존성 목록
├── Makefile              # 명령어 단축 스크립트
├── README.md             # 설명 문서
└── tests/                # 테스트 코드 및 Postman 파일
```


## 사용 기술 스택

| 구분        | 기술                                                     |
| ----------- | -------------------------------------------------------- |
| Backend     | FastAPI, Uvicorn, Pydantic                                |
| Database    | SQLite3 (경량 로컬 DB)                                   |
| Container   | Docker, Docker Compose                                   |
| CI          | GitHub Actions                                            |
| CD          | Argo Rollouts (Kubernetes Blue/Green 배포)                |
| Monitoring  | Prometheus Operator (ServiceMonitor CRD 사용)             |
| Infra       | Kubernetes (v1.30.x), NodePort 서비스, Ingress (Nginx)    |


## 로컬 개발 실행 방법

```bash
# 1. Git 클론
$ git clone https://github.com/rookieboba/fastapi-bluegreen-deploy.git
$ cd fastapi-bluegreen-deploy

# 2. 로컬 개발 환경 빌드 및 실행
$ docker-compose -f docker-compose.dev.yml up --build

# 3. 확인
# 로컬 서버: http://localhost:8000/docs (Swagger)
```


## Kubernetes 배포 방법 (Argo Rollouts 기반)

```bash
# 1. k8s 리소스 적용 (기본 리소스 생성)
$ kubectl apply -k k8s/

# 2. Docker 이미지 빌드 및 Push
$ docker build -t terrnabin/fastapi_app:v1 .
$ docker push terrnabin/fastapi_app:v1

# 3. Rollout 리소스 새로고침 (Blue 배포 시작)
$ kubectl-argo-rollouts get rollout fastapi-rollout

# 4. Preview 상태 확인 (Argo Rollouts 대시보드 or CLI)

# 5. 트래픽 전환 (Promote)
$ kubectl-argo-rollouts promote fastapi-rollout
```


## Blue/Green 배포 전략 핵심 흐름

1. **Preview** 환경에 새 버전(그린)을 배포 → 안정성 체크
2. **Promote** 명령으로 트래픽을 블루 → 그린으로 전환
3. 문제 발생 시 즉시 Rollback 가능 (Stable 레이블 사용)


## FastAPI 주요 엔드포인트

- `GET /health` : 헬스체크용 API (K8S Readiness Probe에 연결)
- `GET /users` : 사용자 목록 조회
- `POST /users` : 신규 사용자 생성


## 참고

- Kubernetes 클러스터 구성: Master 1대, Worker 3대 (Flannel 네트워크)
- Prometheus Operator 설치로 ServiceMonitor 리소스 적용 가능
- Argo Rollouts CLI (`kubectl-argo-rollouts`) 사용 중

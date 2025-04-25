# FastAPI Blue/Green 배포 실습 (Production-ready)

FastAPI 기반 내부 API 서버를 GitOps 기반으로 운영하는 구조를 실습합니다.  
실제 게임사에서 사용하는 방식처럼 CI/CD 자동화, Blue/Green 트래픽 전환, 무중단 PVC 구성, ArgoCD 배포 전략을 적용했습니다.

---

## 🎯 목적

- 개발자의 Docker 이미지가 GitHub Actions를 통해 자동 배포됨
- 운영자는 ArgoCD에서 배포 현황 모니터링 및 Service만으로 트래픽 전환
- 무중단 PVC 환경을 기반으로, 버전 간 공존 + 롤백 가능한 구조 설계

---

## 👨‍💻 개발자 로컬 실행 가이드

```bash
# 1. GitHub에서 프로젝트 클론
git clone https://github.com/rookieboba/fastapi-bluegreen-deploy.git
cd fastapi-bluegreen-deploy

# 2. 가상환경 설정
python -m venv venv
source venv/bin/activate

# 3. 개발 환경 실행
make install  # requirements.txt 설치
make run-dev  # uvicorn으로 FastAPI 실행
```

기본 개발 포트는 `8000`이며, Swagger UI는 `/docs`, Health Check는 `/health` 엔드포인트로 구성

## 📁 엔지니어 디렉토리 구성

```plaintext
manifests/
├── base/               # 공통 리소스 (PVC, Service)
├── v1/                 # blue 버전 (기존 운영)
├── v2/                 # green 버전 (신규 배포)
├── init-sql/           # 초기 데이터 ConfigMap
```

---

## 🧪 운영 시나리오

1. `fastapi_app:v2` 이미지가 GitHub Actions를 통해 DockerHub에 push됨
2. ArgoCD가 manifests/v2 경로 감지 → green 버전 배포
3. 운영자는 ArgoCD UI 또는 Git commit으로 service selector를 green으로 전환
4. 실시간 트래픽이 blue → green 으로 무중단 전환됨

---

## 🚀 실행/배포 요약

```bash
# 1. 공통 리소스
kubectl apply -f manifests/base/

# 2. 초기 SQL ConfigMap
kubectl apply -f manifests/init-sql/

# 3. v1 (blue) 배포
kubectl apply -f manifests/v1/

# 4. v2 (green) 배포
kubectl apply -f manifests/v2/

# 5. 트래픽 전환
kubectl patch svc fastapi-service -p '{"spec":{"selector":{"app":"fastapi","version":"green"}}}'
```

---

## 🔁 CI/CD 흐름

```plaintext
[Dev]
 └── GitHub push
       ↓
[CI]
 └── GitHub Actions: Test + Build + Push
       ↓
[CD]
 └── ArgoCD auto-sync
       ↓
[OPS]
 └── Service selector 변경 → 무중단 전환
```

---


---

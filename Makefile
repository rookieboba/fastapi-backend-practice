.DEFAULT_GOAL := help
.PHONY: deploy undeploy

# ========================
# 공통 변수
# ========================
ENV             ?= dev
PROJECT_NAME    := fastapi
RELEASE_NAME    := $(PROJECT_NAME)-$(ENV)
NAMESPACE       := $(PROJECT_NAME)-$(ENV)
CHART_DIR       := helm/fastapi-app
IMAGE_REPO      := terrnabin/fastapi_app
TAG             ?= $(shell git describe --always --dirty)

DOCKER_COMPOSE  := $(shell command -v docker-compose > /dev/null 2>&1 && echo docker-compose || echo docker compose)

# ========================
# 헬프 및 정보 출력
# ========================
help: ## 사용 가능한 명령어 목록 출력
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  %-25s %s\n", $$1, $$2}'

info: ## 현재 환경 정보 출력
	@echo "ENV:           $(ENV)"
	@echo "NAMESPACE:     $(NAMESPACE)"
	@echo "TAG:           $(TAG)"
	@echo "IMAGE_REPO:    $(IMAGE_REPO)"
	@echo "CHART_DIR:     $(CHART_DIR)"
	@echo "DOCKER_COMPOSE: $(DOCKER_COMPOSE)"

# ========================
# 로컬 개발 환경
# ========================
run-dev: ## FastAPI 로컬 개발 서버 실행
	uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload

docker-dev: ## Docker Compose 개발 환경 실행
	$(DOCKER_COMPOSE) -f docker-compose.dev.yml up --build -d

docker-down: ## Docker Compose 환경 중지
	$(DOCKER_COMPOSE) -f docker-compose.dev.yml down

# ========================
# 테스트
# ========================
test: ## 단위 테스트 실행
	$(DOCKER_COMPOSE) -f docker-compose.dev.yml run --rm web \
		bash -c "PYTHONPATH=/src pytest --cov=src tests/"

test-cov: ## 커버리지 리포트 생성
	$(DOCKER_COMPOSE) -f docker-compose.dev.yml run --rm web \
		bash -c "PYTHONPATH=/src pytest --cov=src --cov-report=html tests/"

# ========================
# 이미지 태그 업데이트
# ========================
update-image: ## Helm values.yaml 내 이미지 태그 변경
	@if [ -z "$(TAG)" ]; then \
		echo "[ERROR] TAG 값을 지정하세요 (예: make update-image TAG=v2)"; exit 1; \
	fi
	sed -i.bak "s|image: .*|image: $(IMAGE_REPO):$(TAG)|" \
		$(CHART_DIR)/values.yaml
	rm -f $(CHART_DIR)/values.yaml.bak
	@echo "이미지 태그를 $(TAG)로 업데이트 완료"

# ========================
# 유효성 검사
# ========================
lint: ## Helm 템플릿 문법 검사
	helm lint $(CHART_DIR)

dry-run: ## 템플릿 렌더링 + kubeval 검사
	helm template $(RELEASE_NAME) $(CHART_DIR) --namespace $(NAMESPACE) | kubeval --strict

# ========================
# 배포 및 롤백
# ========================
install: 
	echo "✅ [1/5] Helm 설치 중..."
	curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

	echo "✅ [2/5] ArgoCD 설치 중..."
	kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

	echo "✅ [3/5] Argo Rollouts 설치 중..."
	kubectl create namespace argo-rollouts --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

	echo "✅ [4/5] Argo Rollouts CRD 적용 확인..."
	kubectl get crd | grep rollouts.argoproj.io

	echo "✅ [5/5] 포트포워딩 (ArgoCD UI: localhost:9999)"
	kubectl port-forward svc/argocd-server -n argocd 9999:443 &

deploy:
	kubectl apply -k ./k8s

undeploy:
	kubectl delete -k ./k8s

reset-dev: ## 전체 삭제 후 재배포
	$(MAKE) undeploy ENV=$(ENV)
	$(MAKE) deploy ENV=$(ENV)

# ========================
# Argo Rollouts 제어
# ========================
rollout-promote: ## Preview → Active 전환
	kubectl argo rollouts promote $(RELEASE_NAME) -n $(NAMESPACE)

rollout-monitor: ## Rollout 상태 실시간 확인
	kubectl argo rollouts get rollout $(RELEASE_NAME) -n $(NAMESPACE) --watch

rollout-undo: ## 이전 버전 롤백
	kubectl argo rollouts undo $(RELEASE_NAME) -n $(NAMESPACE)

# ========================
# CI/CD 전용 타겟
# ========================
ci: test lint dry-run ## CI 파이프라인용 검증 타겟

release: update-image deploy ## GitHub Actions 릴리즈용 배포 실행

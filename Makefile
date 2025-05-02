# Makefile for FastAPI Blue-Green + Argo Rollouts 자동화

# ===================
# 공통 변수
# ===================
DOCKER_COMPOSE      := $(shell command -v docker-compose > /dev/null 2>&1 && echo docker-compose || echo docker compose)
COMPOSE_FILE        := docker-compose.dev.yml
ARGO_NS             ?= argo-rollouts
NAMESPACE_FASTAPI   ?= fastapi
ROLLOUT_NAME        ?= fastapi-rollout

# ===================
# 개발 환경
# ===================

run-dev:
	uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

docker-dev:
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) up --build -d
	docker ps

docker-down:
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) down

# ===================
# 테스트
# ===================

test:
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) run --rm web \
		bash -c "env PYTHONPATH=/app pytest --cov=app --cov-report=term tests/"

test-cov:
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) run --rm web \
		bash -c "env PYTHONPATH=/app pytest --cov=app --cov-report=html tests/"

db-check:
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) exec web \
		bash -c "sqlite3 /app/data/db.sqlite3 '.tables'; sqlite3 /app/data/db.sqlite3 'SELECT * FROM payments;'"

# ===================
# Kubernetes 배포
# ===================

deploy:
	@echo "[INFO] Creating namespaces"
	kubectl apply -f k8s/namespace.yaml

	@echo "[INFO] Applying all manifests"
	kubectl apply -k k8s/
	kubectl get all -n $(NAMESPACE_FASTAPI)
	kubectl get all -A -o wide

install-argocd:
	@echo "[INFO] Installing ArgoCD"
	kubectl create ns argocd --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

install-rollouts:
	@echo "[INFO] Installing Argo Rollouts"
	kubectl create ns $(ARGO_NS) --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n $(ARGO_NS) -f https://raw.githubusercontent.com/argoproj/argo-rollouts/stable/manifests/install.yaml

undeploy:
	@echo "[INFO] Deleting FastAPI app rollout and services"
	kubectl delete rollout $(ROLLOUT_NAME) -n $(NAMESPACE_FASTAPI) --ignore-not-found
	kubectl delete svc fastapi-service-active -n $(NAMESPACE_FASTAPI) --ignore-not-found
	kubectl delete svc fastapi-service-preview -n $(NAMESPACE_FASTAPI) --ignore-not-found

	@echo "[INFO] Deleting only app-specific ConfigMaps and PVCs"
	kubectl delete configmap fastapi-config -n $(NAMESPACE_FASTAPI) --ignore-not-found
	kubectl delete pvc --selector=app=fastapi -n $(NAMESPACE_FASTAPI) --ignore-not-found

	@echo "[INFO] Skipping ArgoCD, Argo Rollouts, and CRD deletion"

	@echo "[INFO] Undeploy complete"
	kubectl get all -n $(NAMESPACE_FASTAPI)

reset:
	$(MAKE) undeploy
	$(MAKE) deploy
	@echo "[INFO] Reset and redeploy completed"

# ===================
# Rollouts 제어
# ===================

rollout-promote:
	kubectl argo rollouts promote $(ROLLOUT_NAME) -n $(NAMESPACE_FASTAPI)
	kubectl argo rollouts get rollout $(ROLLOUT_NAME) -n $(NAMESPACE_FASTAPI)

rollout-monitor:
	kubectl argo rollouts get rollout $(ROLLOUT_NAME) -n $(NAMESPACE_FASTAPI) --watch

rollout-revision:
	kubectl argo rollouts get rollout $(ROLLOUT_NAME) -n $(NAMESPACE_FASTAPI) --revision

rollout-restart:
	kubectl argo rollouts restart $(ROLLOUT_NAME) -n $(NAMESPACE_FASTAPI)

rollout-undo:
	kubectl argo rollouts undo $(ROLLOUT_NAME) -n $(NAMESPACE_FASTAPI)

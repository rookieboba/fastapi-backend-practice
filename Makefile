# Makefile for FastAPI Blue-Green + Argo Rollouts 자동화

DOCKER_COMPOSE := $(shell command -v docker-compose > /dev/null 2>&1 && echo docker-compose || echo docker compose)
SERVER_IP      := $(shell hostname -I | awk '{print $$1}')

# FastAPI 서비스 노드포트 (NodePort)
PORT_FASTAPI_ACTIVE  := 30080
PORT_FASTAPI_PREVIEW := 30081

# Argo Rollouts Dashboard
PORT_ARGO_ROLLOUTS := 3100

# Argo Workflows 서버 → ClusterIP 80 → 로컬 포트
PORT_WORKFLOWS_LOCAL  := 2746
PORT_WORKFLOWS_REMOTE := 80

# ArgoCD 서버 → ClusterIP 80 → 로컬 포트
PORT_ARGOCD_LOCAL  := 8080
PORT_ARGOCD_REMOTE := 80

# ===================
# 개발 환경
# ===================

run-dev:
	uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

docker-dev:
	$(DOCKER_COMPOSE) -f docker-compose.dev.yml up --build -d
	@echo "[INFO] Docker containers are running:"
	docker ps

docker-down:
	$(DOCKER_COMPOSE) -f docker-compose.dev.yml down
	@echo "[INFO] Docker containers stopped."

test:
	$(DOCKER_COMPOSE) -f docker-compose.dev.yml run --rm web \
		bash -c "env PYTHONPATH=/app pytest --cov=app --cov-report=term tests/"

test-cov:
	$(DOCKER_COMPOSE) -f docker-compose.dev.yml run --rm web \
		bash -c "env PYTHONPATH=/app pytest --cov=app --cov-report=html tests/"

# ===================
# Kubernetes 배포
# ===================

clean:
	@echo "[INFO] Cleaning Kubernetes resources..."
	@if [ -n "$$(docker ps -qa)" ]; then \
		docker stop $$(docker ps -qa); \
	fi

	@if [ -n "$$(docker ps -qa)" ]; then \
		docker rm $$(docker ps -qa); \
	fi

	@if [ -n "$$(docker images -q)" ]; then \
		docker rmi -f $$(docker images -q); \
	fi
	- kubectl delete ns fastapi argo-rollouts argocd argo
	@echo "[INFO] Clean completed."

first-deploy:
	@echo "[INFO] Creating Namespace"
	kubectl apply -f k8s/namespace.yaml
	@echo "[INFO] Applying all k8s manifests..."
	kubectl apply -k k8s/
	@echo "[INFO] First deployment completed."
	kubectl get pods,svc,deploy,rollout

deploy-all: first-deploy deploy-dashboard

rollout-promote:
	@echo "[INFO] Promoting FastAPI Rollout..."
	kubectl argo rollouts promote fastapi-rollout
	kubectl argo rollouts get rollout fastapi-rollout

rollout-monitor:
	kubectl argo rollouts get rollout fastapi-rollout --watch

rollout-revision:
	kubectl argo rollouts get rollout fastapi-rollout --revision

# ===================
# 포트 포워딩 자동화
# ===================

port-all:
	@echo "[INFO] Cleaning up existing port-forward processes..."
	- pkill -f "port-forward.*:$(PORT_ARGO_ROLLOUTS):3100"
	- pkill -f "port-forward.*:$(PORT_WORKFLOWS_LOCAL):$(PORT_WORKFLOWS_REMOTE)"
	- pkill -f "port-forward.*:$(PORT_ARGOCD_LOCAL):$(PORT_ARGOCD_REMOTE)"

	@echo "[INFO] Starting port-forward..."
	# 1) Argo Rollouts Dashboard → localhost:3100
	kubectl -n argo-rollouts port-forward deployment/argo-rollouts-dashboard \
		$(PORT_ARGO_ROLLOUTS):3100 &

	# 2) Argo Workflows UI → localhost:2746
	kubectl -n argo port-forward svc/argo-workflows-server \
		$(PORT_WORKFLOWS_LOCAL):$(PORT_WORKFLOWS_REMOTE) &

	# 3) ArgoCD UI → localhost:8080
	kubectl -n argocd port-forward svc/argocd-server \
		$(PORT_ARGOCD_LOCAL):$(PORT_ARGOCD_REMOTE) &

	wait
	@echo "[INFO] Port Forwarded:"
	@echo "  - Rollouts Dashboard → http://localhost:$(PORT_ARGO_ROLLOUTS)"
	@echo "  - Workflows UI       → http://localhost:$(PORT_WORKFLOWS_LOCAL)"
	@echo "  - ArgoCD UI          → http://localhost:$(PORT_ARGOCD_LOCAL)"

reset:
	@$(MAKE) clean
	@$(MAKE) deploy-all
	@$(MAKE) deploy-dashboard
	@$(MAKE) port-all
	@echo "[INFO] Reset and redeploy completed."


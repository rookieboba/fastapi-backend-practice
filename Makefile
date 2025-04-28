# Makefile for FastAPI Blue-Green + Argo Rollouts 자동화

DOCKER_COMPOSE := $(shell command -v docker-compose > /dev/null 2>&1 && echo docker-compose || echo docker compose)
SERVER_IP      := $(shell hostname -I | awk '{print $$1}')

# FastAPI 서비스 노드포트 (NodePort)
PORT_FASTAPI_ACTIVE  := 30080
PORT_FASTAPI_PREVIEW := 30081

NAMESPACE_FASTAPI ?= fastapi
ROLLOUT_NAME ?= fastapi-rollout

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

# ===================
# 테스트
# ===================

test:
	@echo "[INFO] 실행: pytest 단위 테스트 + 커버리지 측정 (터미널 출력)"
	$(DOCKER_COMPOSE) -f docker-compose.dev.yml run --rm web \
		bash -c "env PYTHONPATH=/app pytest --cov=app --cov-report=term tests/"

test-cov:
	@echo "[INFO] 실행: pytest 단위 테스트 + 커버리지 측정 (HTML 리포트 생성)"
	$(DOCKER_COMPOSE) -f docker-compose.dev.yml run --rm web \
		bash -c "env PYTHONPATH=/app pytest --cov=app --cov-report=html tests/"

db-check:
	@echo "[INFO] 실행: 개발용 컨테이너 내부 SQLite 데이터베이스 확인"
	$(DOCKER_COMPOSE) -f docker-compose.dev.yml exec web \
		bash -c "sqlite3 /app/data/db.sqlite3 '.tables'; sqlite3 /app/data/db.sqlite3 'SELECT * FROM payments;'"


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
	@echo "[INFO] Deleting existing PV and PVC..."
	- rm -rf /mnt/data/sqlite
	- mkdir -p /mnt/data/sqlite
	- kubectl delete pvc sqlite-pvc -n fastapi || true
	- kubectl patch pv sqlite-pv -p '{"spec":{"claimRef": null}}' || true
	- kubectl delete pv sqlite-pv || true
	- kubectl delete ns fastapi argocd argo monitoring 
	@echo "[INFO] Clean completed."

deploy:
	@echo "[INFO] Creating Namespace"
	kubectl apply -f k8s/namespace.yaml
	@echo "[INFO] Installing Argo Rollouts Controller..."
	kubectl apply -f k8s/argo/argo-rollouts-install.yaml
	@echo "[INFO] Applying all k8s manifests..."
	kubectl apply -k k8s/
	@echo "[INFO] First deployment completed."
	kubectl get pods,svc,deploy,rollout -n $(NAMESPACE_FASTAPI)

rollout-promote:
	@echo "[INFO] Promoting FastAPI Rollout..."
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


reset:
	@$(MAKE) clean
	@$(MAKE) deploy
#	@$(MAKE) deploy-dashboard
#	@$(MAKE) port-all
	@echo "[INFO] Reset and redeploy completed."


# Makefile for FastAPI Blue-Green + Argo Rollouts 자동화

DOCKER_COMPOSE := $(shell command -v docker-compose > /dev/null 2>&1 && echo docker-compose || echo docker compose)
SERVER_IP      := $(shell hostname -I | awk '{print $$1}')

# FastAPI 서비스 노드포트 (NodePort)
PORT_FASTAPI_ACTIVE  := 30080
PORT_FASTAPI_PREVIEW := 30081

ARGO_NS            ?= argo-rollouts
NAMESPACE_FASTAPI  ?= fastapi
ROLLOUT_NAME       ?= fastapi-rollout

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
	@echo "[INFO] pytest 단위 테스트 + 커버리지 측정"
	$(DOCKER_COMPOSE) -f docker-compose.dev.yml run --rm web \
		bash -c "env PYTHONPATH=/app pytest --cov=app --cov-report=term tests/"

test-cov:
	@echo "[INFO] pytest 단위 테스트 + 커버리지 HTML 리포트"
	$(DOCKER_COMPOSE) -f docker-compose.dev.yml run --rm web \
		bash -c "env PYTHONPATH=/app pytest --cov=app --cov-report=html tests/"

db-check:
	@echo "[INFO] 개발용 컨테이너 내부 SQLite 확인"
	$(DOCKER_COMPOSE) -f docker-compose.dev.yml exec web \
		bash -c "sqlite3 /app/data/db.sqlite3 '.tables'; sqlite3 /app/data/db.sqlite3 'SELECT * FROM payments;'"

# ===================
# Kubernetes 배포
# ===================

clean:
	@echo "[INFO] Stop & remove all local containers/images"
	@if [ "$$(docker ps -q)" ]; then docker stop $$(docker ps -q) && docker rm -f $$(docker ps -q); fi
	@if [ "$$(docker images -q)" ]; then docker rmi -f $$(docker images -q); fi

undeploy: clean
	@echo "Remove and remake bind directory"
	rm -rf /mnt/data/sqlite
	mkdir -p /mnt/data/sqlite
	@echo "[INFO] Deleting all deployed namespaces…"
	kubectl delete ns $(NAMESPACE_FASTAPI) argocd argo monitoring $(ARGO_NS) \
	  --ignore-not-found --grace-period=0 --timeout=30s --wait=false

	@echo "[INFO] Clearing finalizers on $(NAMESPACE_FASTAPI) namespace (if stuck)…"
	kubectl get ns $(NAMESPACE_FASTAPI) -o json \
	  | jq '.spec.finalizers=[]' \
	  | kubectl apply -f - || true
	kubectl delete ns $(NAMESPACE_FASTAPI) --ignore-not-found || true

	@echo "[INFO] Forcing removal of $(NAMESPACE_FASTAPI) PVCs…"
	kubectl get pvc -n $(NAMESPACE_FASTAPI) -o name \
	  | xargs -r -n1 kubectl patch --type=merge -p='{"metadata":{"finalizers":[]}}' -n $(NAMESPACE_FASTAPI)
	kubectl delete pvc --all -n $(NAMESPACE_FASTAPI) --force --grace-period=0 --ignore-not-found

	@echo "[INFO] Forcing removal of PVs…"
	kubectl get pv -o name \
	  | xargs -r -n1 kubectl patch --type=merge -p='{"spec":{"claimRef":null},"metadata":{"finalizers":[]}}'
	kubectl delete pv -l app=fastapi --force --grace-period=0 --ignore-not-found

	@echo "[INFO] Deleting Argo Rollouts CRDs…"
	kubectl delete crd rollouts.argoproj.io experiments.argoproj.io \
	  analysisruns.analysis.argoproj.io analysistemplates.analysis.argoproj.io \
	  --ignore-not-found

	@echo "[INFO] Undeploy complete."
	kubectl get all -A -o wide

deploy:
	@echo "[INFO] Creating namespaces"
	kubectl apply -f k8s/namespace.yaml

	@echo "[INFO] Installing Argo Rollouts Controller…"
	kubectl create ns $(ARGO_NS) --dry-run=client -o yaml | kubectl apply -f -
	#kubectl apply -n $(ARGO_NS) -f k8s/argo/install.yaml
	kubectl apply -n argo-rollouts -f https://raw.githubusercontent.com/argoproj/argo-rollouts/stable/manifests/install.yaml

	@echo "[INFO] Applying all k8s manifests…"
	kubectl apply -k k8s/

	@echo "[INFO] First deployment completed."
	kubectl get all -n $(NAMESPACE_FASTAPI)
	kubectl get all -A -o wide

rollout-promote:
	@echo "[INFO] Promoting FastAPI Rollout…"
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
	@$(MAKE) undeploy
	@$(MAKE) deploy
	@echo "[INFO] Reset and redeploy completed."


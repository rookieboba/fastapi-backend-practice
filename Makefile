DOCKER_COMPOSE := $(shell command -v docker-compose > /dev/null 2>&1 && echo docker-compose || echo docker compose)
SERVER_IP := $(shell hostname -I | awk '{print $$1}')
PORT_FASTAPI_ACTIVE := 30080
PORT_FASTAPI_PREVIEW := 30081
PORT_ARGO_ROLLOUTS := 3100
PORT_ARGO_WORKFLOWS := 2746
PORT_ARGOCD := 8080

# ===================
# 🧪 개발 환경
# ===================

run-dev:
	uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload -d

docker-dev:
	$(DOCKER_COMPOSE) -f docker-compose.dev.yml up --build -d
	@echo "[INFO] Docker containers are running:"
	docker ps

docker-down:
	${DOCKER_COMPOSE} -f docker-compose.dev.yml down
	@echo "[INFO] Docker containers stopped."
	
test:
	$(DOCKER_COMPOSE) -f docker-compose.dev.yml run --rm web \
		bash -c "env PYTHONPATH=/app pytest --cov=app --cov-report=term tests/" -d

test-cov:
	$(DOCKER_COMPOSE) -f docker-compose.dev.yml run --rm web \
		bash -c "env PYTHONPATH=/app pytest --cov=app --cov-report=html tests/" -d

# ===================
# Kubernetes
# ===================

first-deploy:
	kubectl apply -f k8s/argo/argo-rollouts-install.yaml
	kubectl apply -k k8s/
	kubectl get all
	@echo "[INFO] First deployment completed."
	kubectl get pods,svc,deploy,rollout

deploy-all:
	kubectl apply -f k8s/argo/argo-rollouts-install.yaml
	kubectl apply -k k8s/
	kubectl get all
	@echo "[INFO] Full deployment completed."
	kubectl get pods,svc,deploy,rollout

deploy-dashboard:
	kubectl apply -f k8s/argo/argo-rollouts-dashboard-install.yaml
	@echo "[INFO] Argo Rollouts Dashboard installed from local file."
	kubectl get deploy -n argo-rollouts

rollout-promote:
	kubectl argo rollouts promote fastapi-rollout
	@echo "[INFO] Rollout promoted."
	kubectl argo rollouts get rollout fastapi-rollout

rollout-monitor:
	kubectl argo rollouts get rollout fastapi-rollout --watch

rollout-revision:
	kubectl argo rollouts get rollout fastapi-rollout --revision

port-all:
	kubectl -n argo-rollouts port-forward deployment/argo-rollouts-dashboard $(PORT_ARGO_ROLLOUTS):3100 & \
	kubectl -n argo port-forward svc/argo-workflows-server $(PORT_ARGO_WORKFLOWS):2746 & \
	kubectl -n argocd port-forward svc/argocd-server $(PORT_ARGOCD):8080 & \
	wait
	@echo "[INFO] Port Forwarded: Rollouts Dashboard -> $(PORT_ARGO_ROLLOUTS), Workflows UI -> $(PORT_ARGO_WORKFLOWS), ArgoCD UI -> $(PORT_ARGOCD)"

# ===================
# 🔧 기타
# ===================

clean:
	# 삭제 - fastapi 앱 관련 리소스 (default namespace)
	-kubectl delete rollout fastapi-rollout -n default || true
	-kubectl delete svc fastapi-active -n default || true
	-kubectl delete svc fastapi-preview -n default || true
	-kubectl delete pvc sqlite-pvc -n default || true
	-kubectl delete pv sqlite-pv || true

	# 삭제 - argo-rollouts 관련 리소스 (argo-rollouts namespace)
	-kubectl delete deploy argo-rollouts-controller -n argo-rollouts || true
	-kubectl delete svc argo-rollouts-server -n argo-rollouts || true
	-kubectl delete deploy argo-rollouts-dashboard -n argo-rollouts || true
	-kubectl delete svc argo-rollouts-dashboard -n argo-rollouts || true

	# argo-rollouts 네임스페이스 자체 삭제
	-kubectl delete ns argo-rollouts || true

	@echo "✅ Clean completed: fastapi rollout, services, PVC, PV, argo-rollouts controller/dashboard."

reset:
	make clean
	make deploy-all
	make deploy-dashboard
	make port-all
	@echo "[INFO] Reset and redeploy completed including dashboard installation and port forwarding."
	kubectl get pods,svc,deploy,rollout

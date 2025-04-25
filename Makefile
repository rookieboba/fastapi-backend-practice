DOCKER_COMPOSE := $(shell command -v docker-compose > /dev/null 2>&1 && echo docker-compose || echo docker compose)

# ===================
# 🧪 개발 환경
# ===================

run-dev:
	uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload -d

docker-dev:
	$(DOCKER_COMPOSE) -f docker-compose.dev.yml up --build -d

docker-down:
	${DOCKER_COMPOSE} -f docker-compose.dev.yml down

#docker-push:
#	docker build -t terrnabin/fastapi_app:v1 .
#	docker push terrnabin/fastapi_app:v1

test:
	$(DOCKER_COMPOSE) -f docker-compose.dev.yml run --rm web \
		bash -c "env PYTHONPATH=/app pytest --cov=app --cov-report=term tests/" -d

test-cov:
	$(DOCKER_COMPOSE) -f docker-compose.dev.yml run --rm web \
		bash -c "env PYTHONPATH=/app pytest --cov=app --cov-report=html tests/" -d

# ===================
# Kubernetes
# ===================

deploy:
	kubectl apply -f k8s/argo/argo-rollouts-install.yaml
	kubectl apply -k k8s/
	kubectl get all

promote:
	kubectl argo rollouts promote fastapi-rollout

dashboard:
	kubectl -n argo-rollouts port-forward deployment/argo-rollouts-dashboard 3100:3100


# ===================
# 🔧 기타
# ===================

clean:
	kubectl delete deployment,svc,cm,secret,pvc -l app=fastapi || true
	kubectl delete rollout fastapi-rollout || true
	kubectl delete -f k8s/argo/argo-rollouts-install.yaml || true
	kubectl delete -f k8s/argo/argo-workflows-install.yaml || true
	kubectl delete -f k8s/argo/argocd-install.yaml || true

reset:
	make clean
	make first-deploy
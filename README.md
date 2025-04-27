# fastapi-bluegreen-deploy

## 프로젝트 소개
> Kubernetes + Argo Rollouts 환경에서 **Blue/Green 무중단 배포** 전력을 지\ucdirect 구현하고 실습한 프로젝트입니다.

- FastAPI 기반 앱 개발하여 DockerHub에 업로드 후 Kubernetes에 배포 시도
- FastAPI 앱 배포 중 일부 문제를 걸친 후 무중단 배포 실습을 위해 nginx 공식 이미지를 활용
- DevOps 및 클라우드 네이트에 해당한 실전 경험과 문제 해결 능력 강화 목표

---

## 구성 기술

| 기술 스크 | 버전 |
|:----------|:----|
| Kubernetes | v1.30.x |
| Argo Rollouts | v1.6.5 |
| Container Runtime | containerd 1.6.32 |
| DockerHub Public Image | 활용 |

---

## 프로젝트 구성
```
fastapi-bluegreen-deploy/
├── app/                 
├── k8s/
│   ├── argo/             # Argo Rollouts 설정 파일
│   ├── config/           # ConfigMap, Secret, PVC
│   ├── hpa/              # HPA
│   ├── ingress/          # Ingress 설정
│   ├── monitoring/       # ServiceMonitor
│   ├── policy/           # NetworkPolicy
│   ├── rollout/          # Blue/Green 전력
│   └── service/          # 서비스 파일
├── manifests/
├── Dockerfile
├── docker-compose.dev.yml
├── docker-compose.prod.yml
├── Makefile
├── README.md
└── requirements.txt
```

---

## 빠른 시작 (Quick Start)

```bash
# 1. 프로젝트 다운로드
git clone <repo-url>
cd fastapi-bluegreen-deploy

# 2. FastAPI Docker 이미지 빌드 및 푸시
docker build -t terrnabin/fastapi_app:v1 .
docker push terrnabin/fastapi_app:v1

# 3. Kubernetes 리소스 배포
kubectl apply -k k8s/

# 4. Argo Rollouts 상태 확인
kubectl argo rollouts get rollout nginx-rollout

# 5. (필요 시) 수동 프로모션
kubectl argo rollouts promote nginx-rollout

# 6. nginx 버전 업데이트 (1.21 ➔ 1.25)
kubectl apply -f k8s/rollout/nginx-rollout.yaml
```

---

## Blue/Green 배포 해제 설정

**[k8s/rollout/nginx-rollout.yaml]**
```yaml
strategy:
  blueGreen:
    activeService: nginx-active
    previewService: nginx-preview
    autoPromotionEnabled: false
```

**Deployment 코드**

**[k8s/rollout/nginx-rollout.yaml]**
```yaml
containers:
  - name: nginx
    # image: nginx:1.21
    image: nginx:1.25  # 1.25로 변경하며 배포
    ports:
      - containerPort: 80
```

**Argo Rollouts 상태 조회**

![image](https://github.com/user-attachments/assets/706c4f87-be43-497f-bf7a-02b548c15164)


---

## FastAPI 개발 및 전환 경험

- FastAPI 앱 개발 → DockerHub Push → Kubernetes 배포 시도
- **CrashLoopBackOff** 이수 발생 (앱 내림 종료 문제)
- 문제 방안 및 재배포 시도했지만, 무중단 배포 실습을 위해 FastAPI 개발이 아닌,  nginx 버전 업데이트로 전환

---

## Troubleshooting 요약

| 문제 | 원인 | 해결 방법 |
|:-----|:-----|:-----------|
| Argo Rollouts 권한 부족 | ServiceAccount Role 부족 | ClusterRole/RoleBinding 수정 |
| Service Label 비일치 | track 레이블 비일치 | track: canary 수정 |
| FastAPI 앱 CrashLoopBackOff | 앱 내림 종료 문제 | nginx 공식 이미지 대체 |

---




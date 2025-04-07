# fastapi-backend-practice
FastAPI 기반 백엔드 프로젝트 연습 – RESTful API부터 JWT 인증까지 실습
PostMan 테스트 (JSON) 를 위한 개발 진행 

# clone
```bash
git clone -b main https://github.com/rookieboba/fastapi-backend-practice/
```

# 이미지 빌드 + 컨테이너 실행
```bash
cd fastapi-backend-practice/
docker build -t fastapi-demo .
docker run -d -p 8000:8000 --env-file tests/.env fastapi-demo
docker ps
docker exec -it {containerID} /bin/bash
```

# 테스트
```bash
newman run /app/tests/api-collection.postman.json -e /app/tests/dev-environment.postman.json
```

# DB 들어가기
```bash
sqlite3
```

Swagger UI

```bash
http://127.0.0.1:8000/docs
```

![image](https://github.com/user-attachments/assets/310be3a7-d31b-4f5b-b035-0e4fff50a16f)



ReDoc

```bash
http://127.0.0.1:8000/redoc
```

![image](https://github.com/user-attachments/assets/ea6ed652-64a7-425c-ba4f-9a4eadc6409a)

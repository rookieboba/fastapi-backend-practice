# fastapi-backend-practice
FastAPI 기반 백엔드 프로젝트 연습 – RESTful API부터 JWT 인증까지 실습
PostMan 테스트 (JSON) 를 위한 개발 진행 

```bash
git clone -b main https://github.com/rookieboba/fastapi-backend-practice/
```
# 실행
```bash
uvicorn app.main:app --reload
```

# 테스트
```bash
newman run tests/api-collection.postman.json -e tests/dev-environment.postman.json
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

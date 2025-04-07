# fastapi-backend-practice
FastAPI 기반의 백엔드 프로젝트
사용자(User) 정보를 SQLite에 저장하고 
CRUD 및 자동화 테스트(Newman)를 수행

```bash
git clone -b main https://github.com/rookieboba/fastapi-backend-practice/
```

# 개발 환경
```bash
# 코드 변경 시 자동 반영
docker-compose -f docker-compose.dev.yml up --build
```

# 운영 환경
```bash
docker-compose -f docker-compose.prod.yml up --build -d
```


# 테스트
```bash
docker run --rm -v $(pwd)/tests:/etc/newman postman/newman \
  run api-collection.postman.json -e dev-environment.postman.json
```

# DB 들어가기
```bash
sqlite3 /app/sqlite3/your_database_file.db

sqlite> SELECT * FROM users;
id  email              password
--  -----------------  --------
1   test1@example.com  1234    
2   test2@example.com  abcd    
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

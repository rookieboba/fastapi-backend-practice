# FastAPI 예시
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def hello():
    return {"message": "Hello FastAPI!"}

print(app.get("/"))  # FastAPI 인스턴스의 get 메서드 호출from fastapi import FastAPI
import requests

app = FastAPI()

@app.get("/")
def hello():
    return {"message": "Hello FastAPI!"}

# FastAPI 애플리케이션을 실행하는 코드
import uvicorn

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000)

# 별도의 스크립트에서 HTTP 요청을 보내는 코드
# 이 코드는 FastAPI 애플리케이션이 실행 중일 때 실행해야 합니다.
response = requests.get("http://127.0.0.1:8000/")
print(response.json())

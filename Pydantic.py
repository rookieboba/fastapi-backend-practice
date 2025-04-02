from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, EmailStr
from typing import List

app = FastAPI(title="FastAPI Demo", description="FastAPI 특장점이 담긴 예제", version="1.0.0")

# in-memory 사용자 저장소
fake_users = {}

# Pydantic 모델로 요청 유효성 검사
class User(BaseModel):
    id: int
    name: str
    email: EmailStr
    is_active: bool = True

@app.get("/", tags=["Health Check"])
async def root():
    return {"message": "FastAPI is running!"}

@app.get("/users", response_model=List[User], tags=["User"])
async def get_users():
    return list(fake_users.values())

@app.get("/users/{user_id}", response_model=User, tags=["User"])
async def get_user(user_id: int):
    if user_id not in fake_users:
        raise HTTPException(status_code=404, detail="User not found")
    return fake_users[user_id]

@app.post("/users", response_model=User, tags=["User"])
async def create_user(user: User):
    if user.id in fake_users:
        raise HTTPException(status_code=400, detail="User already exists")
    fake_users[user.id] = user
    return user

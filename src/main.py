from fastapi import FastAPI
from src.routers import payment

app = FastAPI()

app.include_router(payment.router)

@app.get("/")
def root():
    return {"message": "FastAPI Payments API"}
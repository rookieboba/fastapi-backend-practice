from pydantic import BaseModel

class PaymentCreate(BaseModel):
    amount: int
    method: str

class PaymentResponse(PaymentCreate):
    id: int
    status: str
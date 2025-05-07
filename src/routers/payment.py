from fastapi import APIRouter, HTTPException
from src.schemas.payment import PaymentCreate, PaymentResponse
from src.services.payment_service import PaymentService

router = APIRouter(prefix="/payments", tags=["Payments"])
payment_service = PaymentService()

@router.post("/", response_model=PaymentResponse, status_code=201)
def create_payment(payment: PaymentCreate):
    return payment_service.create_payment(payment)

@router.get("/{payment_id}", response_model=PaymentResponse)
def get_payment(payment_id: int):
    return payment_service.get_payment(payment_id)

@router.patch("/{payment_id}/cancel", response_model=PaymentResponse)
def cancel_payment(payment_id: int):
    return payment_service.cancel_payment(payment_id)

@router.post("/{payment_id}/approve", response_model=PaymentResponse)
def approve_payment(payment_id: int):
    return payment_service.approve_payment(payment_id)
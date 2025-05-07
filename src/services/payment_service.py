from src.schemas.payment import PaymentCreate, PaymentResponse
from fastapi import FastAPI, HTTPException

class PaymentService:
    def __init__(self):
        self._payments = {}
        self._id_counter = 1

    def create_payment(self, payment: PaymentCreate) -> PaymentResponse:
        new_payment = PaymentResponse(
            id=self._id_counter,
            amount=payment.amount,
            method=payment.method,
            status="pending"
        )
        self._payments[self._id_counter] = new_payment
        self._id_counter += 1
        return new_payment

    def get_payment(self, payment_id: int) -> PaymentResponse:
        payment = self._payments.get(payment_id)
        if not payment:
            raise HTTPException(status_code=404, detail="Payment not found")
        return payment

    def cancel_payment(self, payment_id: int) -> PaymentResponse:
        payment = self.get_payment(payment_id)
        payment.status = "cancelled"
        return payment

    def approve_payment(self, payment_id: int) -> PaymentResponse:
        payment = self.get_payment(payment_id)
        payment.status = "approved"
        return payment
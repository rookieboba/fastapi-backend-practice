from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_create_payment():
    response = client.post("/payments", json={"amount": 5000, "method": "kakaopay"})
    assert response.status_code == 201
    assert response.json()["status"] == "pending"

def test_get_payment():
    client.post("/payments", json={"amount": 3000, "method": "card"})
    response = client.get("/payments/1")
    assert response.status_code == 200
    assert response.json()["id"] == 1

def test_cancel_payment():
    client.post("/payments", json={"amount": 4000, "method": "bank"})
    response = client.patch("/payments/1/cancel")
    assert response.json()["status"] == "cancelled"

def test_approve_payment():
    client.post("/payments", json={"amount": 2000, "method": "naverpay"})
    response = client.post("/payments/1/approve")
    assert response.json()["status"] == "approved"
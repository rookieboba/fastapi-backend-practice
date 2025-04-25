from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_create_payment_returns_201_and_pending_status():
    payload = {"amount": 5000, "method": "kakaopay"}
    response = client.post("/payments", json=payload)
    
    assert response.status_code == 201, f"Expected 201, got {response.status_code}"
    data = response.json()
    assert data["status"] == "pending", f"Expected 'pending', got {data['status']}"


def test_get_payment_returns_correct_data():
    create_payload = {"amount": 3000, "method": "card"}
    create_resp = client.post("/payments", json=create_payload)
    created_id = create_resp.json()["id"]

    get_resp = client.get(f"/payments/{created_id}")
    
    assert get_resp.status_code == 200, f"Expected 200, got {get_resp.status_code}"
    data = get_resp.json()
    assert data["id"] == created_id, f"Expected id {created_id}, got {data['id']}"


def test_cancel_payment_changes_status_to_cancelled():
    create_payload = {"amount": 4000, "method": "bank"}
    create_resp = client.post("/payments", json=create_payload)
    created_id = create_resp.json()["id"]

    cancel_resp = client.patch(f"/payments/{created_id}/cancel")
    
    assert cancel_resp.status_code == 200, f"Expected 200, got {cancel_resp.status_code}"
    data = cancel_resp.json()
    assert data["status"] == "cancelled", f"Expected 'cancelled', got {data['status']}"


def test_approve_payment_changes_status_to_approved():
    create_payload = {"amount": 2000, "method": "naverpay"}
    create_resp = client.post("/payments", json=create_payload)
    created_id = create_resp.json()["id"]

    approve_resp = client.post(f"/payments/{created_id}/approve")
    
    assert approve_resp.status_code == 200, f"Expected 200, got {approve_resp.status_code}"
    data = approve_resp.json()
    assert data["status"] == "approved", f"Expected 'approved', got {data['status']}"


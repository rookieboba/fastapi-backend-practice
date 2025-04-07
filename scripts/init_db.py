# scripts/init_db.py
from app.models import User
from app.database import init_db, get_session

init_db()

# Optional: insert dummy user
from sqlmodel import Session
from app.database import engine

with Session(engine) as session:
    user = User(name="Sungbin", email="sungbin@example.com")
    session.add(user)
    session.commit()


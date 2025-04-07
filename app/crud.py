### app/crud.py
from sqlmodel import Session, select
from app.models import User


def create_user(session: Session, user: User) -> User:
    session.add(user)
    session.commit()
    session.refresh(user)
    return user


def get_users(session: Session):
    return session.exec(select(User)).all()


def get_user(session: Session, user_id: int):
    return session.get(User, user_id)


def delete_user(session: Session, user_id: int):
    user = session.get(User, user_id)
    if user:
        session.delete(user)
        session.commit()
    return user


def update_user(session: Session, user_id: int, name: str, email: str):
    user = session.get(User, user_id)
    if user:
        user.name = name
        user.email = email
        session.commit()
        session.refresh(user)
    return user
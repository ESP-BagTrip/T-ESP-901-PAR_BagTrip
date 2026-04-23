"""Middleware d'authentification JWT — dual-mode (cookie + Bearer)."""

from typing import Annotated

from fastapi import Depends, HTTPException, Request, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from sqlalchemy.orm import Session

from src.config.database import get_db
from src.config.env import settings
from src.models.user import User
from src.utils.cookies import access_cookie_name

security = HTTPBearer(auto_error=False)


def verify_jwt_token(token: str) -> str | None:
    """Vérifie un token JWT et retourne l'ID utilisateur."""
    try:
        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=["HS256"])
        token_type = payload.get("type")
        if token_type is not None and token_type != "access":
            return None
        return payload.get("userId")
    except JWTError:
        return None


async def get_current_user(
    request: Request,
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(security)] = None,
    db: Annotated[Session, Depends(get_db)] = None,  # type: ignore[assignment]
) -> User:
    """Dépendance FastAPI — lit le token depuis le cookie access_token ou le header Bearer."""
    token = None

    # 1. Cookie httpOnly (admin panel)
    cookie_token = request.cookies.get(access_cookie_name())
    if cookie_token:
        token = cookie_token

    # 2. Bearer header (mobile app)
    if not token and credentials:
        token = credentials.credentials

    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user_id = verify_jwt_token(token)
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    return user

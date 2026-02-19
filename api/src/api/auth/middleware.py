"""Middleware d'authentification JWT."""

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from sqlalchemy.orm import Session

from src.config.database import get_db
from src.config.env import settings
from src.models.user import User

security = HTTPBearer(auto_error=True)


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
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db),
) -> User:
    """Dépendance FastAPI pour obtenir l'utilisateur actuel depuis le token JWT."""
    token = credentials.credentials

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

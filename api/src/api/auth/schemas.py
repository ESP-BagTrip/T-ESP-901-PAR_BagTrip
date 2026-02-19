"""Schémas Pydantic pour l'authentification."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field


class SignupRequest(BaseModel):
    """Requête d'inscription selon PLAN.md."""

    email: EmailStr
    password: str = Field(..., min_length=6)
    fullName: str | None = None
    phone: str | None = None


class LoginRequest(BaseModel):
    """Requête de connexion."""

    email: EmailStr
    password: str


class UserResponse(BaseModel):
    """Réponse utilisateur."""

    id: UUID
    email: str
    created_at: datetime = Field(..., alias="createdAt")
    updated_at: datetime | None = Field(None, alias="updatedAt")

    class Config:
        from_attributes = True
        populate_by_name = True


class GoogleSignInRequest(BaseModel):
    """Requête de connexion avec Google."""

    idToken: str = Field(..., description="Google ID token")


class AppleSignInRequest(BaseModel):
    """Requête de connexion avec Apple."""

    idToken: str = Field(..., description="Apple ID token")


class AuthResponse(BaseModel):
    """Réponse d'authentification avec access + refresh tokens."""

    access_token: str
    refresh_token: str
    expires_in: int
    token_type: str = "Bearer"
    user: UserResponse


class RefreshTokenRequest(BaseModel):
    """Requête de rafraîchissement de token."""

    refresh_token: str


class LogoutRequest(BaseModel):
    """Requête de déconnexion."""

    refresh_token: str

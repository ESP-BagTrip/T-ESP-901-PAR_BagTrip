"""Schémas Pydantic pour l'authentification."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from src.api.common.base_schema import BagtripRequestModel


class SignupRequest(BagtripRequestModel):
    """Requête d'inscription selon PLAN.md."""

    email: EmailStr
    password: str = Field(..., min_length=6)
    fullName: str | None = None
    phone: str | None = None


class LoginRequest(BagtripRequestModel):
    """Requête de connexion."""

    email: EmailStr
    password: str


class UserResponse(BaseModel):
    """Réponse utilisateur."""

    id: UUID
    email: str
    full_name: str | None = Field(None, alias="fullName")
    phone: str | None = Field(None, alias="phone")
    created_at: datetime = Field(..., alias="createdAt")
    updated_at: datetime | None = Field(None, alias="updatedAt")
    is_profile_completed: bool = Field(False, alias="isProfileCompleted")
    plan: str = Field("FREE")
    ai_generations_remaining: int | None = Field(None, alias="aiGenerationsRemaining")
    plan_expires_at: datetime | None = Field(None, alias="planExpiresAt")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class UpdateUserRequest(BagtripRequestModel):
    """Requête de mise à jour du profil utilisateur."""

    fullName: str | None = None
    phone: str | None = None


class GoogleSignInRequest(BagtripRequestModel):
    """Requête de connexion avec Google."""

    idToken: str = Field(..., description="Google ID token")


class AppleSignInRequest(BagtripRequestModel):
    """Requête de connexion avec Apple."""

    idToken: str = Field(..., description="Apple ID token")


class AuthResponse(BaseModel):
    """Réponse d'authentification avec access + refresh tokens."""

    access_token: str
    refresh_token: str
    expires_in: int
    token_type: str = "Bearer"
    user: UserResponse


class RefreshTokenRequest(BagtripRequestModel):
    """Requête de rafraîchissement de token."""

    refresh_token: str


class LogoutRequest(BagtripRequestModel):
    """Requête de déconnexion."""

    refresh_token: str | None = None


class ForgotPasswordRequest(BagtripRequestModel):
    """Requête de réinitialisation de mot de passe."""

    email: EmailStr


class ResetPasswordRequest(BagtripRequestModel):
    """Requête de changement de mot de passe via token."""

    token: str
    new_password: str = Field(..., min_length=6)

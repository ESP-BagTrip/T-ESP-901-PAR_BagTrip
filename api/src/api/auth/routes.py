"""Routes d'authentification."""

import os
from datetime import datetime, timedelta

import bcrypt
from fastapi import APIRouter, Depends, HTTPException, status
from jose import jwt
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from src.api.auth.middleware import get_current_user
from src.api.auth.schemas import AuthResponse, LoginRequest, SignupRequest, UserResponse
from src.config.database import get_db
from src.models.user import User

router = APIRouter(prefix="/v1/auth", tags=["Auth"])

JWT_SECRET = os.getenv("JWT_SECRET", "your-secret-key")
JWT_EXPIRATION = "365d"  # Expiration "abusée" comme demandé


def create_jwt_token(user_id: str) -> str:
    """Crée un token JWT."""
    # Calculer l'expiration (365 jours)
    expire = datetime.utcnow() + timedelta(days=365)
    payload = {"userId": str(user_id), "exp": expire}
    return jwt.encode(payload, JWT_SECRET, algorithm="HS256")


@router.post(
    "/register",
    response_model=AuthResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new user",
    description="Create a new user account and receive a JWT token",
    responses={
        201: {
            "description": "User created successfully",
            "content": {
                "application/json": {
                    "example": {
                        "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                        "user": {
                            "id": "550e8400-e29b-41d4-a716-446655440000",
                            "email": "user@example.com",
                            "createdAt": "2025-12-11T14:24:32Z",
                            "updatedAt": None,
                        },
                    }
                }
            },
        },
        400: {"description": "Bad request - User already exists or validation error"},
    },
)
async def register(request: SignupRequest, db: Session = Depends(get_db)):
    """
    Register - Créer un nouvel utilisateur selon PLAN.md.

    - **email**: Email de l'utilisateur (doit être unique)
    - **password**: Mot de passe (minimum 6 caractères)

    Retourne un token JWT valide pendant 365 jours.
    """
    # Vérifier si l'utilisateur existe déjà
    existing_user = db.query(User).filter(User.email == request.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User already exists",
        )

    # Hasher le mot de passe
    hashed_password = bcrypt.hashpw(request.password.encode("utf-8"), bcrypt.gensalt()).decode(
        "utf-8"
    )

    # Créer l'utilisateur
    try:
        user = User(
            email=request.email,
            password_hash=hashed_password,
            full_name=getattr(request, "fullName", None),
            phone=getattr(request, "phone", None),
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User already exists",
        ) from None

    # Générer le token JWT
    token = create_jwt_token(str(user.id))

    return AuthResponse(
        token=token,
        user=UserResponse(
            id=user.id,
            email=user.email,
            created_at=user.created_at,
            updated_at=user.updated_at,
        ),
    )


@router.post(
    "/login",
    response_model=AuthResponse,
    summary="Authenticate user and get JWT token",
    description="Login with email and password to receive a JWT token",
    responses={
        200: {
            "description": "Login successful",
            "content": {
                "application/json": {
                    "example": {
                        "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                        "user": {
                            "id": "550e8400-e29b-41d4-a716-446655440000",
                            "email": "user@example.com",
                            "createdAt": "2025-12-11T14:24:32Z",
                            "updatedAt": None,
                        },
                    }
                }
            },
        },
        401: {"description": "Unauthorized - Invalid credentials"},
    },
)
async def login(request: LoginRequest, db: Session = Depends(get_db)):
    """
    Login - Authentifier un utilisateur.

    - **email**: Email de l'utilisateur
    - **password**: Mot de passe

    Retourne un token JWT valide pendant 365 jours.
    """
    # Trouver l'utilisateur
    user = db.query(User).filter(User.email == request.email).first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials",
        )

    # Vérifier le mot de passe
    is_valid_password = bcrypt.checkpw(
        request.password.encode("utf-8"),
        user.password_hash.encode("utf-8"),
    )

    if not is_valid_password:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials",
        )

    # Générer le token JWT
    token = create_jwt_token(str(user.id))

    return AuthResponse(
        token=token,
        user=UserResponse(
            id=user.id,
            email=user.email,
            created_at=user.created_at,
            updated_at=user.updated_at,
        ),
    )


@router.get(
    "/me",
    response_model=UserResponse,
    summary="Get current authenticated user information",
    description="Retrieve information about the currently authenticated user",
    responses={
        200: {
            "description": "User information retrieved successfully",
            "content": {
                "application/json": {
                    "example": {
                        "id": "550e8400-e29b-41d4-a716-446655440000",
                        "email": "user@example.com",
                        "createdAt": "2025-12-11T14:24:32Z",
                        "updatedAt": "2025-12-11T14:24:32Z",
                    }
                }
            },
        },
        401: {"description": "Unauthorized - No token or invalid token"},
        404: {"description": "User not found"},
    },
)
async def me(current_user: User = Depends(get_current_user)):
    """
    Me - Obtenir les informations de l'utilisateur actuel.

    Requiert un token JWT valide dans le header Authorization.
    """
    return UserResponse(
        id=current_user.id,
        email=current_user.email,
        created_at=current_user.created_at,
        updated_at=current_user.updated_at,
    )

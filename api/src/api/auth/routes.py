"""Routes d'authentification."""

import os
from datetime import datetime, timedelta

import bcrypt
from fastapi import APIRouter, Depends, HTTPException, status
from jose import jwt
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from src.api.auth.middleware import get_current_user
from src.api.auth.schemas import (
    AppleSignInRequest,
    AuthResponse,
    GoogleSignInRequest,
    LoginRequest,
    SignupRequest,
    UserResponse,
)
from src.config.database import get_db
from src.integrations.stripe.client import StripeClient
from src.models.user import User
from src.utils.logger import logger

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
        db.flush()  # Flush to get user.id without committing

        # Créer un client Stripe
        try:
            stripe_customer = StripeClient.create_customer(
                email=request.email,
                name=getattr(request, "fullName", None),
            )
            user.stripe_customer_id = stripe_customer.id
            logger.info(f"Created Stripe customer {stripe_customer.id} for user {user.id}")
        except Exception as e:
            # Log l'erreur mais continue la création de l'utilisateur
            logger.warning(
                f"Failed to create Stripe customer for user {user.id}: {e}",
                exc_info=True,
            )

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


@router.post(
    "/google",
    response_model=AuthResponse,
    summary="Authenticate with Google",
    description="Login or register with Google ID token",
    responses={
        200: {
            "description": "Authentication successful",
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
        401: {"description": "Unauthorized - Invalid Google token"},
    },
)
async def google_sign_in(
    request: GoogleSignInRequest, db: Session = Depends(get_db)
):
    """
    Google Sign In - Authentifier un utilisateur avec Google.

    - **idToken**: Token ID Google

    Crée un utilisateur s'il n'existe pas, sinon retourne l'utilisateur existant.
    Retourne un token JWT valide pendant 365 jours.
    """
    try:
        # Décoder le token Google (sans vérification complète pour MVP)
        # En production, il faudrait vérifier le token avec les clés publiques Google
        # Utiliser get_unverified_claims pour éviter les vérifications (at_hash, etc.)
        decoded_token = jwt.get_unverified_claims(request.idToken)

        email = decoded_token.get("email")
        if not email:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid Google token: email not found",
            )

        name = decoded_token.get("name")
        given_name = decoded_token.get("given_name")
        family_name = decoded_token.get("family_name")
        full_name = name or (
            f"{given_name} {family_name}".strip() if given_name or family_name else None
        )

        # Chercher ou créer l'utilisateur
        user = db.query(User).filter(User.email == email).first()

        if not user:
            # Créer un nouvel utilisateur
            # Pour les utilisateurs sociaux, on utilise un hash de mot de passe factice
            # car ils n'utiliseront jamais l'authentification par mot de passe
            dummy_password = os.urandom(32).hex()
            hashed_password = bcrypt.hashpw(
                dummy_password.encode("utf-8"), bcrypt.gensalt()
            ).decode("utf-8")

            user = User(
                email=email,
                password_hash=hashed_password,
                full_name=full_name,
            )
            db.add(user)
            db.flush()

            # Créer un client Stripe
            try:
                stripe_customer = StripeClient.create_customer(
                    email=email,
                    name=full_name,
                )
                user.stripe_customer_id = stripe_customer.id
                logger.info(
                    f"Created Stripe customer {stripe_customer.id} for user {user.id}"
                )
            except Exception as e:
                logger.warning(
                    f"Failed to create Stripe customer for user {user.id}: {e}",
                    exc_info=True,
                )

            db.commit()
            db.refresh(user)
        else:
            # Mettre à jour le nom si nécessaire
            if full_name and not user.full_name:
                user.full_name = full_name
                db.commit()
                db.refresh(user)

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
    except jwt.JWTError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid Google token: {str(e)}",
        ) from None
    except Exception as e:
        logger.error(f"Error during Google sign in: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error during Google authentication",
        ) from None


@router.post(
    "/apple",
    response_model=AuthResponse,
    summary="Authenticate with Apple",
    description="Login or register with Apple ID token",
    responses={
        200: {
            "description": "Authentication successful",
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
        401: {"description": "Unauthorized - Invalid Apple token"},
    },
)
async def apple_sign_in(request: AppleSignInRequest, db: Session = Depends(get_db)):
    """
    Apple Sign In - Authentifier un utilisateur avec Apple.

    - **idToken**: Token ID Apple

    Crée un utilisateur s'il n'existe pas, sinon retourne l'utilisateur existant.
    Retourne un token JWT valide pendant 365 jours.
    """
    try:
        # Vérifier que le token n'est pas vide
        if not request.idToken or not request.idToken.strip():
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid Apple token: token is empty",
            )

        # Décoder le token Apple (sans vérification complète pour MVP)
        # En production, il faudrait vérifier le token avec les clés publiques Apple
        # Utiliser get_unverified_claims pour éviter les vérifications
        try:
            decoded_token = jwt.get_unverified_claims(request.idToken)
        except jwt.JWTError as jwt_error:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=f"Invalid Apple token: {str(jwt_error)}",
            ) from None

        # Apple peut ne pas fournir l'email si l'utilisateur a choisi de le masquer
        # Dans ce cas, on utilise le subject (sub) comme identifiant
        email = decoded_token.get("email")
        subject = decoded_token.get("sub")

        if not email and not subject:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid Apple token: no email or subject found",
            )

        # Si pas d'email, on génère un email basé sur le subject
        if not email:
            email = f"{subject}@privaterelay.appleid.com"

        # Chercher ou créer l'utilisateur
        user = db.query(User).filter(User.email == email).first()

        if not user:
            # Créer un nouvel utilisateur
            # Pour les utilisateurs sociaux, on utilise un hash de mot de passe factice
            dummy_password = os.urandom(32).hex()
            hashed_password = bcrypt.hashpw(
                dummy_password.encode("utf-8"), bcrypt.gensalt()
            ).decode("utf-8")

            user = User(
                email=email,
                password_hash=hashed_password,
            )
            db.add(user)
            db.flush()

            # Créer un client Stripe
            try:
                stripe_customer = StripeClient.create_customer(
                    email=email,
                    name=None,
                )
                user.stripe_customer_id = stripe_customer.id
                logger.info(
                    f"Created Stripe customer {stripe_customer.id} for user {user.id}"
                )
            except Exception as e:
                logger.warning(
                    f"Failed to create Stripe customer for user {user.id}: {e}",
                    exc_info=True,
                )

            db.commit()
            db.refresh(user)

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
    except jwt.JWTError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid Apple token: {str(e)}",
        ) from None
    except Exception as e:
        logger.error(f"Error during Apple sign in: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error during Apple authentication",
        ) from None

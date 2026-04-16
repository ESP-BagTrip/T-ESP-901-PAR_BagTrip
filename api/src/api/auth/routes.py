"""Routes d'authentification."""

import os
import secrets
from datetime import timezone, datetime, timedelta

import bcrypt
from fastapi import APIRouter, Depends, HTTPException, Request, Response, status
from jose import jwt
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from src.api.auth.apple_token_verifier import verify_apple_id_token
from src.api.auth.google_token_verifier import verify_google_id_token
from src.api.auth.middleware import get_current_user
from src.api.auth.schemas import (
    AppleSignInRequest,
    AuthResponse,
    ForgotPasswordRequest,
    GoogleSignInRequest,
    LoginRequest,
    LogoutRequest,
    RefreshTokenRequest,
    ResetPasswordRequest,
    SignupRequest,
    UpdateUserRequest,
    UserResponse,
)
from src.config.database import get_db
from src.config.env import settings
from src.integrations.stripe.client import StripeClient
from src.models.refresh_token import RefreshToken
from src.models.user import User
from src.services.plan_service import PlanService
from src.utils.cookies import clear_auth_cookies, set_auth_cookies
from src.utils.errors import AppError
from src.utils.logger import logger

router = APIRouter(prefix="/v1/auth", tags=["Auth"])


def create_access_token(user_id: str) -> tuple[str, int]:
    """Create an access token. Returns (token, expires_in_seconds)."""
    expires_in = settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES * 60
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES)
    payload = {"userId": str(user_id), "exp": expire, "type": "access"}
    token = jwt.encode(payload, settings.JWT_SECRET, algorithm="HS256")
    return token, expires_in


def create_refresh_token(user_id: str, db: Session) -> str:
    """Create a refresh token, store in DB, return the raw token."""
    raw_token = secrets.token_urlsafe(64)
    expires_at = datetime.now(timezone.utc) + timedelta(days=settings.JWT_REFRESH_TOKEN_EXPIRE_DAYS)
    refresh = RefreshToken(
        user_id=user_id,
        token=raw_token,
        expires_at=expires_at,
    )
    db.add(refresh)
    return raw_token


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
async def register(request: SignupRequest, response: Response, db: Session = Depends(get_db)):
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
            logger.error(
                f"Failed to create Stripe customer for user {user.id}: {e}",
                exc_info=True,
            )
            db.rollback()
            raise AppError(
                "STRIPE_CUSTOMER_CREATION_FAILED",
                503,
                "Failed to create payment profile. Please try again.",
            ) from e

        db.commit()
        db.refresh(user)

        # Claim pending invites for newly registered user
        try:
            from src.services.trip_share_service import TripShareService

            TripShareService.claim_pending_invites(db, email=user.email, user_id=user.id)
        except Exception:
            pass  # Best-effort, don't block registration

    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User already exists",
        ) from None

    # Generate tokens
    access_token, expires_in = create_access_token(str(user.id))
    refresh_token = create_refresh_token(str(user.id), db)
    db.commit()

    set_auth_cookies(response, access_token, refresh_token, expires_in)

    plan_info = PlanService.get_plan_info(db, user)
    return AuthResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=expires_in,
        user=UserResponse(
            id=user.id,
            email=user.email,
            full_name=user.full_name,
            phone=user.phone,
            created_at=user.created_at,
            updated_at=user.updated_at,
            plan=user.plan or "FREE",
            ai_generations_remaining=plan_info["ai_generations_remaining"],
            plan_expires_at=user.plan_expires_at,
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
async def login(request: LoginRequest, response: Response, db: Session = Depends(get_db)):
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

    # Generate tokens
    access_token, expires_in = create_access_token(str(user.id))
    refresh_token = create_refresh_token(str(user.id), db)
    db.commit()

    set_auth_cookies(response, access_token, refresh_token, expires_in)

    plan_info = PlanService.get_plan_info(db, user)
    return AuthResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=expires_in,
        user=UserResponse(
            id=user.id,
            email=user.email,
            full_name=user.full_name,
            phone=user.phone,
            created_at=user.created_at,
            updated_at=user.updated_at,
            plan=user.plan or "FREE",
            ai_generations_remaining=plan_info["ai_generations_remaining"],
            plan_expires_at=user.plan_expires_at,
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
async def me(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Me - Obtenir les informations de l'utilisateur actuel.

    Requiert un token JWT valide dans le header Authorization.
    """
    from src.services.profile_service import ProfileService

    is_completed, _ = ProfileService.check_completion(db, current_user.id)
    plan_info = PlanService.get_plan_info(db, current_user)
    return UserResponse(
        id=current_user.id,
        email=current_user.email,
        full_name=current_user.full_name,
        phone=current_user.phone,
        created_at=current_user.created_at,
        updated_at=current_user.updated_at,
        is_profile_completed=is_completed,
        plan=current_user.plan or "FREE",
        ai_generations_remaining=plan_info["ai_generations_remaining"],
        plan_expires_at=current_user.plan_expires_at,
    )


@router.patch(
    "/me",
    response_model=UserResponse,
    summary="Update current user profile",
    description="Update the authenticated user's name and/or phone",
)
async def update_me(
    request: UpdateUserRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update the current user's profile (name, phone)."""
    if request.fullName is not None:
        current_user.full_name = request.fullName
    if request.phone is not None:
        current_user.phone = request.phone

    current_user.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(current_user)

    from src.services.profile_service import ProfileService

    is_completed, _ = ProfileService.check_completion(db, current_user.id)
    plan_info = PlanService.get_plan_info(db, current_user)
    return UserResponse(
        id=current_user.id,
        email=current_user.email,
        full_name=current_user.full_name,
        phone=current_user.phone,
        created_at=current_user.created_at,
        updated_at=current_user.updated_at,
        is_profile_completed=is_completed,
        plan=current_user.plan or "FREE",
        ai_generations_remaining=plan_info["ai_generations_remaining"],
        plan_expires_at=current_user.plan_expires_at,
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
    request: GoogleSignInRequest, response: Response, db: Session = Depends(get_db)
):
    """
    Google Sign In - Authentifier un utilisateur avec Google.

    - **idToken**: Token ID Google

    Crée un utilisateur s'il n'existe pas, sinon retourne l'utilisateur existant.
    Retourne un token JWT valide pendant 365 jours.
    """
    try:
        decoded_token = await verify_google_id_token(request.idToken)

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
                logger.info(f"Created Stripe customer {stripe_customer.id} for user {user.id}")
            except Exception as e:
                logger.error(
                    f"Failed to create Stripe customer for user {user.id}: {e}",
                    exc_info=True,
                )
                db.rollback()
                raise AppError(
                    "STRIPE_CUSTOMER_CREATION_FAILED",
                    503,
                    "Failed to create payment profile. Please try again.",
                ) from e

            db.commit()
            db.refresh(user)

            # Claim pending invites for newly registered user
            try:
                from src.services.trip_share_service import TripShareService

                TripShareService.claim_pending_invites(db, email=user.email, user_id=user.id)
            except Exception:
                pass  # Best-effort
        else:
            # Mettre à jour le nom si nécessaire
            if full_name and not user.full_name:
                user.full_name = full_name
                db.commit()
                db.refresh(user)

        # Generate tokens
        access_token, expires_in = create_access_token(str(user.id))
        refresh_token = create_refresh_token(str(user.id), db)
        db.commit()

        set_auth_cookies(response, access_token, refresh_token, expires_in)

        plan_info = PlanService.get_plan_info(db, user)
        return AuthResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            expires_in=expires_in,
            user=UserResponse(
                id=user.id,
                email=user.email,
                full_name=user.full_name,
                phone=user.phone,
                created_at=user.created_at,
                updated_at=user.updated_at,
                plan=user.plan or "FREE",
                ai_generations_remaining=plan_info["ai_generations_remaining"],
                plan_expires_at=user.plan_expires_at,
            ),
        )
    except AppError:
        raise
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
async def apple_sign_in(
    request: AppleSignInRequest, response: Response, db: Session = Depends(get_db)
):
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

        try:
            decoded_token = await verify_apple_id_token(request.idToken)
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
                logger.info(f"Created Stripe customer {stripe_customer.id} for user {user.id}")
            except Exception as e:
                logger.error(
                    f"Failed to create Stripe customer for user {user.id}: {e}",
                    exc_info=True,
                )
                db.rollback()
                raise AppError(
                    "STRIPE_CUSTOMER_CREATION_FAILED",
                    503,
                    "Failed to create payment profile. Please try again.",
                ) from e

            db.commit()
            db.refresh(user)

            # Claim pending invites for newly registered user
            try:
                from src.services.trip_share_service import TripShareService

                TripShareService.claim_pending_invites(db, email=user.email, user_id=user.id)
            except Exception:
                pass  # Best-effort

        # Generate tokens
        access_token, expires_in = create_access_token(str(user.id))
        refresh_token = create_refresh_token(str(user.id), db)
        db.commit()

        set_auth_cookies(response, access_token, refresh_token, expires_in)

        plan_info = PlanService.get_plan_info(db, user)
        return AuthResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            expires_in=expires_in,
            user=UserResponse(
                id=user.id,
                email=user.email,
                full_name=user.full_name,
                phone=user.phone,
                created_at=user.created_at,
                updated_at=user.updated_at,
                plan=user.plan or "FREE",
                ai_generations_remaining=plan_info["ai_generations_remaining"],
                plan_expires_at=user.plan_expires_at,
            ),
        )
    except AppError:
        raise
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


@router.post(
    "/refresh",
    response_model=AuthResponse,
    summary="Refresh access token",
    description="Exchange a valid refresh token for a new access + refresh token pair",
)
async def refresh(request: RefreshTokenRequest, response: Response, db: Session = Depends(get_db)):
    """Refresh — rotate tokens."""
    stored = (
        db.query(RefreshToken)
        .filter(
            RefreshToken.token == request.refresh_token,
            RefreshToken.revoked.is_(False),
        )
        .first()
    )

    if not stored or stored.expires_at < datetime.now(timezone.utc):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token",
        )

    # Revoke old token (rotation)
    stored.revoked = True

    user = db.query(User).filter(User.id == stored.user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
        )

    access_token, expires_in = create_access_token(str(user.id))
    new_refresh = create_refresh_token(str(user.id), db)
    db.commit()

    set_auth_cookies(response, access_token, new_refresh, expires_in)

    plan_info = PlanService.get_plan_info(db, user)
    return AuthResponse(
        access_token=access_token,
        refresh_token=new_refresh,
        expires_in=expires_in,
        user=UserResponse(
            id=user.id,
            email=user.email,
            full_name=user.full_name,
            phone=user.phone,
            created_at=user.created_at,
            updated_at=user.updated_at,
            plan=user.plan or "FREE",
            ai_generations_remaining=plan_info["ai_generations_remaining"],
            plan_expires_at=user.plan_expires_at,
        ),
    )


@router.post(
    "/logout",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Logout — revoke a refresh token",
)
async def logout(
    http_request: Request,
    response: Response,
    request: LogoutRequest | None = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Logout — revoke the given refresh token (from body or cookie)."""
    token_value = None
    if request and request.refresh_token:
        token_value = request.refresh_token
    else:
        token_value = http_request.cookies.get("refresh_token")

    if token_value:
        stored = (
            db.query(RefreshToken)
            .filter(
                RefreshToken.token == token_value,
                RefreshToken.user_id == current_user.id,
                RefreshToken.revoked.is_(False),
            )
            .first()
        )
        if stored:
            stored.revoked = True
            db.commit()

    clear_auth_cookies(response)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post(
    "/logout-all",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Logout all — revoke all refresh tokens for the user",
)
async def logout_all(
    response: Response,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Logout all — revoke every refresh token for the authenticated user."""
    db.query(RefreshToken).filter(
        RefreshToken.user_id == current_user.id,
        RefreshToken.revoked.is_(False),
    ).update({"revoked": True})
    db.commit()

    clear_auth_cookies(response)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post(
    "/forgot-password",
    summary="Request a password reset",
    description="Send a password reset token (POC: token is logged server-side)",
)
async def forgot_password(request: ForgotPasswordRequest, db: Session = Depends(get_db)):
    """Request password reset — always returns 200 to avoid leaking user existence."""
    user = db.query(User).filter(User.email == request.email).first()
    if user:
        token = secrets.token_urlsafe(32)
        user.password_reset_token = token
        user.password_reset_expires = datetime.now(timezone.utc) + timedelta(hours=1)
        db.commit()
        logger.info(f"[POC] Password reset token for {request.email}: {token}")
    return {"message": "If this email exists, a reset link has been sent."}


@router.post(
    "/reset-password",
    summary="Reset password with token",
    description="Reset the password using a valid reset token",
)
async def reset_password(request: ResetPasswordRequest, db: Session = Depends(get_db)):
    """Reset password using a valid, non-expired token."""
    user = (
        db.query(User)
        .filter(
            User.password_reset_token == request.token,
            User.password_reset_expires > datetime.now(timezone.utc),
        )
        .first()
    )
    if not user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired reset token",
        )
    user.password_hash = bcrypt.hashpw(
        request.new_password.encode("utf-8"), bcrypt.gensalt()
    ).decode("utf-8")
    user.password_reset_token = None
    user.password_reset_expires = None
    db.commit()
    return {"message": "Password updated successfully."}


@router.delete(
    "/me",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete account (RGPD)",
    description="Permanently delete the user account and all associated data",
)
async def delete_me(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Hard-delete user, cascade all related data, and remove Stripe customer."""
    from src.models.accommodation import Accommodation
    from src.models.activity import Activity
    from src.models.baggage_item import BaggageItem
    from src.models.booking_intent import BookingIntent
    from src.models.budget_item import BudgetItem
    from src.models.device_token import DeviceToken
    from src.models.feedback import Feedback
    from src.models.flight_offer import FlightOffer
    from src.models.flight_order import FlightOrder
    from src.models.flight_search import FlightSearch
    from src.models.manual_flight import ManualFlight
    from src.models.notification import Notification
    from src.models.traveler import TripTraveler
    from src.models.traveler_profile import TravelerProfile
    from src.models.trip import Trip
    from src.models.trip_share import TripShare

    user_id = current_user.id

    # 1. Delete Stripe customer (best-effort)
    if current_user.stripe_customer_id:
        try:
            StripeClient.delete_customer(current_user.stripe_customer_id)
        except Exception as e:
            logger.error(f"Failed to delete Stripe customer: {e}")

    # 2. Delete user-owned trips and their children
    trip_ids = [t.id for t in db.query(Trip.id).filter(Trip.user_id == user_id).all()]
    if trip_ids:
        for model in [
            Activity,
            Accommodation,
            BaggageItem,
            BudgetItem,
            FlightSearch,
            FlightOffer,
            FlightOrder,
            ManualFlight,
            TripTraveler,
            TripShare,
            Feedback,
            BookingIntent,
            Notification,
        ]:
            db.query(model).filter(model.trip_id.in_(trip_ids)).delete(synchronize_session=False)
        db.query(Trip).filter(Trip.id.in_(trip_ids)).delete(synchronize_session=False)

    # 3. Delete direct user children
    db.query(BookingIntent).filter(BookingIntent.user_id == user_id).delete(
        synchronize_session=False
    )
    db.query(DeviceToken).filter(DeviceToken.user_id == user_id).delete(synchronize_session=False)
    db.query(Notification).filter(Notification.user_id == user_id).delete(synchronize_session=False)
    db.query(RefreshToken).filter(RefreshToken.user_id == user_id).delete(synchronize_session=False)
    db.query(TripShare).filter(TripShare.user_id == user_id).delete(synchronize_session=False)
    db.query(Feedback).filter(Feedback.user_id == user_id).delete(synchronize_session=False)
    db.query(TravelerProfile).filter(TravelerProfile.user_id == user_id).delete(
        synchronize_session=False
    )

    # 4. Delete user
    db.delete(current_user)
    db.commit()

    return Response(status_code=status.HTTP_204_NO_CONTENT)

"""Routes d'authentification."""

import hashlib
import os
import secrets
from datetime import UTC, datetime, timedelta
from typing import Annotated, Any

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
from src.models.refresh_token import RefreshToken
from src.models.user import User
from src.services.plan_service import PlanService
from src.services.stripe_gateway_service import StripeGatewayService
from src.services.user_creation_service import UserCreationService
from src.utils.cookies import (
    clear_auth_cookies,
    refresh_cookie_name,
    set_auth_cookies,
)
from src.utils.errors import AppError
from src.utils.logger import logger

router = APIRouter(prefix="/v1/auth", tags=["Auth"])


def _hash_reset_token(token: str) -> str:
    """SHA-256 hash of a password reset token — only the hash is persisted."""
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def _dummy_password_hash() -> str:
    """Random bcrypt hash for social-login users who will never sign in via password."""
    dummy = os.urandom(32).hex()
    return bcrypt.hashpw(dummy.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def _build_auth_response(
    db: Session,
    user: User,
    response: Response,
) -> AuthResponse:
    """Generate access + refresh tokens, set cookies, return the auth payload.

    Factored out so login / register / Google / Apple / refresh all build the
    response the same way — especially the `plan_info` lookup which used to
    drift (missing keys, wrong defaults) between flows.
    """
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


def create_access_token(user_id: str) -> tuple[str, int]:
    """Create an access token. Returns (token, expires_in_seconds)."""
    expires_in = settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES * 60
    expire = datetime.now(UTC) + timedelta(minutes=settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES)
    payload = {"userId": str(user_id), "exp": expire, "type": "access"}
    token = jwt.encode(payload, settings.JWT_SECRET, algorithm="HS256")
    return token, expires_in


def create_refresh_token(user_id: str, db: Session) -> str:
    """Create a refresh token, store in DB, return the raw token."""
    raw_token = secrets.token_urlsafe(64)
    expires_at = datetime.now(UTC) + timedelta(days=settings.JWT_REFRESH_TOKEN_EXPIRE_DAYS)
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
async def register(
    request: SignupRequest,
    response: Response,
    db: Annotated[Session, Depends(get_db)],
):
    """Register — create a new user with email + password."""
    existing_user = db.query(User).filter(User.email == request.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User already exists",
        )

    hashed_password = bcrypt.hashpw(request.password.encode("utf-8"), bcrypt.gensalt()).decode(
        "utf-8"
    )

    try:
        user = UserCreationService.create_and_setup_user(
            db,
            email=request.email,
            password_hash=hashed_password,
            full_name=getattr(request, "fullName", None),
            phone=getattr(request, "phone", None),
        )
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User already exists",
        ) from None

    return _build_auth_response(db, user, response)


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
async def login(
    request: LoginRequest,
    response: Response,
    db: Annotated[Session, Depends(get_db)],
):
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
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
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
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    """Update the current user's profile (name, phone)."""
    if request.fullName is not None:
        current_user.full_name = request.fullName
    if request.phone is not None:
        current_user.phone = request.phone

    current_user.updated_at = datetime.now(UTC)
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
    request: GoogleSignInRequest,
    response: Response,
    db: Annotated[Session, Depends(get_db)],
):
    """Google Sign In — create or retrieve the user from a Google ID token."""
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

        user = db.query(User).filter(User.email == email).first()
        if not user:
            user = UserCreationService.create_and_setup_user(
                db,
                email=email,
                password_hash=_dummy_password_hash(),
                full_name=full_name,
            )
        elif full_name and not user.full_name:
            user.full_name = full_name
            db.commit()
            db.refresh(user)

        return _build_auth_response(db, user, response)
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
    request: AppleSignInRequest,
    response: Response,
    db: Annotated[Session, Depends(get_db)],
):
    """Apple Sign In — create or retrieve the user from an Apple ID token."""
    try:
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

        # Apple may withhold the email if the user chose "Hide my email" — in that
        # case we fall back to the token subject to synthesize a stable identifier.
        email = decoded_token.get("email")
        subject = decoded_token.get("sub")
        if not email and not subject:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid Apple token: no email or subject found",
            )
        if not email:
            email = f"{subject}@privaterelay.appleid.com"

        user = db.query(User).filter(User.email == email).first()
        if not user:
            user = UserCreationService.create_and_setup_user(
                db,
                email=email,
                password_hash=_dummy_password_hash(),
            )

        return _build_auth_response(db, user, response)
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
async def refresh(
    request: RefreshTokenRequest,
    response: Response,
    db: Annotated[Session, Depends(get_db)],
):
    """Refresh — rotate tokens."""
    stored = (
        db.query(RefreshToken)
        .filter(
            RefreshToken.token == request.refresh_token,
            RefreshToken.revoked.is_(False),
        )
        .first()
    )

    if not stored or stored.expires_at < datetime.now(UTC):
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
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    request: LogoutRequest | None = None,
):
    """Logout — revoke the given refresh token (from body or cookie)."""
    token_value = None
    if request and request.refresh_token:
        token_value = request.refresh_token
    else:
        token_value = http_request.cookies.get(refresh_cookie_name())

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
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
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
    description="Send a password reset token (delivered out-of-band, never logged)",
)
async def forgot_password(
    request: ForgotPasswordRequest,
    db: Annotated[Session, Depends(get_db)],
):
    """Request password reset — always returns 200 to avoid leaking user existence."""
    user = db.query(User).filter(User.email == request.email).first()
    response_body: dict = {"message": "If this email exists, a reset link has been sent."}
    if user:
        raw_token = secrets.token_urlsafe(32)
        user.password_reset_token = _hash_reset_token(raw_token)
        user.password_reset_expires = datetime.now(UTC) + timedelta(hours=1)
        db.commit()
        # Dev-only escape hatch: no mail service yet, so expose the raw token in the
        # response when running outside production. Never log it, never persist it raw.
        if settings.NODE_ENV != "production":
            response_body["debug_reset_token"] = raw_token
    return response_body


@router.post(
    "/reset-password",
    summary="Reset password with token",
    description="Reset the password using a valid reset token",
)
async def reset_password(
    request: ResetPasswordRequest,
    db: Annotated[Session, Depends(get_db)],
):
    """Reset password using a valid, non-expired token."""
    token_hash = _hash_reset_token(request.token)
    user = (
        db.query(User)
        .filter(
            User.password_reset_token == token_hash,
            User.password_reset_expires > datetime.now(UTC),
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
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
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
            StripeGatewayService.delete_customer(current_user.stripe_customer_id)
        except Exception as e:
            logger.error(f"Failed to delete Stripe customer: {e}")

    # 2. Delete user-owned trips and their children
    trip_ids = [t.id for t in db.query(Trip.id).filter(Trip.user_id == user_id).all()]
    if trip_ids:
        # Each of these models has a `trip_id` column pointing at `trips.id`
        # via ForeignKey. mypy can't prove that uniformly across the list —
        # we know it at the call site, so we access `trip_id` on each class.
        trip_children: list[Any] = [
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
        ]
        for model in trip_children:
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

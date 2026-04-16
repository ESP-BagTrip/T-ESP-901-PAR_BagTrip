"""Unit tests for the auth routes."""

import uuid
from datetime import datetime, timedelta, timezone
from unittest.mock import MagicMock, patch

import bcrypt
import pytest
from fastapi import FastAPI
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from src.api.auth.middleware import get_current_user
from src.api.auth.routes import router as auth_router
from src.config.database import get_db
from src.models.refresh_token import RefreshToken
from src.models.user import User
from src.utils.errors import AppError

# Setup the test app
app = FastAPI()
app.include_router(auth_router)


@app.exception_handler(AppError)
async def app_error_handler(request, exc: AppError):
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": {"error": exc.message, "code": exc.code}},
    )


@pytest.fixture
def client():
    """Provide a test client for the app."""
    with TestClient(app) as client:
        yield client


@pytest.fixture
def mock_db_session():
    """Mock the database session."""
    session = MagicMock()
    return session


@pytest.fixture
def override_get_db(mock_db_session):
    """Override the get_db dependency."""
    def _get_db():
        yield mock_db_session

    app.dependency_overrides[get_db] = _get_db
    yield
    app.dependency_overrides = {}


@pytest.fixture
def mock_stripe_client():
    """Mock the StripeClient."""
    with patch("src.api.auth.routes.StripeClient") as mock_stripe:
        mock_customer = MagicMock()
        mock_customer.id = "cus_test123"
        mock_stripe.create_customer.return_value = mock_customer
        mock_stripe.delete_customer.return_value = {"deleted": True}
        yield mock_stripe


class TestRegister:
    """Test suite for the register endpoint."""

    def test_register_success(self, client, override_get_db, mock_db_session, mock_stripe_client):
        """Test successful user registration."""
        mock_db_session.query.return_value.filter.return_value.first.return_value = None

        def refresh_side_effect(instance):
            if isinstance(instance, User):
                instance.id = uuid.uuid4()
                instance.created_at = datetime.now(timezone.utc)
                instance.updated_at = datetime.now(timezone.utc)
            return instance

        mock_db_session.refresh.side_effect = refresh_side_effect

        payload = {
            "email": "newuser@example.com",
            "password": "password123",
            "fullName": "New User",
            "phone": "+1234567890"
        }

        with patch("src.services.plan_service.PlanService.get_plan_info") as mock_plan_info:
            mock_plan_info.return_value = {"ai_generations_remaining": 5}
            response = client.post("/v1/auth/register", json=payload)

            assert response.status_code == 201
            data = response.json()
            assert "access_token" in data
            assert data["user"]["email"] == "newuser@example.com"
            assert data["user"]["fullName"] == "New User"

        assert mock_db_session.add.called
        assert mock_db_session.commit.called
        mock_stripe_client.create_customer.assert_called_once_with(
            email="newuser@example.com",
            name="New User"
        )

    def test_register_user_exists(self, client, override_get_db, mock_db_session):
        """Test registration when user already exists."""
        existing_user = User(id=uuid.uuid4(), email="existing@example.com")
        mock_db_session.query.return_value.filter.return_value.first.return_value = existing_user

        payload = {"email": "existing@example.com", "password": "password123"}
        response = client.post("/v1/auth/register", json=payload)

        assert response.status_code == 400
        assert response.json()["detail"] == "User already exists"


class TestLogin:
    """Test suite for the login endpoint."""

    def test_login_success(self, client, override_get_db, mock_db_session):
        """Test successful login."""
        password = "password123"
        hashed = bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")
        user = User(
            id=uuid.uuid4(),
            email="user@example.com",
            password_hash=hashed,
            created_at=datetime.now(timezone.utc),
            updated_at=None
        )

        mock_db_session.query.return_value.filter.return_value.first.return_value = user

        with patch("src.services.plan_service.PlanService.get_plan_info") as mock_plan_info:
            mock_plan_info.return_value = {"ai_generations_remaining": 5}
            payload = {"email": "user@example.com", "password": password}
            response = client.post("/v1/auth/login", json=payload)

            assert response.status_code == 200
            data = response.json()
            assert "access_token" in data
            assert data["user"]["email"] == "user@example.com"

    def test_login_user_not_found(self, client, override_get_db, mock_db_session):
        """Test login with non-existent email."""
        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        payload = {"email": "unknown@example.com", "password": "password123"}
        response = client.post("/v1/auth/login", json=payload)
        assert response.status_code == 401


class TestMe:
    """Test suite for the me endpoint."""

    def test_me_success(self, client):
        """Test retrieving current user info."""
        user = User(
            id=uuid.uuid4(),
            email="me@example.com",
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc)
        )
        mock_db = MagicMock()
        mock_db.query.return_value.filter.return_value.first.return_value = None

        def _get_db():
            yield mock_db

        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = _get_db

        with patch("src.services.plan_service.PlanService.get_plan_info") as mock_plan_info:
            mock_plan_info.return_value = {"ai_generations_remaining": 5}
            with patch("src.services.profile_service.ProfileService.check_completion") as mock_check:
                mock_check.return_value = (True, [])
                response = client.get("/v1/auth/me")
                assert response.status_code == 200
                data = response.json()
                assert data["email"] == "me@example.com"

        app.dependency_overrides = {}

    def test_update_me_success(self, client):
        """Test updating current user profile."""
        user = User(
            id=uuid.uuid4(),
            email="me@example.com",
            full_name="Old Name",
            phone="+1234567890",
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc)
        )
        mock_db = MagicMock()
        mock_db.query.return_value.filter.return_value.first.return_value = None

        def _get_db():
            yield mock_db

        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = _get_db

        with patch("src.services.plan_service.PlanService.get_plan_info") as mock_plan_info:
            mock_plan_info.return_value = {"ai_generations_remaining": 5}
            with patch("src.services.profile_service.ProfileService.check_completion") as mock_check:
                mock_check.return_value = (True, [])
                payload = {"fullName": "New Name", "phone": "+9876543210"}
                response = client.patch("/v1/auth/me", json=payload)

                assert response.status_code == 200
                data = response.json()
                assert data["fullName"] == "New Name"
                assert data["phone"] == "+9876543210"
                assert user.full_name == "New Name"
                assert mock_db.commit.called

        app.dependency_overrides = {}


class TestSocialSignIn:
    """Test suite for social sign-in endpoints."""

    @patch("src.api.auth.routes.verify_google_id_token")
    def test_google_sign_in_success(self, mock_verify, client, override_get_db, mock_db_session, mock_stripe_client):
        """Test successful Google sign-in."""
        mock_verify.return_value = {
            "email": "google@example.com",
            "name": "Google User",
            "sub": "google-sub-123"
        }
        mock_db_session.query.return_value.filter.return_value.first.return_value = None

        def refresh_side_effect(instance):
            if isinstance(instance, User):
                instance.id = uuid.uuid4()
                instance.created_at = datetime.now(timezone.utc)
            return instance
        mock_db_session.refresh.side_effect = refresh_side_effect

        with patch("src.services.plan_service.PlanService.get_plan_info") as mock_plan_info:
            mock_plan_info.return_value = {"ai_generations_remaining": 5}
            response = client.post("/v1/auth/google", json={"idToken": "fake-google-token"})
            assert response.status_code == 200
            data = response.json()
            assert data["user"]["email"] == "google@example.com"
            assert data["user"]["fullName"] == "Google User"

    @patch("src.api.auth.routes.verify_apple_id_token")
    def test_apple_sign_in_success(self, mock_verify, client, override_get_db, mock_db_session, mock_stripe_client):
        """Test successful Apple sign-in."""
        mock_verify.return_value = {"email": "apple@example.com", "sub": "apple-sub-123"}
        mock_db_session.query.return_value.filter.return_value.first.return_value = None

        def refresh_side_effect(instance):
            if isinstance(instance, User):
                instance.id = uuid.uuid4()
                instance.created_at = datetime.now(timezone.utc)
            return instance
        mock_db_session.refresh.side_effect = refresh_side_effect

        with patch("src.services.plan_service.PlanService.get_plan_info") as mock_plan_info:
            mock_plan_info.return_value = {"ai_generations_remaining": 5}
            response = client.post("/v1/auth/apple", json={"idToken": "fake-apple-token"})
            assert response.status_code == 200
            data = response.json()
            assert data["user"]["email"] == "apple@example.com"


class TestTokenRotation:
    """Test suite for the refresh token rotation endpoint."""

    def test_refresh_token_success(self, client, override_get_db, mock_db_session):
        """Test successful token rotation."""
        user_id = uuid.uuid4()
        stored_token = RefreshToken(
            token="valid-refresh-token",
            user_id=user_id,
            expires_at=datetime.now(timezone.utc) + timedelta(days=1),
            revoked=False
        )
        user = User(id=user_id, email="user@example.com", created_at=datetime.now(timezone.utc))
        mock_db_session.query.return_value.filter.return_value.first.side_effect = [stored_token, user]

        with patch("src.services.plan_service.PlanService.get_plan_info") as mock_plan_info:
            mock_plan_info.return_value = {"ai_generations_remaining": 5}
            response = client.post("/v1/auth/refresh", json={"refresh_token": "valid-refresh-token"})
            assert response.status_code == 200
            assert stored_token.revoked is True
            assert mock_db_session.commit.called

    def test_refresh_token_expired(self, client, override_get_db, mock_db_session):
        """Test token rotation with an expired token."""
        stored_token = RefreshToken(
            token="expired-token",
            expires_at=datetime.now(timezone.utc) - timedelta(days=1),
            revoked=False
        )
        mock_db_session.query.return_value.filter.return_value.first.return_value = stored_token
        response = client.post("/v1/auth/refresh", json={"refresh_token": "expired-token"})
        assert response.status_code == 401


class TestLogout:
    """Test suite for the logout endpoint."""

    def test_logout_success(self, client, override_get_db, mock_db_session):
        """Test successful logout."""
        user = User(id=uuid.uuid4(), email="user@example.com")
        stored_token = RefreshToken(token="token-to-revoke", user_id=user.id, revoked=False)
        app.dependency_overrides[get_current_user] = lambda: user
        mock_db_session.query.return_value.filter.return_value.first.return_value = stored_token
        response = client.post("/v1/auth/logout", json={"refresh_token": "token-to-revoke"})
        assert response.status_code == 204
        assert stored_token.revoked is True
        app.dependency_overrides = {}


class TestPasswordReset:
    """Test suite for the password reset endpoints."""

    def test_forgot_password_success(self, client, override_get_db, mock_db_session):
        """Test forgot password request."""
        user = User(id=uuid.uuid4(), email="user@example.com")
        mock_db_session.query.return_value.filter.return_value.first.return_value = user
        response = client.post("/v1/auth/forgot-password", json={"email": "user@example.com"})
        assert response.status_code == 200
        assert user.password_reset_token is not None

    def test_reset_password_success(self, client, override_get_db, mock_db_session):
        """Test successful password reset."""
        user = User(
            id=uuid.uuid4(),
            email="user@example.com",
            password_reset_token="valid-token",
            password_reset_expires=datetime.now(timezone.utc) + timedelta(hours=1)
        )
        mock_db_session.query.return_value.filter.return_value.first.return_value = user
        payload = {"token": "valid-token", "new_password": "newpassword123"}
        response = client.post("/v1/auth/reset-password", json=payload)
        assert response.status_code == 200
        assert user.password_reset_token is None


class TestAccountDeletion:
    """Test suite for the account deletion endpoint."""

    def test_delete_me_success(self, client, override_get_db, mock_db_session, mock_stripe_client):
        """Test successful account deletion."""
        user = User(id=uuid.uuid4(), email="user@example.com", stripe_customer_id="cus_123")
        app.dependency_overrides[get_current_user] = lambda: user
        mock_db_session.query.return_value.filter.return_value.all.return_value = []
        response = client.delete("/v1/auth/me")
        assert response.status_code == 204
        assert mock_db_session.delete.called
        assert mock_stripe_client.delete_customer.called
        app.dependency_overrides = {}

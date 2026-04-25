"""Unit tests for the auth routes."""

import uuid
from datetime import datetime
from unittest.mock import MagicMock, patch

import bcrypt
import pytest
from fastapi import FastAPI
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from src.api.auth.middleware import get_current_user
from src.api.auth.routes import router as auth_router
from src.config.database import get_db
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
    """Mock the StripeClient — the register/social flows delegate Stripe
    customer creation to UserCreationService, so we patch the symbol there."""
    with patch("src.services.user_creation_service.StripeClient") as mock_stripe:
        mock_customer = MagicMock()
        mock_customer.id = "cus_test123"
        mock_stripe.create_customer.return_value = mock_customer
        yield mock_stripe


class TestRegister:
    """Test suite for the register endpoint."""

    def test_register_success(self, client, override_get_db, mock_db_session, mock_stripe_client):
        """Test successful user registration."""
        # Setup mock DB behavior
        mock_db_session.query.return_value.filter.return_value.first.return_value = (
            None  # User doesn't exist
        )

        def refresh_side_effect(instance):
            instance.id = uuid.uuid4()
            instance.created_at = datetime.utcnow()
            instance.updated_at = datetime.utcnow()

        mock_db_session.refresh.side_effect = refresh_side_effect

        payload = {
            "email": "newuser@example.com",
            "password": "password123",
            "fullName": "New User",
            "phone": "+1234567890",
        }

        response = client.post("/v1/auth/register", json=payload)

        assert response.status_code == 201
        data = response.json()
        assert "access_token" in data
        assert data["user"]["email"] == "newuser@example.com"

        # Verify DB interactions
        assert mock_db_session.add.called
        assert mock_db_session.commit.called

        # Verify Stripe interaction (idempotency key forwarded so a network
        # retry of signup doesn't create a duplicate customer).
        kwargs = mock_stripe_client.create_customer.call_args.kwargs
        assert kwargs["email"] == "newuser@example.com"
        assert kwargs["name"] == "New User"
        assert "idempotency_key" in kwargs

    def test_register_user_exists(self, client, override_get_db, mock_db_session):
        """Test registration when user already exists."""
        # Setup mock DB behavior
        existing_user = User(id=uuid.uuid4(), email="existing@example.com")
        mock_db_session.query.return_value.filter.return_value.first.return_value = existing_user

        payload = {"email": "existing@example.com", "password": "password123"}

        response = client.post("/v1/auth/register", json=payload)

        assert response.status_code == 400
        assert response.json()["detail"] == "User already exists"

    def test_register_integrity_error(
        self, client, override_get_db, mock_db_session, mock_stripe_client
    ):
        """Test registration race condition handling (IntegrityError)."""
        from sqlalchemy.exc import IntegrityError

        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        mock_db_session.commit.side_effect = IntegrityError("mock", "mock", "mock")

        payload = {"email": "race@example.com", "password": "password123"}

        response = client.post("/v1/auth/register", json=payload)

        assert response.status_code == 400
        assert response.json()["detail"] == "User already exists"
        assert mock_db_session.rollback.called

    def test_register_stripe_failure(
        self, client, override_get_db, mock_db_session, mock_stripe_client
    ):
        """Test registration when Stripe customer creation fails."""
        mock_db_session.query.return_value.filter.return_value.first.return_value = None

        # Mock Stripe failure
        mock_stripe_client.create_customer.side_effect = Exception("Stripe down")

        def refresh_side_effect(instance):
            instance.id = uuid.uuid4()
            instance.created_at = datetime.utcnow()
            instance.updated_at = datetime.utcnow()

        mock_db_session.refresh.side_effect = refresh_side_effect

        payload = {"email": "nostripe@example.com", "password": "password123"}

        response = client.post("/v1/auth/register", json=payload)

        # Should fail with 503 — Stripe customer creation is now required
        assert response.status_code == 503
        data = response.json()
        assert data["detail"]["code"] == "STRIPE_CUSTOMER_CREATION_FAILED"


class TestLogin:
    """Test suite for the login endpoint."""

    def test_login_success(self, client, override_get_db, mock_db_session):
        """Test successful login."""
        # Setup user with hashed password
        password = "password123"
        hashed = bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")
        user = User(
            id=uuid.uuid4(),
            email="user@example.com",
            password_hash=hashed,
            created_at=datetime.utcnow(),
            updated_at=None,
        )

        mock_db_session.query.return_value.filter.return_value.first.return_value = user

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
        assert response.json()["detail"] == "Invalid credentials"

    def test_login_wrong_password(self, client, override_get_db, mock_db_session):
        """Test login with incorrect password."""
        # Setup user with hashed password
        password = "password123"
        hashed = bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")
        user = User(id=uuid.uuid4(), email="user@example.com", password_hash=hashed)

        mock_db_session.query.return_value.filter.return_value.first.return_value = user

        payload = {"email": "user@example.com", "password": "wrongpassword"}
        response = client.post("/v1/auth/login", json=payload)

        assert response.status_code == 401
        assert response.json()["detail"] == "Invalid credentials"


class TestMe:
    """Test suite for the me endpoint."""

    def test_me_success(self, client):
        """Test retrieving current user info."""
        user = User(
            id=uuid.uuid4(),
            email="me@example.com",
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )

        # Mock DB session so ProfileService and PlanService don't hit a real DB
        mock_db = MagicMock()
        mock_db.query.return_value.filter.return_value.first.return_value = None

        def _get_db():
            yield mock_db

        # Override both dependencies
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = _get_db

        response = client.get("/v1/auth/me")

        assert response.status_code == 200
        data = response.json()
        assert data["email"] == "me@example.com"
        assert "id" in data

        # Cleanup
        app.dependency_overrides = {}


class TestUpdateMe:
    """Test suite for PATCH /v1/auth/me."""

    def test_update_me_success(self, client):
        """Test updating the current user's name and phone."""
        user = User(
            id=uuid.uuid4(),
            email="me@example.com",
            full_name="Old Name",
            phone=None,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )

        mock_db = MagicMock()
        mock_db.query.return_value.filter.return_value.first.return_value = None

        def _get_db():
            yield mock_db

        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = _get_db

        response = client.patch(
            "/v1/auth/me",
            json={"fullName": "New Name", "phone": "+33123456789"},
        )

        assert response.status_code == 200
        data = response.json()
        assert data["email"] == "me@example.com"
        assert user.full_name == "New Name"
        assert user.phone == "+33123456789"
        assert mock_db.commit.called

        app.dependency_overrides = {}


class TestRefresh:
    """Test suite for POST /v1/auth/refresh."""

    def test_refresh_success(self, client, override_get_db, mock_db_session):
        """Test successful token refresh."""
        from datetime import UTC, timedelta

        user_id = uuid.uuid4()
        user = User(
            id=user_id,
            email="user@example.com",
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )

        stored = MagicMock()
        stored.token = "valid-refresh-token"
        stored.revoked = False
        stored.expires_at = datetime.now(UTC) + timedelta(days=30)
        stored.user_id = user_id

        # First .first() = RefreshToken lookup, second .first() = User lookup
        mock_db_session.query.return_value.filter.return_value.first.side_effect = [
            stored,
            user,
        ]

        response = client.post(
            "/v1/auth/refresh",
            json={"refresh_token": "valid-refresh-token"},
        )

        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert data["user"]["email"] == "user@example.com"
        # Old token should have been revoked (rotation)
        assert stored.revoked is True

    def test_refresh_invalid_token(self, client, override_get_db, mock_db_session):
        """Test refresh with an invalid token returns 401."""
        mock_db_session.query.return_value.filter.return_value.first.return_value = None

        response = client.post(
            "/v1/auth/refresh",
            json={"refresh_token": "bad-token"},
        )

        assert response.status_code == 401
        assert response.json()["detail"] == "Invalid or expired refresh token"

    def test_refresh_expired_token(self, client, override_get_db, mock_db_session):
        """Test refresh with an expired token returns 401."""
        from datetime import UTC, timedelta

        stored = MagicMock()
        stored.token = "expired"
        stored.revoked = False
        stored.expires_at = datetime.now(UTC) - timedelta(days=1)
        stored.user_id = uuid.uuid4()

        mock_db_session.query.return_value.filter.return_value.first.return_value = stored

        response = client.post(
            "/v1/auth/refresh",
            json={"refresh_token": "expired"},
        )

        assert response.status_code == 401
        assert response.json()["detail"] == "Invalid or expired refresh token"


class TestLogout:
    """Test suite for POST /v1/auth/logout and /logout-all."""

    def test_logout_with_body_token(self, client, override_get_db, mock_db_session):
        """Test logout revokes the refresh token from the request body."""
        user = User(id=uuid.uuid4(), email="user@example.com")
        app.dependency_overrides[get_current_user] = lambda: user

        stored = MagicMock()
        stored.revoked = False
        mock_db_session.query.return_value.filter.return_value.first.return_value = stored

        response = client.post(
            "/v1/auth/logout",
            json={"refresh_token": "some-token"},
        )

        assert response.status_code == 204
        assert stored.revoked is True
        assert mock_db_session.commit.called
        app.dependency_overrides = {}

    def test_logout_without_token(self, client, override_get_db, mock_db_session):
        """Test logout without a token still clears cookies and returns 204."""
        user = User(id=uuid.uuid4(), email="user@example.com")
        app.dependency_overrides[get_current_user] = lambda: user

        response = client.post("/v1/auth/logout")

        assert response.status_code == 204
        app.dependency_overrides = {}

    def test_logout_all_success(self, client, override_get_db, mock_db_session):
        """Test /logout-all revokes every refresh token for the user."""
        user = User(id=uuid.uuid4(), email="user@example.com")
        app.dependency_overrides[get_current_user] = lambda: user

        # Mock the bulk update call chain
        mock_db_session.query.return_value.filter.return_value.update.return_value = 3

        response = client.post("/v1/auth/logout-all")

        assert response.status_code == 204
        mock_db_session.commit.assert_called()
        app.dependency_overrides = {}

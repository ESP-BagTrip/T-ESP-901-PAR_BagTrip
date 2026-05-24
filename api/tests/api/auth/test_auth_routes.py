"""Unit tests for the auth routes."""

import uuid
from datetime import datetime
from unittest.mock import AsyncMock, MagicMock, patch

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

        with patch(
            "src.api.auth.routes.MailerService.send_email_verification",
            new=AsyncMock(return_value=False),
        ):
            response = client.post("/v1/auth/register", json=payload)

        assert response.status_code == 201
        data = response.json()
        assert "access_token" in data
        assert data["user"]["email"] == "newuser@example.com"
        # A freshly registered user starts unverified (soft verification).
        assert data["user"]["emailVerified"] is False

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

    def test_login_locks_account_after_repeated_failures(
        self, client, override_get_db, mock_db_session
    ):
        """After enough wrong-password attempts the account is locked (429)."""
        from src.services.auth_lockout_service import MAX_FAILURES, AuthLockoutService

        # Distinct email so the process-shared counter doesn't bleed into other tests.
        email = f"lockme-{uuid.uuid4().hex}@example.com"
        AuthLockoutService.reset(email)
        hashed = bcrypt.hashpw(b"password123", bcrypt.gensalt()).decode("utf-8")
        user = User(id=uuid.uuid4(), email=email, password_hash=hashed)
        mock_db_session.query.return_value.filter.return_value.first.return_value = user

        wrong = {"email": email, "password": "nope"}
        for _ in range(MAX_FAILURES):
            assert client.post("/v1/auth/login", json=wrong).status_code == 401

        # The next attempt is locked out, even with the correct password.
        locked = client.post("/v1/auth/login", json={"email": email, "password": "password123"})
        assert locked.status_code == 429
        assert "Retry-After" in locked.headers
        AuthLockoutService.reset(email)

    def test_login_success_resets_lockout_counter(
        self, client, override_get_db, mock_db_session
    ):
        """A successful login clears prior failures so the user isn't locked next time."""
        from src.services.auth_lockout_service import AuthLockoutService

        email = f"reset-{uuid.uuid4().hex}@example.com"
        password = "password123"
        hashed = bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")
        user = User(
            id=uuid.uuid4(),
            email=email,
            password_hash=hashed,
            created_at=datetime.utcnow(),
            updated_at=None,
        )
        mock_db_session.query.return_value.filter.return_value.first.return_value = user

        AuthLockoutService.record_failure(email)
        AuthLockoutService.record_failure(email)
        assert client.post("/v1/auth/login", json={"email": email, "password": password}).status_code == 200
        assert AuthLockoutService.is_locked(email)[0] is False


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


class TestRefreshTokenHashing:
    """Refresh tokens must be stored hashed, never in clear text."""

    def test_hash_is_deterministic_sha256(self):
        """The hash helper is a stable 64-char SHA-256 hex digest."""
        from src.api.auth.routes import _hash_refresh_token

        digest = _hash_refresh_token("some-raw-token")
        assert digest == _hash_refresh_token("some-raw-token")
        assert len(digest) == 64
        assert digest != "some-raw-token"

    def test_create_refresh_token_persists_hash_not_raw(self):
        """create_refresh_token stores the hash but returns the raw token."""
        from src.api.auth.routes import _hash_refresh_token, create_refresh_token

        db = MagicMock()
        raw = create_refresh_token(str(uuid.uuid4()), db)

        added = db.add.call_args[0][0]
        assert added.token == _hash_refresh_token(raw)
        assert added.token != raw

    def test_refresh_hashes_presented_token_before_lookup(
        self, client, override_get_db, mock_db_session
    ):
        """The handler hashes the incoming raw token before querying the DB."""
        from datetime import UTC, timedelta

        from src.api.auth import routes as auth_routes

        user_id = uuid.uuid4()
        user = User(id=user_id, email="user@example.com", created_at=datetime.utcnow())
        stored = MagicMock()
        stored.revoked = False
        stored.expires_at = datetime.now(UTC) + timedelta(days=30)
        stored.user_id = user_id
        mock_db_session.query.return_value.filter.return_value.first.side_effect = [stored, user]

        with patch.object(
            auth_routes,
            "_hash_refresh_token",
            wraps=auth_routes._hash_refresh_token,
        ) as spy:
            response = client.post("/v1/auth/refresh", json={"refresh_token": "raw-token"})

        assert response.status_code == 200
        spy.assert_any_call("raw-token")


class TestRefreshReuseDetection:
    """Presenting an already-revoked refresh token is a theft signal."""

    def test_reused_revoked_token_revokes_all_and_401(
        self, client, override_get_db, mock_db_session
    ):
        """A revoked token replayed -> revoke the whole chain + 401."""
        from datetime import UTC, timedelta

        stored = MagicMock()
        stored.revoked = True  # already rotated away
        stored.expires_at = datetime.now(UTC) + timedelta(days=30)
        stored.user_id = uuid.uuid4()
        mock_db_session.query.return_value.filter.return_value.first.return_value = stored

        response = client.post("/v1/auth/refresh", json={"refresh_token": "stolen"})

        assert response.status_code == 401
        assert response.json()["detail"] == "Invalid or expired refresh token"
        # The chain-revoke bulk update must have fired.
        mock_db_session.query.return_value.filter.return_value.update.assert_called_with(
            {"revoked": True}
        )
        assert mock_db_session.commit.called


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


class TestRegisterEmailVerification:
    """Registration issues an email-verification token and sends the email."""

    def test_register_sends_verification_email(
        self, client, override_get_db, mock_db_session, mock_stripe_client
    ):
        """A fresh signup persists a hashed verification token and emails it."""
        created: dict = {}

        def refresh_side_effect(instance):
            instance.id = uuid.uuid4()
            instance.created_at = datetime.utcnow()
            instance.updated_at = datetime.utcnow()
            created["user"] = instance

        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        mock_db_session.refresh.side_effect = refresh_side_effect

        with patch(
            "src.api.auth.routes.MailerService.send_email_verification",
            new=AsyncMock(return_value=True),
        ) as send:
            response = client.post(
                "/v1/auth/register",
                json={"email": "verify@example.com", "password": "password123"},
            )

        assert response.status_code == 201
        send.assert_awaited_once()
        # The verification email targets the new address, never logging the raw token.
        assert send.await_args.args[0] == "verify@example.com"
        # A hashed token + expiry were stamped on the user before sending.
        user = created["user"]
        assert user.email_verification_token is not None
        assert user.email_verification_token != send.await_args.args[1]
        assert user.email_verification_expires is not None


class TestVerifyEmail:
    """Test suite for POST /v1/auth/verify-email."""

    def test_verify_email_success(self, client, override_get_db, mock_db_session):
        """A valid token flips email_verified and clears the token + expiry."""
        import hashlib
        from datetime import UTC, timedelta

        now = datetime.now(UTC)
        user = User(
            id=uuid.uuid4(),
            email="user@example.com",
            email_verified=False,
            email_verification_token=hashlib.sha256(b"valid-token").hexdigest(),
            email_verification_expires=now + timedelta(hours=24),
        )
        mock_db_session.query.return_value.filter.return_value.first.return_value = user

        response = client.post("/v1/auth/verify-email", json={"token": "valid-token"})

        assert response.status_code == 200
        assert response.json()["message"] == "Email verified successfully."
        assert user.email_verified is True
        assert user.email_verification_token is None
        assert user.email_verification_expires is None
        assert mock_db_session.commit.called

    def test_verify_email_invalid_token(self, client, override_get_db, mock_db_session):
        """An unknown token returns 400."""
        mock_db_session.query.return_value.filter.return_value.first.return_value = None

        response = client.post("/v1/auth/verify-email", json={"token": "nope"})

        assert response.status_code == 400
        assert response.json()["detail"] == "Invalid or expired verification token"

    def test_verify_email_expired_token(self, client, override_get_db, mock_db_session):
        """An expired token is filtered out by the query -> 400."""
        # The route filters by email_verification_expires > now(), so an expired
        # token means the query returns None.
        mock_db_session.query.return_value.filter.return_value.first.return_value = None

        response = client.post("/v1/auth/verify-email", json={"token": "expired"})

        assert response.status_code == 400
        assert response.json()["detail"] == "Invalid or expired verification token"


class TestResendVerification:
    """Test suite for POST /v1/auth/resend-verification."""

    def test_resend_when_unverified_reissues_and_sends(
        self, client, override_get_db, mock_db_session
    ):
        """An unverified user gets a fresh token and a new email."""
        user = User(
            id=uuid.uuid4(),
            email="user@example.com",
            email_verified=False,
            email_verification_token=None,
            email_verification_expires=None,
        )
        app.dependency_overrides[get_current_user] = lambda: user
        # DeviceTokenService.get_locale_for_user queries DeviceToken -> None.
        mock_db_session.query.return_value.filter.return_value.order_by.return_value.first.return_value = None  # noqa: E501

        with patch(
            "src.api.auth.routes.MailerService.send_email_verification",
            new=AsyncMock(return_value=True),
        ) as send:
            response = client.post("/v1/auth/resend-verification")

        assert response.status_code == 200
        assert response.json()["message"] == "Verification email sent."
        assert user.email_verification_token is not None
        assert user.email_verification_expires is not None
        send.assert_awaited_once()
        assert send.await_args.args[0] == "user@example.com"
        assert mock_db_session.commit.called
        app.dependency_overrides = {}

    def test_resend_when_already_verified_is_noop(self, client, override_get_db, mock_db_session):
        """An already-verified user gets a 200 no-op without sending mail."""
        user = User(id=uuid.uuid4(), email="user@example.com", email_verified=True)
        app.dependency_overrides[get_current_user] = lambda: user

        with patch(
            "src.api.auth.routes.MailerService.send_email_verification",
            new=AsyncMock(return_value=True),
        ) as send:
            response = client.post("/v1/auth/resend-verification")

        assert response.status_code == 200
        assert response.json()["message"] == "Email already verified."
        send.assert_not_awaited()
        app.dependency_overrides = {}


class TestMeExposesEmailVerified:
    """GET /v1/auth/me surfaces the emailVerified flag (mobile banner)."""

    def test_me_returns_email_verified(self, client):
        """The /me payload exposes emailVerified mirroring the user column."""
        user = User(
            id=uuid.uuid4(),
            email="me@example.com",
            email_verified=True,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        mock_db = MagicMock()
        mock_db.query.return_value.filter.return_value.first.return_value = None

        def _get_db():
            yield mock_db

        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = _get_db

        response = client.get("/v1/auth/me")

        assert response.status_code == 200
        assert response.json()["emailVerified"] is True
        app.dependency_overrides = {}


class TestOAuthMarksEmailVerified:
    """Google / Apple sign-in mark the email as provider-verified."""

    def test_google_sign_in_sets_email_verified(
        self, client, override_get_db, mock_db_session, mock_stripe_client
    ):
        """A new Google user is created with email_verified flipped to True."""
        created: dict = {}

        def refresh_side_effect(instance):
            instance.id = uuid.uuid4()
            instance.created_at = datetime.utcnow()
            instance.updated_at = datetime.utcnow()
            created["user"] = instance

        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        mock_db_session.refresh.side_effect = refresh_side_effect

        with patch(
            "src.api.auth.routes.verify_google_id_token",
            new=AsyncMock(return_value={"email": "g@example.com", "name": "G User"}),
        ):
            response = client.post("/v1/auth/google", json={"idToken": "tok"})

        assert response.status_code == 200
        assert response.json()["user"]["emailVerified"] is True
        assert created["user"].email_verified is True

    def test_apple_sign_in_sets_email_verified(
        self, client, override_get_db, mock_db_session, mock_stripe_client
    ):
        """A new Apple user is created with email_verified flipped to True."""
        created: dict = {}

        def refresh_side_effect(instance):
            instance.id = uuid.uuid4()
            instance.created_at = datetime.utcnow()
            instance.updated_at = datetime.utcnow()
            created["user"] = instance

        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        mock_db_session.refresh.side_effect = refresh_side_effect

        with patch(
            "src.api.auth.routes.verify_apple_id_token",
            new=AsyncMock(return_value={"email": "a@example.com", "sub": "sub123"}),
        ):
            response = client.post("/v1/auth/apple", json={"idToken": "tok"})

        assert response.status_code == 200
        assert response.json()["user"]["emailVerified"] is True
        assert created["user"].email_verified is True

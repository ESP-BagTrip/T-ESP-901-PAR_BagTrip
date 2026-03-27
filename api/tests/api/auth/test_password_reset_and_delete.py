"""Unit tests for forgot-password, reset-password and delete-me endpoints."""

import uuid
from datetime import UTC, datetime, timedelta
from unittest.mock import MagicMock, patch

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from src.api.auth.routes import router as auth_router
from src.api.auth.middleware import get_current_user
from src.config.database import get_db
from src.models.user import User

# Setup the test app
app = FastAPI()
app.include_router(auth_router)


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
def mock_user():
    """Create a mock user."""
    return User(
        id=uuid.uuid4(),
        email="test@example.com",
        stripe_customer_id="cus_test123",
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )


@pytest.fixture
def override_get_current_user(mock_user):
    """Override the get_current_user dependency."""
    app.dependency_overrides[get_current_user] = lambda: mock_user
    yield
    app.dependency_overrides = {}


class TestForgotPassword:
    """Test suite for POST /v1/auth/forgot-password."""

    def test_forgot_password_existing_user(self, client, override_get_db, mock_db_session):
        """Test forgot-password with an existing user returns 200 and saves token."""
        user = User(
            id=uuid.uuid4(),
            email="user@example.com",
            password_reset_token=None,
            password_reset_expires=None,
        )
        mock_db_session.query.return_value.filter.return_value.first.return_value = user

        payload = {"email": "user@example.com"}
        response = client.post("/v1/auth/forgot-password", json=payload)

        assert response.status_code == 200
        data = response.json()
        assert data["message"] == "If this email exists, a reset link has been sent."

        # Verify token was saved to the user
        assert user.password_reset_token is not None
        assert user.password_reset_expires is not None
        assert mock_db_session.commit.called

    def test_forgot_password_nonexistent_email(self, client, override_get_db, mock_db_session):
        """Test forgot-password with non-existent email still returns 200 (no leak)."""
        mock_db_session.query.return_value.filter.return_value.first.return_value = None

        payload = {"email": "nobody@example.com"}
        response = client.post("/v1/auth/forgot-password", json=payload)

        assert response.status_code == 200
        data = response.json()
        assert data["message"] == "If this email exists, a reset link has been sent."

        # Verify commit was NOT called since no user was found
        assert not mock_db_session.commit.called


class TestResetPassword:
    """Test suite for POST /v1/auth/reset-password."""

    def test_reset_password_success(self, client, override_get_db, mock_db_session):
        """Test reset-password with a valid token updates the password and clears token."""
        user = User(
            id=uuid.uuid4(),
            email="user@example.com",
            password_hash="old_hash",
            password_reset_token="valid-token",
            password_reset_expires=datetime.now(UTC) + timedelta(hours=1),
        )
        mock_db_session.query.return_value.filter.return_value.first.return_value = user

        payload = {"token": "valid-token", "new_password": "newpassword123"}
        response = client.post("/v1/auth/reset-password", json=payload)

        assert response.status_code == 200
        data = response.json()
        assert data["message"] == "Password updated successfully."

        # Verify password was updated and token was cleared
        assert user.password_hash != "old_hash"
        assert user.password_reset_token is None
        assert user.password_reset_expires is None
        assert mock_db_session.commit.called

    def test_reset_password_invalid_token(self, client, override_get_db, mock_db_session):
        """Test reset-password with an invalid token returns 400."""
        mock_db_session.query.return_value.filter.return_value.first.return_value = None

        payload = {"token": "invalid-token", "new_password": "newpassword123"}
        response = client.post("/v1/auth/reset-password", json=payload)

        assert response.status_code == 400
        assert response.json()["detail"] == "Invalid or expired reset token"

    def test_reset_password_expired_token(self, client, override_get_db, mock_db_session):
        """Test reset-password with an expired token returns 400."""
        # The route filters by password_reset_expires > now(), so an expired token
        # means the query returns None — same behavior as invalid token.
        mock_db_session.query.return_value.filter.return_value.first.return_value = None

        payload = {"token": "expired-token", "new_password": "newpassword123"}
        response = client.post("/v1/auth/reset-password", json=payload)

        assert response.status_code == 400
        assert response.json()["detail"] == "Invalid or expired reset token"


class TestDeleteMe:
    """Test suite for DELETE /v1/auth/me."""

    @patch("src.api.auth.routes.StripeClient")
    def test_delete_me_success(
        self,
        mock_stripe,
        client,
        override_get_current_user,
        override_get_db,
        mock_db_session,
        mock_user,
    ):
        """Test successful account deletion returns 204 and deletes data."""
        # Mock trip query to return no trips (simplest case)
        mock_trip_query = MagicMock()
        mock_trip_query.all.return_value = []

        # Setup query routing: when querying Trip.id with filter, return empty list
        mock_db_session.query.return_value.filter.return_value.all.return_value = []
        mock_db_session.query.return_value.filter.return_value.delete.return_value = 0

        response = client.delete("/v1/auth/me")

        assert response.status_code == 204

        # Verify Stripe customer deletion was called
        mock_stripe.delete_customer.assert_called_once_with("cus_test123")

        # Verify user was deleted
        mock_db_session.delete.assert_called_once_with(mock_user)
        assert mock_db_session.commit.called

    @patch("src.api.auth.routes.StripeClient")
    def test_delete_me_no_stripe_customer(
        self,
        mock_stripe,
        client,
        override_get_db,
        mock_db_session,
    ):
        """Test account deletion when user has no Stripe customer ID."""
        user = User(
            id=uuid.uuid4(),
            email="nostripe@example.com",
            stripe_customer_id=None,
            created_at=datetime.now(UTC),
            updated_at=datetime.now(UTC),
        )
        app.dependency_overrides[get_current_user] = lambda: user

        mock_db_session.query.return_value.filter.return_value.all.return_value = []
        mock_db_session.query.return_value.filter.return_value.delete.return_value = 0

        response = client.delete("/v1/auth/me")

        assert response.status_code == 204

        # Stripe should NOT be called
        mock_stripe.delete_customer.assert_not_called()

        # User should still be deleted
        mock_db_session.delete.assert_called_once_with(user)
        assert mock_db_session.commit.called

        # Cleanup
        app.dependency_overrides = {}

    @patch("src.api.auth.routes.StripeClient")
    def test_delete_me_stripe_failure_continues(
        self,
        mock_stripe,
        client,
        override_get_current_user,
        override_get_db,
        mock_db_session,
        mock_user,
    ):
        """Test that account deletion continues even if Stripe deletion fails."""
        mock_stripe.delete_customer.side_effect = Exception("Stripe down")

        mock_db_session.query.return_value.filter.return_value.all.return_value = []
        mock_db_session.query.return_value.filter.return_value.delete.return_value = 0

        response = client.delete("/v1/auth/me")

        # Should still succeed despite Stripe failure
        assert response.status_code == 204
        mock_db_session.delete.assert_called_once_with(mock_user)
        assert mock_db_session.commit.called

    def test_delete_me_requires_authentication(self, client, override_get_db):
        """Test that DELETE /me requires authentication (no user override)."""
        # Do NOT override get_current_user — should fail with 401
        response = client.delete("/v1/auth/me")

        assert response.status_code in (401, 403)

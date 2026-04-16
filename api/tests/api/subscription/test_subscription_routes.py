"""Unit tests for the subscription routes."""

import uuid
from unittest.mock import MagicMock, patch

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from src.api.auth.middleware import get_current_user
from src.api.subscription.routes import router as subscription_router
from src.config.database import get_db
from src.models.user import User
from src.utils.errors import AppError

# Setup the test app
app = FastAPI()
app.include_router(subscription_router)


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
    return User(id=uuid.uuid4(), email="test@example.com")


@pytest.fixture
def override_get_current_user(mock_user):
    """Override the get_current_user dependency."""
    app.dependency_overrides[get_current_user] = lambda: mock_user
    yield
    app.dependency_overrides = {}


class TestCreateCheckout:
    """Tests for POST /v1/subscription/checkout."""

    @patch("src.api.subscription.routes.SubscriptionService")
    def test_create_checkout_success(
        self, mock_service, client, override_get_current_user, override_get_db
    ):
        """Test successful checkout session creation."""
        mock_service.create_checkout_session.return_value = {
            "url": "https://checkout.stripe.com/session_123"
        }

        response = client.post("/v1/subscription/checkout")

        assert response.status_code == 200
        assert response.json()["url"] == "https://checkout.stripe.com/session_123"
        mock_service.create_checkout_session.assert_called_once()

    @patch("src.api.subscription.routes.SubscriptionService")
    def test_create_checkout_already_premium(
        self, mock_service, client, override_get_current_user, override_get_db
    ):
        """Test checkout when user is already on a paid plan."""
        mock_service.create_checkout_session.side_effect = AppError(
            "ALREADY_PREMIUM", 400, "You are already on a paid plan"
        )

        response = client.post("/v1/subscription/checkout")

        assert response.status_code == 400
        assert response.json()["detail"]["error"] == "You are already on a paid plan"

    @patch("src.api.subscription.routes.SubscriptionService")
    def test_create_checkout_stripe_error(
        self, mock_service, client, override_get_current_user, override_get_db
    ):
        """Test checkout when Stripe returns an error."""
        mock_service.create_checkout_session.side_effect = AppError(
            "STRIPE_ERROR", 500, "Stripe error"
        )

        response = client.post("/v1/subscription/checkout")

        assert response.status_code == 500
        assert response.json()["detail"]["error"] == "Stripe error"


class TestCreatePortal:
    """Tests for POST /v1/subscription/portal."""

    @patch("src.api.subscription.routes.SubscriptionService")
    def test_create_portal_success(
        self, mock_service, client, override_get_current_user, override_get_db
    ):
        """Test successful portal session creation."""
        mock_service.create_portal_session.return_value = {
            "url": "https://billing.stripe.com/session_456"
        }

        response = client.post("/v1/subscription/portal")

        assert response.status_code == 200
        assert response.json()["url"] == "https://billing.stripe.com/session_456"
        mock_service.create_portal_session.assert_called_once()

    @patch("src.api.subscription.routes.SubscriptionService")
    def test_create_portal_error(
        self, mock_service, client, override_get_current_user, override_get_db
    ):
        """Test portal session creation when Stripe returns an error."""
        mock_service.create_portal_session.side_effect = AppError(
            "STRIPE_ERROR", 500, "Portal error"
        )

        response = client.post("/v1/subscription/portal")

        assert response.status_code == 500
        assert response.json()["detail"]["error"] == "Portal error"


class TestGetStatus:
    """Tests for GET /v1/subscription/status."""

    @patch("src.api.subscription.routes.SubscriptionService")
    def test_get_status_success(
        self, mock_service, client, override_get_current_user, override_get_db
    ):
        """Test successful subscription status retrieval."""
        mock_service.get_status.return_value = {
            "plan": "FREE",
            "limits": {
                "max_trips": 3,
                "max_activities_per_trip": 10,
            },
            "stripe_subscription_id": None,
            "plan_expires_at": None,
        }

        response = client.get("/v1/subscription/status")

        assert response.status_code == 200
        data = response.json()
        assert data["plan"] == "FREE"
        assert data["stripe_subscription_id"] is None
        assert data["plan_expires_at"] is None
        assert "limits" in data
        mock_service.get_status.assert_called_once()

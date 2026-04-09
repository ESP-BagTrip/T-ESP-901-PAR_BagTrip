"""Unit tests for SubscriptionService."""

from unittest.mock import MagicMock, patch

import pytest

from src.services.subscription_service import SubscriptionService
from src.utils.errors import AppError


@pytest.fixture
def mock_db_session():
    """Mock database session."""
    return MagicMock()


class TestSubscriptionService:
    """Tests for SubscriptionService."""

    @patch("stripe.checkout.Session.create")
    @patch("src.services.stripe_products_service.STRIPE_PRODUCT_IDS", {"premium_subscription": "price_123"})
    @patch("src.services.subscription_service.PlanService")
    @patch("src.services.subscription_service.settings")
    def test_create_checkout_success(
        self, mock_settings, mock_plan_service, mock_checkout_create, mock_db_session
    ):
        """Test successful checkout session creation."""
        mock_settings.STRIPE_SECRET_KEY = "sk_test"
        mock_settings.STRIPE_SUCCESS_URL = "https://success.url"
        mock_settings.STRIPE_CANCEL_URL = "https://cancel.url"

        # PlanService.get_plan(user).value != "FREE" should be False (user IS free)
        mock_plan = MagicMock()
        mock_plan.value = "FREE"
        mock_plan_service.get_plan.return_value = mock_plan

        user = MagicMock()
        user.id = "user_123"
        user.stripe_customer_id = "cus_123"
        user.plan = "FREE"

        mock_session = MagicMock()
        mock_session.url = "https://checkout.stripe.com/session_123"
        mock_checkout_create.return_value = mock_session

        result = SubscriptionService.create_checkout_session(mock_db_session, user)

        assert result == {"url": "https://checkout.stripe.com/session_123"}
        mock_checkout_create.assert_called_once()

    @patch("src.services.subscription_service.PlanService")
    @patch("src.services.subscription_service.settings")
    def test_create_checkout_already_premium(
        self, mock_settings, mock_plan_service, mock_db_session
    ):
        """Test error when user is already premium."""
        mock_settings.STRIPE_SECRET_KEY = "sk_test"

        mock_plan = MagicMock()
        mock_plan.value = "PREMIUM"
        mock_plan_service.get_plan.return_value = mock_plan

        user = MagicMock()
        user.plan = "PREMIUM"
        user.stripe_customer_id = "cus_123"

        with pytest.raises(AppError) as exc:
            SubscriptionService.create_checkout_session(mock_db_session, user)
        assert exc.value.code == "ALREADY_PREMIUM"

    @patch("src.services.subscription_service.PlanService")
    @patch("src.services.subscription_service.settings")
    def test_create_checkout_missing_customer(
        self, mock_settings, mock_plan_service, mock_db_session
    ):
        """Test error when user has no stripe customer ID."""
        mock_settings.STRIPE_SECRET_KEY = "sk_test"

        mock_plan = MagicMock()
        mock_plan.value = "FREE"
        mock_plan_service.get_plan.return_value = mock_plan

        user = MagicMock()
        user.stripe_customer_id = None
        user.plan = "FREE"

        with pytest.raises(AppError) as exc:
            SubscriptionService.create_checkout_session(mock_db_session, user)
        assert exc.value.code == "STRIPE_CUSTOMER_MISSING"

    @patch("src.services.subscription_service.settings")
    def test_create_checkout_stripe_not_configured(self, mock_settings, mock_db_session):
        """Test error when Stripe is not configured."""
        mock_settings.STRIPE_SECRET_KEY = None

        user = MagicMock()

        with pytest.raises(AppError) as exc:
            SubscriptionService.create_checkout_session(mock_db_session, user)
        assert exc.value.code == "STRIPE_NOT_CONFIGURED"

    @patch("stripe.billing_portal.Session.create")
    @patch("src.services.subscription_service.settings")
    def test_create_portal_success(
        self, mock_settings, mock_portal_create, mock_db_session
    ):
        """Test successful portal session creation."""
        mock_settings.STRIPE_SECRET_KEY = "sk_test"

        user = MagicMock()
        user.stripe_customer_id = "cus_123"

        mock_session = MagicMock()
        mock_session.url = "https://billing.stripe.com/portal_123"
        mock_portal_create.return_value = mock_session

        result = SubscriptionService.create_portal_session(mock_db_session, user)

        assert result == {"url": "https://billing.stripe.com/portal_123"}
        mock_portal_create.assert_called_once()

    @patch("src.services.subscription_service.settings")
    def test_create_portal_missing_customer(self, mock_settings, mock_db_session):
        """Test error when user has no stripe customer ID for portal."""
        mock_settings.STRIPE_SECRET_KEY = "sk_test"

        user = MagicMock()
        user.stripe_customer_id = None

        with pytest.raises(AppError) as exc:
            SubscriptionService.create_portal_session(mock_db_session, user)
        assert exc.value.code == "STRIPE_CUSTOMER_MISSING"

    @patch("src.services.subscription_service.PlanService")
    def test_get_status_success(self, mock_plan_service, mock_db_session):
        """Test successful status retrieval."""
        mock_plan_service.get_plan_info.return_value = {
            "plan": "FREE",
            "limits": {},
        }

        user = MagicMock()
        user.stripe_subscription_id = None
        user.plan_expires_at = None

        result = SubscriptionService.get_status(mock_db_session, user)

        assert result["plan"] == "FREE"
        assert result["limits"] == {}
        assert result["stripe_subscription_id"] is None
        assert result["plan_expires_at"] is None
        mock_plan_service.get_plan_info.assert_called_once_with(mock_db_session, user)

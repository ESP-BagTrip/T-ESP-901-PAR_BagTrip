"""Unit tests for SubscriptionService — full Premium lifecycle."""

import uuid
from unittest.mock import MagicMock, patch

import pytest

from src.services.subscription_service import SubscriptionService
from src.utils.errors import AppError


@pytest.fixture
def mock_db_session():
    return MagicMock()


@pytest.fixture
def free_user():
    user = MagicMock()
    user.id = uuid.uuid4()
    user.plan = "FREE"
    user.stripe_customer_id = "cus_123"
    user.stripe_subscription_id = None
    user.plan_expires_at = None
    return user


@pytest.fixture
def premium_user():
    user = MagicMock()
    user.id = uuid.uuid4()
    user.plan = "PREMIUM"
    user.stripe_customer_id = "cus_123"
    user.stripe_subscription_id = "sub_123"
    user.plan_expires_at = None
    return user


class TestCheckout:
    @patch("stripe.checkout.Session.create")
    @patch(
        "src.services.stripe_products_service.STRIPE_PRODUCT_IDS",
        {"premium_subscription": "price_123"},
    )
    @patch("src.services.subscription_service.PlanService")
    @patch("src.services.subscription_service.settings")
    def test_create_checkout_success(
        self, mock_settings, mock_plan_service, mock_checkout, mock_db_session, free_user
    ):
        mock_settings.STRIPE_SECRET_KEY = "sk_test"
        mock_settings.STRIPE_SUCCESS_URL = "https://success.url"
        mock_settings.STRIPE_CANCEL_URL = "https://cancel.url"
        mock_plan_service.get_plan.return_value = MagicMock(value="FREE")
        mock_checkout.return_value = MagicMock(url="https://checkout.stripe.com/session_123")

        result = SubscriptionService.create_checkout_session(mock_db_session, free_user)

        assert result == {"url": "https://checkout.stripe.com/session_123"}
        mock_checkout.assert_called_once()

    @patch("src.services.subscription_service.PlanService")
    @patch("src.services.subscription_service.settings")
    def test_create_checkout_already_premium(
        self, mock_settings, mock_plan_service, mock_db_session, premium_user
    ):
        mock_settings.STRIPE_SECRET_KEY = "sk_test"
        mock_plan_service.get_plan.return_value = MagicMock(value="PREMIUM")

        with pytest.raises(AppError) as exc:
            SubscriptionService.create_checkout_session(mock_db_session, premium_user)
        assert exc.value.code == "ALREADY_PREMIUM"

    @patch("src.services.subscription_service.PlanService")
    @patch("src.services.subscription_service.settings")
    def test_create_checkout_missing_customer(
        self, mock_settings, mock_plan_service, mock_db_session, free_user
    ):
        mock_settings.STRIPE_SECRET_KEY = "sk_test"
        mock_plan_service.get_plan.return_value = MagicMock(value="FREE")
        free_user.stripe_customer_id = None

        with pytest.raises(AppError) as exc:
            SubscriptionService.create_checkout_session(mock_db_session, free_user)
        assert exc.value.code == "STRIPE_CUSTOMER_MISSING"

    @patch("src.services.subscription_service.settings")
    def test_create_checkout_stripe_not_configured(self, mock_settings, mock_db_session, free_user):
        mock_settings.STRIPE_SECRET_KEY = None

        with pytest.raises(AppError) as exc:
            SubscriptionService.create_checkout_session(mock_db_session, free_user)
        assert exc.value.code == "STRIPE_NOT_CONFIGURED"


class TestPortal:
    @patch("src.services.subscription_service.StripeClient")
    @patch("src.services.subscription_service.settings")
    def test_create_portal_success(self, mock_settings, mock_client, mock_db_session, free_user):
        mock_settings.STRIPE_SECRET_KEY = "sk_test"
        mock_settings.STRIPE_PORTAL_RETURN_URL = "bagtrip://profile"
        mock_client.create_billing_portal_session.return_value = MagicMock(
            url="https://billing.stripe.com/portal_123"
        )

        result = SubscriptionService.create_portal_session(mock_db_session, free_user)

        assert result == {"url": "https://billing.stripe.com/portal_123"}

    @patch("src.services.subscription_service.settings")
    def test_create_portal_missing_customer(self, mock_settings, mock_db_session, free_user):
        mock_settings.STRIPE_SECRET_KEY = "sk_test"
        free_user.stripe_customer_id = None

        with pytest.raises(AppError) as exc:
            SubscriptionService.create_portal_session(mock_db_session, free_user)
        assert exc.value.code == "STRIPE_CUSTOMER_MISSING"


class TestStatus:
    @patch("src.services.subscription_service.PlanService")
    def test_get_status_success(self, mock_plan_service, mock_db_session, free_user):
        mock_plan_service.get_plan_info.return_value = {"plan": "FREE", "limits": {}}

        result = SubscriptionService.get_status(mock_db_session, free_user)

        assert result["plan"] == "FREE"
        assert result["stripe_subscription_id"] is None
        assert result["plan_expires_at"] is None


class TestSubscriptionDetails:
    @patch("src.services.subscription_service.StripeClient")
    @patch("src.services.subscription_service.PlanService")
    @patch("src.services.subscription_service.settings")
    def test_details_with_active_subscription(
        self,
        mock_settings,
        mock_plan_service,
        mock_client,
        mock_db_session,
        premium_user,
    ):
        """Active sub: returns cancel state, period end, payment method."""
        mock_settings.STRIPE_SECRET_KEY = "sk_test"
        mock_plan_service.get_plan_info.return_value = {"plan": "PREMIUM"}

        mock_client.retrieve_subscription.return_value = MagicMock(
            cancel_at_period_end=True,
            current_period_end=1735689600,
            default_payment_method="pm_123",
        )
        mock_client.retrieve_payment_method.return_value = MagicMock(
            card=MagicMock(brand="visa", last4="4242", exp_month=12, exp_year=2030)
        )

        result = SubscriptionService.get_subscription_details(mock_db_session, premium_user)

        assert result["cancel_at_period_end"] is True
        assert result["current_period_end"] is not None
        assert result["payment_method"]["last4"] == "4242"
        assert result["payment_method"]["brand"] == "visa"

    @patch("src.services.subscription_service.PlanService")
    @patch("src.services.subscription_service.settings")
    def test_details_no_subscription(
        self, mock_settings, mock_plan_service, mock_db_session, free_user
    ):
        """Free user: returns base info with empty Stripe-side fields."""
        mock_settings.STRIPE_SECRET_KEY = "sk_test"
        mock_plan_service.get_plan_info.return_value = {"plan": "FREE"}

        result = SubscriptionService.get_subscription_details(mock_db_session, free_user)

        assert result["cancel_at_period_end"] is False
        assert result["payment_method"] is None

    @patch("src.services.subscription_service.StripeClient")
    @patch("src.services.subscription_service.PlanService")
    @patch("src.services.subscription_service.settings")
    def test_details_falls_back_when_stripe_errors(
        self,
        mock_settings,
        mock_plan_service,
        mock_client,
        mock_db_session,
        premium_user,
    ):
        """If Stripe is unreachable, return base info — never crash the screen."""
        import stripe

        mock_settings.STRIPE_SECRET_KEY = "sk_test"
        mock_plan_service.get_plan_info.return_value = {"plan": "PREMIUM"}
        mock_client.retrieve_subscription.side_effect = stripe.StripeError("offline")

        result = SubscriptionService.get_subscription_details(mock_db_session, premium_user)

        assert result["cancel_at_period_end"] is False
        assert result["payment_method"] is None


class TestCancel:
    @patch("src.services.subscription_service.StripeClient")
    @patch("src.services.subscription_service.settings")
    def test_cancel_success(self, mock_settings, mock_client, mock_db_session, premium_user):
        mock_settings.STRIPE_SECRET_KEY = "sk_test"
        mock_client.update_subscription.return_value = MagicMock(current_period_end=1735689600)

        result = SubscriptionService.cancel_subscription(mock_db_session, premium_user)

        assert result["status"] == "scheduled_for_cancellation"
        assert result["cancel_at_period_end"] is True
        # Idempotent + sets cancel_at_period_end
        kwargs = mock_client.update_subscription.call_args.kwargs
        assert kwargs["cancel_at_period_end"] is True
        assert "idempotency_key" in kwargs

    @patch("src.services.subscription_service.settings")
    def test_cancel_no_active_subscription(self, mock_settings, mock_db_session, free_user):
        mock_settings.STRIPE_SECRET_KEY = "sk_test"

        with pytest.raises(AppError) as exc:
            SubscriptionService.cancel_subscription(mock_db_session, free_user)
        assert exc.value.code == "NO_ACTIVE_SUBSCRIPTION"


class TestReactivate:
    @patch("src.services.subscription_service.StripeClient")
    @patch("src.services.subscription_service.settings")
    def test_reactivate_success(self, mock_settings, mock_client, mock_db_session, premium_user):
        mock_settings.STRIPE_SECRET_KEY = "sk_test"
        mock_client.update_subscription.return_value = MagicMock(current_period_end=1735689600)

        result = SubscriptionService.reactivate_subscription(mock_db_session, premium_user)

        assert result["status"] == "active"
        assert result["cancel_at_period_end"] is False
        kwargs = mock_client.update_subscription.call_args.kwargs
        assert kwargs["cancel_at_period_end"] is False

    @patch("src.services.subscription_service.settings")
    def test_reactivate_no_active_subscription(self, mock_settings, mock_db_session, free_user):
        mock_settings.STRIPE_SECRET_KEY = "sk_test"

        with pytest.raises(AppError) as exc:
            SubscriptionService.reactivate_subscription(mock_db_session, free_user)
        assert exc.value.code == "NO_ACTIVE_SUBSCRIPTION"


class TestInvoices:
    @patch("src.services.subscription_service.StripeClient")
    @patch("src.services.subscription_service.settings")
    def test_list_invoices_success(self, mock_settings, mock_client, mock_db_session, premium_user):
        mock_settings.STRIPE_SECRET_KEY = "sk_test"
        invoice = MagicMock(
            id="in_1",
            number="0001",
            status="paid",
            amount_paid=999,
            currency="eur",
            created=1735689600,
            hosted_invoice_url="https://stripe.test/inv/1",
            invoice_pdf="https://stripe.test/pdf/1",
        )
        mock_client.list_invoices.return_value = MagicMock(data=[invoice])

        result = SubscriptionService.list_invoices(mock_db_session, premium_user)

        assert len(result) == 1
        assert result[0]["id"] == "in_1"
        assert result[0]["status"] == "paid"
        assert result[0]["created"] is not None

    @patch("src.services.subscription_service.settings")
    def test_list_invoices_no_customer(self, mock_settings, mock_db_session, free_user):
        mock_settings.STRIPE_SECRET_KEY = "sk_test"
        free_user.stripe_customer_id = None
        assert SubscriptionService.list_invoices(mock_db_session, free_user) == []

    @patch("src.services.subscription_service.StripeClient")
    @patch("src.services.subscription_service.settings")
    def test_list_invoices_stripe_error(
        self, mock_settings, mock_client, mock_db_session, premium_user
    ):
        import stripe

        mock_settings.STRIPE_SECRET_KEY = "sk_test"
        mock_client.list_invoices.side_effect = stripe.StripeError("offline")

        with pytest.raises(AppError) as exc:
            SubscriptionService.list_invoices(mock_db_session, premium_user)
        assert exc.value.code == "STRIPE_ERROR"


class TestStartSubscription:
    """Native PaymentSheet flow — replaces the Checkout URL on mobile."""

    @patch("src.services.subscription_service.StripeClient")
    @patch(
        "src.services.stripe_products_service.STRIPE_PRODUCT_IDS",
        {"premium_subscription": "price_123"},
    )
    @patch("src.services.subscription_service.PlanService")
    @patch("src.services.subscription_service.settings")
    def test_returns_client_secret_ephemeral_key_and_customer(
        self, mock_settings, mock_plan_service, mock_client, mock_db_session, free_user
    ):
        """Happy path: Subscription + EphemeralKey created, all 3 secrets returned."""
        mock_settings.STRIPE_SECRET_KEY = "sk_test"
        mock_plan_service.get_plan.return_value = MagicMock(value="FREE")

        # Subscription expanded with latest_invoice.payment_intent.client_secret
        sub = MagicMock(id="sub_999")
        sub.latest_invoice.payment_intent.client_secret = "pi_secret_xyz"
        mock_client.create_subscription.return_value = sub
        mock_client.create_ephemeral_key.return_value = MagicMock(secret="ek_secret_abc")

        result = SubscriptionService.start_subscription(mock_db_session, free_user)

        assert result["subscription_id"] == "sub_999"
        assert result["payment_intent_client_secret"] == "pi_secret_xyz"
        assert result["ephemeral_key"] == "ek_secret_abc"
        assert result["customer"] == "cus_123"
        # Idempotency key is stable per user so a network retry of the same
        # signup doesn't create two subscriptions.
        kwargs = mock_client.create_subscription.call_args.kwargs
        assert kwargs["customer"] == "cus_123"
        assert kwargs["price"] == "price_123"
        assert "idempotency_key" in kwargs

    @patch("src.services.subscription_service.PlanService")
    @patch("src.services.subscription_service.settings")
    def test_already_premium_rejected(
        self, mock_settings, mock_plan_service, mock_db_session, premium_user
    ):
        """A user who's already PREMIUM can't start a second subscription."""
        mock_settings.STRIPE_SECRET_KEY = "sk_test"
        mock_plan_service.get_plan.return_value = MagicMock(value="PREMIUM")

        with pytest.raises(AppError) as exc:
            SubscriptionService.start_subscription(mock_db_session, premium_user)
        assert exc.value.code == "ALREADY_PREMIUM"

    @patch("src.services.subscription_service.PlanService")
    @patch("src.services.subscription_service.settings")
    def test_missing_customer_rejected(
        self, mock_settings, mock_plan_service, mock_db_session, free_user
    ):
        mock_settings.STRIPE_SECRET_KEY = "sk_test"
        mock_plan_service.get_plan.return_value = MagicMock(value="FREE")
        free_user.stripe_customer_id = None

        with pytest.raises(AppError) as exc:
            SubscriptionService.start_subscription(mock_db_session, free_user)
        assert exc.value.code == "STRIPE_CUSTOMER_MISSING"

    @patch("src.services.subscription_service.StripeClient")
    @patch(
        "src.services.stripe_products_service.STRIPE_PRODUCT_IDS",
        {"premium_subscription": "price_123"},
    )
    @patch("src.services.subscription_service.PlanService")
    @patch("src.services.subscription_service.settings")
    def test_subscription_without_client_secret_raises(
        self, mock_settings, mock_plan_service, mock_client, mock_db_session, free_user
    ):
        """Defensive: malformed Stripe response → 500, not silent success."""
        mock_settings.STRIPE_SECRET_KEY = "sk_test"
        mock_plan_service.get_plan.return_value = MagicMock(value="FREE")
        sub = MagicMock(id="sub_999")
        sub.latest_invoice.payment_intent.client_secret = None
        mock_client.create_subscription.return_value = sub
        mock_client.create_ephemeral_key.return_value = MagicMock(secret="ek_x")

        with pytest.raises(AppError) as exc:
            SubscriptionService.start_subscription(mock_db_session, free_user)
        assert exc.value.code == "STRIPE_ERROR"


class TestStartPaymentMethodUpdate:
    """In-app SetupIntent flow — replaces the Stripe Portal "Change card" jump."""

    @patch("src.services.subscription_service.StripeClient")
    @patch("src.services.subscription_service.settings")
    def test_returns_setup_intent_secret_and_ephemeral_key(
        self, mock_settings, mock_client, mock_db_session, premium_user
    ):
        mock_settings.STRIPE_SECRET_KEY = "sk_test"
        mock_client.create_setup_intent.return_value = MagicMock(
            client_secret="seti_secret_xyz"
        )
        mock_client.create_ephemeral_key.return_value = MagicMock(secret="ek_abc")

        result = SubscriptionService.start_payment_method_update(
            mock_db_session, premium_user
        )

        assert result["setup_intent_client_secret"] == "seti_secret_xyz"
        assert result["ephemeral_key"] == "ek_abc"
        assert result["customer"] == "cus_123"

    @patch("src.services.subscription_service.settings")
    def test_missing_customer_rejected(
        self, mock_settings, mock_db_session, free_user
    ):
        mock_settings.STRIPE_SECRET_KEY = "sk_test"
        free_user.stripe_customer_id = None

        with pytest.raises(AppError) as exc:
            SubscriptionService.start_payment_method_update(mock_db_session, free_user)
        assert exc.value.code == "STRIPE_CUSTOMER_MISSING"


class TestAttachDefaultPaymentMethod:
    @patch("stripe.Customer.modify")
    @patch("src.services.subscription_service.StripeClient")
    @patch("src.services.subscription_service.settings")
    def test_updates_customer_and_subscription_defaults(
        self,
        mock_settings,
        mock_client,
        mock_customer_modify,
        mock_db_session,
        premium_user,
    ):
        """Both customer and subscription defaults are updated.

        Customer-level default catches one-off charges and any future
        subscription created without an explicit `default_payment_method`;
        subscription-level default is what the next renewal actually charges.
        """
        mock_settings.STRIPE_SECRET_KEY = "sk_test"

        result = SubscriptionService.attach_default_payment_method(
            mock_db_session, premium_user, "pm_xyz"
        )

        assert result == {"status": "attached"}
        mock_customer_modify.assert_called_once_with(
            "cus_123", invoice_settings={"default_payment_method": "pm_xyz"}
        )
        kwargs = mock_client.update_subscription.call_args.kwargs
        assert kwargs["default_payment_method"] == "pm_xyz"

    @patch("src.services.subscription_service.settings")
    def test_no_active_subscription_rejected(
        self, mock_settings, mock_db_session, free_user
    ):
        mock_settings.STRIPE_SECRET_KEY = "sk_test"

        with pytest.raises(AppError) as exc:
            SubscriptionService.attach_default_payment_method(
                mock_db_session, free_user, "pm_xyz"
            )
        assert exc.value.code == "NO_ACTIVE_SUBSCRIPTION"

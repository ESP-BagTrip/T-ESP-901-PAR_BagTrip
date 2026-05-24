"""Unit tests for SubscriptionService — full Premium lifecycle."""

import uuid
from unittest.mock import AsyncMock, MagicMock, patch

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
    @pytest.mark.asyncio
    @patch("src.services.subscription_service.PlanService")
    async def test_get_status_success(self, mock_plan_service, mock_db_session, free_user):
        mock_plan_service.get_plan_info = AsyncMock(return_value={"plan": "FREE", "limits": {}})

        result = await SubscriptionService.get_status(mock_db_session, free_user)

        assert result["plan"] == "FREE"
        assert result["stripe_subscription_id"] is None
        assert result["plan_expires_at"] is None


class TestSubscriptionDetails:
    """The plan-resolution self-heal lives in ``PlanService.reconcile_plan_with_stripe``
    and is exhaustively covered in ``test_plan_service.py``. These tests focus
    on the Stripe-only fields that this service still owns: cancel state,
    period end, payment method preview."""

    @pytest.mark.asyncio
    @patch("src.services.subscription_service.StripeClient")
    @patch("src.services.subscription_service.PlanService")
    @patch("src.services.subscription_service.settings")
    async def test_details_with_active_subscription(
        self,
        mock_settings,
        mock_plan_service,
        mock_client,
        mock_db_session,
        premium_user,
    ):
        """Active sub: returns cancel state, period end, payment method."""
        mock_settings.STRIPE_SECRET_KEY = "sk_test"
        mock_plan_service.get_plan_info = AsyncMock(return_value={"plan": "PREMIUM"})

        mock_client.retrieve_subscription.return_value = MagicMock(
            cancel_at_period_end=True,
            current_period_end=1735689600,
            default_payment_method="pm_123",
        )
        mock_client.retrieve_payment_method.return_value = MagicMock(
            card=MagicMock(brand="visa", last4="4242", exp_month=12, exp_year=2030)
        )

        result = await SubscriptionService.get_subscription_details(mock_db_session, premium_user)

        assert result["cancel_at_period_end"] is True
        assert result["current_period_end"] is not None
        assert result["payment_method"]["last4"] == "4242"
        assert result["payment_method"]["brand"] == "visa"

    @pytest.mark.asyncio
    @patch("src.services.subscription_service.PlanService")
    @patch("src.services.subscription_service.settings")
    async def test_details_no_subscription(
        self, mock_settings, mock_plan_service, mock_db_session, free_user
    ):
        """Free user: returns base info with empty Stripe-side fields."""
        mock_settings.STRIPE_SECRET_KEY = "sk_test"
        mock_plan_service.get_plan_info = AsyncMock(return_value={"plan": "FREE"})

        result = await SubscriptionService.get_subscription_details(mock_db_session, free_user)

        assert result["cancel_at_period_end"] is False
        assert result["payment_method"] is None

    @pytest.mark.asyncio
    @patch("src.services.subscription_service.StripeClient")
    @patch("src.services.subscription_service.PlanService")
    @patch("src.services.subscription_service.settings")
    async def test_details_falls_back_when_stripe_errors(
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
        mock_plan_service.get_plan_info = AsyncMock(return_value={"plan": "PREMIUM"})
        mock_client.retrieve_subscription.side_effect = stripe.StripeError("offline")

        result = await SubscriptionService.get_subscription_details(mock_db_session, premium_user)

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
    """`/subscription/start` — bootstrap-only with no Stripe write."""

    @patch("stripe.Price.retrieve")
    @patch("src.services.subscription_service.StripeClient")
    @patch(
        "src.services.stripe_products_service.STRIPE_PRODUCT_IDS",
        {"premium_subscription": "price_123"},
    )
    @patch("src.services.subscription_service.PlanService")
    @patch("src.services.subscription_service.settings")
    def test_returns_bootstrap_payload(
        self,
        mock_settings,
        mock_plan_service,
        mock_client,
        mock_price_retrieve,
        mock_db_session,
        free_user,
    ):
        """Happy path: returns customer + ephemeralKey + amount + currency.

        No subscription is created at this stage — that happens in
        `confirm_subscription` after the user actually picks a payment
        method and taps Pay. Eliminates orphan `incomplete` subs.
        """
        mock_settings.STRIPE_SECRET_KEY = "sk_test"
        mock_plan_service.get_plan.return_value = MagicMock(value="FREE")
        mock_price_retrieve.return_value = MagicMock(unit_amount=999, currency="eur")
        mock_client.create_ephemeral_key.return_value = MagicMock(secret="ek_secret_abc")

        result = SubscriptionService.start_subscription(mock_db_session, free_user)

        assert result == {
            "customer": "cus_123",
            "ephemeral_key": "ek_secret_abc",
            "amount": 999,
            "currency": "eur",
        }
        # Critical: no subscription created on the bootstrap call.
        mock_client.create_subscription.assert_not_called()

    @patch("src.services.subscription_service.PlanService")
    @patch("src.services.subscription_service.settings")
    def test_already_premium_rejected(
        self, mock_settings, mock_plan_service, mock_db_session, premium_user
    ):
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


class TestConfirmSubscription:
    """`/subscription/confirm` — creates the Subscription with the chosen PM."""

    @patch("src.services.subscription_service.StripeClient")
    @patch(
        "src.services.stripe_products_service.STRIPE_PRODUCT_IDS",
        {"premium_subscription": "price_123"},
    )
    @patch("src.services.subscription_service.PlanService")
    @patch("src.services.subscription_service.settings")
    def test_creates_subscription_with_payment_method(
        self,
        mock_settings,
        mock_plan_service,
        mock_client,
        mock_db_session,
        free_user,
    ):
        """Happy path: subscription created with PM as default, client_secret returned."""
        mock_settings.STRIPE_SECRET_KEY = "sk_test"
        mock_plan_service.get_plan.return_value = MagicMock(value="FREE")
        sub = MagicMock(id="sub_999")
        sub.latest_invoice.payment_intent.client_secret = "pi_secret_xyz"
        mock_client.create_subscription.return_value = sub

        result = SubscriptionService.confirm_subscription(
            mock_db_session, free_user, "pm_card_visa"
        )

        assert result == {
            "subscription_id": "sub_999",
            "client_secret": "pi_secret_xyz",
        }
        kwargs = mock_client.create_subscription.call_args.kwargs
        assert kwargs["customer"] == "cus_123"
        assert kwargs["price"] == "price_123"
        assert kwargs["default_payment_method"] == "pm_card_visa"
        # Idempotency keys on (user, payment_method) so a network retry
        # of confirm doesn't create a second subscription.
        assert "pm_card_visa" in kwargs["idempotency_key"]

    @patch("src.services.subscription_service.PlanService")
    @patch("src.services.subscription_service.settings")
    def test_already_premium_rejected(
        self, mock_settings, mock_plan_service, mock_db_session, premium_user
    ):
        mock_settings.STRIPE_SECRET_KEY = "sk_test"
        mock_plan_service.get_plan.return_value = MagicMock(value="PREMIUM")

        with pytest.raises(AppError) as exc:
            SubscriptionService.confirm_subscription(mock_db_session, premium_user, "pm_x")
        assert exc.value.code == "ALREADY_PREMIUM"

    @patch("src.services.subscription_service.StripeClient")
    @patch(
        "src.services.stripe_products_service.STRIPE_PRODUCT_IDS",
        {"premium_subscription": "price_123"},
    )
    @patch("src.services.subscription_service.PlanService")
    @patch("src.services.subscription_service.settings")
    def test_missing_client_secret_raises(
        self,
        mock_settings,
        mock_plan_service,
        mock_client,
        mock_db_session,
        free_user,
    ):
        """Defensive: malformed Stripe response → 500, not silent success."""
        mock_settings.STRIPE_SECRET_KEY = "sk_test"
        mock_plan_service.get_plan.return_value = MagicMock(value="FREE")
        sub = MagicMock(id="sub_999")
        sub.latest_invoice.payment_intent.client_secret = None
        mock_client.create_subscription.return_value = sub

        with pytest.raises(AppError) as exc:
            SubscriptionService.confirm_subscription(mock_db_session, free_user, "pm_x")
        assert exc.value.code == "STRIPE_ERROR"

    @patch("src.services.subscription_service.StripeClient")
    @patch(
        "src.services.stripe_products_service.STRIPE_PRODUCT_IDS",
        {"premium_subscription": "price_123"},
    )
    @patch("src.services.subscription_service.PlanService")
    @patch("src.services.subscription_service.settings")
    def test_persists_subscription_id_on_user(
        self,
        mock_settings,
        mock_plan_service,
        mock_client,
        mock_db_session,
        free_user,
    ):
        """Subscription id is persisted on the user immediately, so the
        manage screen self-heals to PREMIUM even if the
        `customer.subscription.created` webhook is delayed (or absent in
        local dev without `stripe listen`)."""
        mock_settings.STRIPE_SECRET_KEY = "sk_test"
        mock_plan_service.get_plan.return_value = MagicMock(value="FREE")
        sub = MagicMock(id="sub_brandnew")
        sub.latest_invoice.payment_intent.client_secret = "pi_secret_xyz"
        mock_client.create_subscription.return_value = sub
        assert free_user.stripe_subscription_id is None

        SubscriptionService.confirm_subscription(mock_db_session, free_user, "pm_card_visa")

        assert free_user.stripe_subscription_id == "sub_brandnew"
        mock_db_session.commit.assert_called()


class TestStartPaymentMethodUpdate:
    """In-app SetupIntent flow — replaces the Stripe Portal "Change card" jump."""

    @patch("src.services.subscription_service.StripeClient")
    @patch("src.services.subscription_service.settings")
    def test_returns_setup_intent_secret_and_ephemeral_key(
        self, mock_settings, mock_client, mock_db_session, premium_user
    ):
        mock_settings.STRIPE_SECRET_KEY = "sk_test"
        mock_client.create_setup_intent.return_value = MagicMock(client_secret="seti_secret_xyz")
        mock_client.create_ephemeral_key.return_value = MagicMock(secret="ek_abc")

        result = SubscriptionService.start_payment_method_update(mock_db_session, premium_user)

        assert result["setup_intent_client_secret"] == "seti_secret_xyz"
        assert result["ephemeral_key"] == "ek_abc"
        assert result["customer"] == "cus_123"

    @patch("src.services.subscription_service.settings")
    def test_missing_customer_rejected(self, mock_settings, mock_db_session, free_user):
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
    def test_no_active_subscription_rejected(self, mock_settings, mock_db_session, free_user):
        mock_settings.STRIPE_SECRET_KEY = "sk_test"

        with pytest.raises(AppError) as exc:
            SubscriptionService.attach_default_payment_method(mock_db_session, free_user, "pm_xyz")
        assert exc.value.code == "NO_ACTIVE_SUBSCRIPTION"


class TestCustomerResolution:
    """`_resolve_customer_id` recovery for stale `stripe_customer_id`.

    Triggered when:
      - the customer was deleted in the Stripe dashboard, or
      - the secret key was switched to a different Stripe workspace
        (common in dev when juggling test accounts).
    """

    @patch("stripe.Price.retrieve")
    @patch("src.services.subscription_service.StripeClient")
    @patch(
        "src.services.stripe_products_service.STRIPE_PRODUCT_IDS",
        {"premium_subscription": "price_123"},
    )
    @patch("src.services.subscription_service.PlanService")
    @patch("src.services.subscription_service.settings")
    def test_recreates_customer_when_missing_then_continues(
        self,
        mock_settings,
        mock_plan_service,
        mock_client,
        mock_price_retrieve,
        mock_db_session,
        free_user,
    ):
        """Stripe says resource_missing → recreate customer + persist + continue."""
        import stripe

        mock_settings.STRIPE_SECRET_KEY = "sk_test"
        mock_plan_service.get_plan.return_value = MagicMock(value="FREE")

        # First retrieve_customer call raises resource_missing.
        missing = stripe.InvalidRequestError("No such customer", "id")
        missing.code = "resource_missing"
        mock_client.retrieve_customer.side_effect = missing

        # create_customer returns the new customer.
        new_customer = MagicMock(id="cus_new_acct")
        mock_client.create_customer.return_value = new_customer

        # Bootstrap path proceeds normally.
        mock_price_retrieve.return_value = MagicMock(unit_amount=999, currency="eur")
        mock_client.create_ephemeral_key.return_value = MagicMock(secret="ek_x")

        result = SubscriptionService.start_subscription(mock_db_session, free_user)

        # Customer was recreated and persisted on the User row.
        assert free_user.stripe_customer_id == "cus_new_acct"
        mock_db_session.commit.assert_called()
        # The bootstrap returns the *new* customer id, not the stale one.
        assert result["customer"] == "cus_new_acct"
        assert result["amount"] == 999
        assert result["currency"] == "eur"
        # Critical: no subscription created — that's the deferred flow's whole point.
        mock_client.create_subscription.assert_not_called()

    @patch("src.services.subscription_service.StripeClient")
    @patch("src.services.subscription_service.PlanService")
    @patch("src.services.subscription_service.settings")
    def test_propagates_other_invalid_request_errors(
        self, mock_settings, mock_plan_service, mock_client, mock_db_session, free_user
    ):
        """A non-resource_missing InvalidRequestError must bubble up unchanged.

        Otherwise a "your account is in a strange state" Stripe error would
        get silently re-mapped to a customer recreation.
        """
        import stripe

        mock_settings.STRIPE_SECRET_KEY = "sk_test"
        mock_plan_service.get_plan.return_value = MagicMock(value="FREE")

        other_error = stripe.InvalidRequestError("Some other problem", "id")
        other_error.code = "parameter_invalid_string_blank"
        mock_client.retrieve_customer.side_effect = other_error

        with pytest.raises(AppError) as exc:
            SubscriptionService.start_subscription(mock_db_session, free_user)
        assert exc.value.code == "STRIPE_ERROR"
        # No customer recreation happened — that error wasn't ours to recover.
        mock_client.create_customer.assert_not_called()

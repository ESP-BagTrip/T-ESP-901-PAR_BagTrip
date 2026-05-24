"""Unit tests for `UserCreationService.create_and_setup_user`.

The service wires three side effects together (insert User → Stripe customer →
claim pending invites) and any of them can fail. These tests pin down:
- Happy path creates the row, attaches the Stripe customer and claims invites
- Stripe failure rolls back and raises AppError
- Invite claim failure does NOT block signup (best-effort)
"""

from __future__ import annotations

from unittest.mock import MagicMock, patch

import pytest

from src.services.user_creation_service import UserCreationService
from src.utils.errors import AppError


class TestCreateAndSetupUser:
    def test_happy_path_creates_user_and_stripe_customer(
        self, mock_db_session, mock_stripe_customer
    ):
        with (
            patch(
                "src.services.user_creation_service.StripeClient.create_customer",
                return_value=mock_stripe_customer,
            ) as mock_create_customer,
            patch(
                "src.services.trip_share_service.TripShareService.claim_pending_invites"
            ) as mock_claim,
        ):
            user = UserCreationService.create_and_setup_user(
                mock_db_session,
                email="new@example.com",
                password_hash="$2b$hash",
                full_name="Alice",
                phone="+33601",
            )

        assert user.email == "new@example.com"
        assert user.password_hash == "$2b$hash"
        assert user.full_name == "Alice"
        assert user.phone == "+33601"
        assert user.stripe_customer_id == mock_stripe_customer.id

        mock_db_session.add.assert_called_once_with(user)
        assert mock_db_session.flush.called
        assert mock_db_session.commit.called
        # Idempotency key is stable per user.id so a network retry of signup
        # that already created a Stripe customer won't duplicate it.
        kwargs = mock_create_customer.call_args.kwargs
        assert kwargs["email"] == "new@example.com"
        assert kwargs["name"] == "Alice"
        assert kwargs["idempotency_key"].startswith("user-")
        assert kwargs["idempotency_key"].endswith("-customer-create-v1")
        mock_claim.assert_called_once()

    def test_stripe_failure_rolls_back_and_raises(self, mock_db_session):
        with (
            patch(
                "src.services.user_creation_service.StripeClient.create_customer",
                side_effect=Exception("Stripe is down"),
            ),
            pytest.raises(AppError) as exc_info,
        ):
            UserCreationService.create_and_setup_user(
                mock_db_session,
                email="fail@example.com",
                password_hash="$2b$hash",
            )

        assert exc_info.value.code == "STRIPE_CUSTOMER_CREATION_FAILED"
        assert exc_info.value.status_code == 503
        assert mock_db_session.rollback.called
        # Invites should NOT be claimed on failure
        # (the call path returns before that)

    def test_invite_claim_failure_does_not_block_signup(
        self, mock_db_session, mock_stripe_customer
    ):
        """Best-effort: invite claim errors are logged but ignored."""
        with (
            patch(
                "src.services.user_creation_service.StripeClient.create_customer",
                return_value=mock_stripe_customer,
            ),
            patch(
                "src.services.trip_share_service.TripShareService.claim_pending_invites",
                side_effect=RuntimeError("db deadlock"),
            ),
        ):
            # Should NOT raise despite the claim failure
            user = UserCreationService.create_and_setup_user(
                mock_db_session,
                email="invited@example.com",
                password_hash="$2b$hash",
            )

        assert user.email == "invited@example.com"
        assert user.stripe_customer_id == mock_stripe_customer.id

    def test_social_signup_with_no_full_name(self, mock_db_session, mock_stripe_customer):
        """Apple users can withhold their name — default None is accepted."""
        with (
            patch(
                "src.services.user_creation_service.StripeClient.create_customer",
                return_value=mock_stripe_customer,
            ) as mock_create_customer,
            patch("src.services.trip_share_service.TripShareService.claim_pending_invites"),
        ):
            user = UserCreationService.create_and_setup_user(
                mock_db_session,
                email="apple@privaterelay.appleid.com",
                password_hash="$2b$dummy",
            )

        assert user.full_name is None
        kwargs = mock_create_customer.call_args.kwargs
        assert kwargs["email"] == "apple@privaterelay.appleid.com"
        assert kwargs["name"] is None
        assert "idempotency_key" in kwargs

    def test_claim_pending_invites_helper_suppresses_errors(self, mock_db_session):
        """`_claim_pending_invites` is a private best-effort helper."""
        user = MagicMock(id="u1", email="test@example.com")
        with patch(
            "src.services.trip_share_service.TripShareService.claim_pending_invites",
            side_effect=Exception("boom"),
        ):
            # Should not raise
            UserCreationService._claim_pending_invites(mock_db_session, user)

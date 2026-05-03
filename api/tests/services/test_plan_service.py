"""Unit tests for `PlanService` — quota enforcement and feature gating."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from src.config.plans import UserPlan
from src.services.plan_service import PlanService
from src.utils.errors import AppError


# ---------------------------------------------------------------------------
# Synchronous resolution / limits / feature gates
# ---------------------------------------------------------------------------


class TestGetPlan:
    """`get_plan()` should resolve the user's plan string to the enum."""

    def test_free_plan(self, make_user):
        user = make_user(plan="FREE")
        assert PlanService.get_plan(user) == UserPlan.FREE

    def test_premium_plan(self, make_user):
        user = make_user(plan="PREMIUM")
        assert PlanService.get_plan(user) == UserPlan.PREMIUM

    def test_admin_plan(self, make_user):
        user = make_user(plan="ADMIN")
        assert PlanService.get_plan(user) == UserPlan.ADMIN

    def test_invalid_plan_falls_back_to_free(self, make_user):
        user = make_user(plan="NONSENSE")
        assert PlanService.get_plan(user) == UserPlan.FREE

    def test_none_plan_falls_back_to_free(self, make_user):
        user = make_user(plan=None)
        assert PlanService.get_plan(user) == UserPlan.FREE


class TestGetLimits:
    def test_free_limits(self, make_user):
        limits = PlanService.get_limits(make_user(plan="FREE"))
        assert limits["ai_generations_per_month"] == 3
        assert limits["viewers_per_trip"] == 2

    def test_premium_limits(self, make_user):
        limits = PlanService.get_limits(make_user(plan="PREMIUM"))
        assert limits["ai_generations_per_month"] is None
        assert limits["viewers_per_trip"] == 10

    def test_admin_limits(self, make_user):
        limits = PlanService.get_limits(make_user(plan="ADMIN"))
        assert limits["viewers_per_trip"] is None  # unlimited


class TestGetShareLimit:
    def test_free_share_limit(self, make_user):
        assert PlanService.get_share_limit(make_user(plan="FREE")) == 2

    def test_premium_share_limit(self, make_user):
        assert PlanService.get_share_limit(make_user(plan="PREMIUM")) == 10

    def test_admin_share_limit_is_unlimited(self, make_user):
        assert PlanService.get_share_limit(make_user(plan="ADMIN")) is None


class TestCanAccessFeature:
    def test_free_cannot_access_post_voyage_ai(self, make_user):
        user = make_user(plan="FREE")
        assert PlanService.can_access_feature(user, "post_voyage_ai") is False

    def test_premium_can_access_post_voyage_ai(self, make_user):
        user = make_user(plan="PREMIUM")
        assert PlanService.can_access_feature(user, "post_voyage_ai") is True

    def test_free_cannot_access_offline_notifications(self, make_user):
        user = make_user(plan="FREE")
        assert PlanService.can_access_feature(user, "offline_notifications") is False

    def test_unknown_feature_returns_true(self, make_user):
        user = make_user(plan="FREE")
        # Unknown feature keys default to True (fail-open for new features).
        assert PlanService.can_access_feature(user, "some_new_feature") is True


# ---------------------------------------------------------------------------
# Async paths — quota / info / increment
# ---------------------------------------------------------------------------


class TestCheckAiGenerationQuota:
    @pytest.mark.asyncio
    async def test_free_user_under_limit_allows(self, make_user, mock_db_session):
        user = make_user(plan="FREE", ai_generations_count=1)
        await PlanService.check_ai_generation_quota(mock_db_session, user)

    @pytest.mark.asyncio
    async def test_free_user_at_limit_raises(self, make_user, mock_db_session):
        user = make_user(plan="FREE", ai_generations_count=3)
        with pytest.raises(AppError) as exc_info:
            await PlanService.check_ai_generation_quota(mock_db_session, user)
        assert exc_info.value.code == "AI_QUOTA_EXCEEDED"
        assert exc_info.value.status_code == 402

    @pytest.mark.asyncio
    async def test_premium_user_bypasses_quota(self, make_user, mock_db_session):
        user = make_user(plan="PREMIUM", ai_generations_count=9999)
        await PlanService.check_ai_generation_quota(mock_db_session, user)

    @pytest.mark.asyncio
    async def test_auto_reset_on_new_month(self, make_user, mock_db_session):
        now = datetime.now(UTC)
        last_month = now - timedelta(days=32)
        user = make_user(
            plan="FREE",
            ai_generations_count=3,
            ai_generations_reset_at=last_month,
        )
        await PlanService.check_ai_generation_quota(mock_db_session, user)
        assert user.ai_generations_count == 0
        assert mock_db_session.commit.called

    @pytest.mark.asyncio
    async def test_no_auto_reset_in_same_month(self, make_user, mock_db_session):
        now = datetime.now(UTC)
        user = make_user(
            plan="FREE",
            ai_generations_count=2,
            ai_generations_reset_at=now,
        )
        await PlanService.check_ai_generation_quota(mock_db_session, user)
        assert user.ai_generations_count == 2

    @pytest.mark.asyncio
    async def test_subscribed_user_with_local_free_is_unlocked_via_self_heal(
        self, make_user, mock_db_session
    ):
        """SMP-324 Stripe-divergence regression: a paid user whose webhook
        is delayed must not be blocked by the FREE quota."""
        user = make_user(
            plan="FREE",
            ai_generations_count=3,
            stripe_subscription_id="sub_X",
        )
        with (
            patch(
                "src.services.plan_service._fetch_subscription_snapshot",
                new=AsyncMock(return_value={"status": "active", "current_period_end": None}),
            ),
            patch("src.services.plan_service.settings.STRIPE_SECRET_KEY", "sk_test"),
        ):
            # Should not raise — reconcile flips the user to PREMIUM.
            await PlanService.check_ai_generation_quota(mock_db_session, user)
        assert user.plan == UserPlan.PREMIUM.value


class TestIncrementAiGeneration:
    def test_increment_from_zero(self, make_user, mock_db_session):
        user = make_user(ai_generations_count=0, ai_generations_reset_at=None)
        PlanService.increment_ai_generation(mock_db_session, user)
        assert user.ai_generations_count == 1
        assert user.ai_generations_reset_at is not None
        assert mock_db_session.commit.called

    def test_increment_preserves_reset_at_when_set(self, make_user, mock_db_session):
        original_reset = datetime.now(UTC)
        user = make_user(ai_generations_count=1, ai_generations_reset_at=original_reset)
        PlanService.increment_ai_generation(mock_db_session, user)
        assert user.ai_generations_count == 2
        assert user.ai_generations_reset_at == original_reset

    def test_increment_handles_none_count(self, make_user, mock_db_session):
        user = make_user(ai_generations_count=None)
        PlanService.increment_ai_generation(mock_db_session, user)
        assert user.ai_generations_count == 1


class TestGetPlanInfo:
    @pytest.mark.asyncio
    async def test_free_user_info(self, make_user, mock_db_session):
        user = make_user(plan="FREE", ai_generations_count=1)
        info = await PlanService.get_plan_info(mock_db_session, user)
        assert info["plan"] == "FREE"
        assert info["ai_generations_remaining"] == 2
        assert info["viewers_per_trip"] == 2
        assert info["post_voyage_ai"] is False

    @pytest.mark.asyncio
    async def test_premium_user_info(self, make_user, mock_db_session):
        user = make_user(plan="PREMIUM", ai_generations_count=42)
        info = await PlanService.get_plan_info(mock_db_session, user)
        assert info["plan"] == "PREMIUM"
        assert info["ai_generations_remaining"] is None
        assert info["viewers_per_trip"] == 10
        assert info["post_voyage_ai"] is True

    @pytest.mark.asyncio
    async def test_info_resets_count_across_month_boundary(self, make_user, mock_db_session):
        last_month = datetime.now(UTC) - timedelta(days=45)
        user = make_user(
            plan="FREE",
            ai_generations_count=3,
            ai_generations_reset_at=last_month,
        )
        info = await PlanService.get_plan_info(mock_db_session, user)
        assert info["ai_generations_remaining"] == 3

    @pytest.mark.asyncio
    async def test_info_handles_none_count(self, make_user, mock_db_session):
        user = make_user(plan="FREE", ai_generations_count=None)
        info = await PlanService.get_plan_info(mock_db_session, user)
        assert info["ai_generations_remaining"] == 3


# ---------------------------------------------------------------------------
# Stripe self-heal cascade
# ---------------------------------------------------------------------------


class TestReconcilePlanWithStripe:
    @pytest.mark.asyncio
    async def test_no_stripe_subscription_returns_local_plan(self, make_user, mock_db_session):
        user = make_user(plan="FREE", stripe_subscription_id=None)
        with patch(
            "src.services.plan_service._fetch_subscription_snapshot",
            new=AsyncMock(),
        ) as fetch:
            result = await PlanService.reconcile_plan_with_stripe(mock_db_session, user)
        assert result == UserPlan.FREE
        fetch.assert_not_called()

    @pytest.mark.asyncio
    async def test_already_premium_short_circuits_without_stripe_call(
        self, make_user, mock_db_session
    ):
        user = make_user(plan="PREMIUM", stripe_subscription_id="sub_X")
        with patch(
            "src.services.plan_service._fetch_subscription_snapshot",
            new=AsyncMock(),
        ) as fetch:
            result = await PlanService.reconcile_plan_with_stripe(mock_db_session, user)
        assert result == UserPlan.PREMIUM
        fetch.assert_not_called()

    @pytest.mark.asyncio
    async def test_admin_short_circuits_without_stripe_call(self, make_user, mock_db_session):
        user = make_user(plan="ADMIN", stripe_subscription_id="sub_X")
        with patch(
            "src.services.plan_service._fetch_subscription_snapshot",
            new=AsyncMock(),
        ) as fetch:
            result = await PlanService.reconcile_plan_with_stripe(mock_db_session, user)
        assert result == UserPlan.ADMIN
        fetch.assert_not_called()

    @pytest.mark.asyncio
    async def test_stripe_active_heals_to_premium_and_persists(self, make_user, mock_db_session):
        user = make_user(plan="FREE", stripe_subscription_id="sub_X")
        period_end = int(datetime(2027, 6, 1, tzinfo=UTC).timestamp())
        with (
            patch(
                "src.services.plan_service._fetch_subscription_snapshot",
                new=AsyncMock(return_value={"status": "active", "current_period_end": period_end}),
            ),
            patch(
                "src.services.plan_service.AuditService.log",
                return_value=MagicMock(),
            ) as audit,
            patch("src.services.plan_service.settings.STRIPE_SECRET_KEY", "sk_test"),
        ):
            result = await PlanService.reconcile_plan_with_stripe(mock_db_session, user)
        assert result == UserPlan.PREMIUM
        assert user.plan == UserPlan.PREMIUM.value
        assert user.plan_expires_at is not None
        assert user.plan_expires_at.year == 2027
        audit.assert_called_once()
        assert audit.call_args.kwargs["action"] == "PLAN_RECONCILED_TO_PREMIUM"

    @pytest.mark.asyncio
    async def test_stripe_canceled_clears_dangling_subscription_id(
        self, make_user, mock_db_session
    ):
        user = make_user(plan="FREE", stripe_subscription_id="sub_X")
        with (
            patch(
                "src.services.plan_service._fetch_subscription_snapshot",
                new=AsyncMock(return_value={"status": "canceled", "current_period_end": None}),
            ),
            patch(
                "src.services.plan_service.AuditService.log",
                return_value=MagicMock(),
            ) as audit,
            patch("src.services.plan_service.settings.STRIPE_SECRET_KEY", "sk_test"),
        ):
            result = await PlanService.reconcile_plan_with_stripe(mock_db_session, user)
        assert result == UserPlan.FREE
        assert user.stripe_subscription_id is None
        audit.assert_called_once()
        assert audit.call_args.kwargs["action"] == "PLAN_RECONCILED_TO_FREE"

    @pytest.mark.asyncio
    async def test_stripe_unreachable_returns_local_plan_unchanged(
        self, make_user, mock_db_session
    ):
        user = make_user(plan="FREE", stripe_subscription_id="sub_X")
        with patch(
            "src.services.plan_service._fetch_subscription_snapshot",
            new=AsyncMock(return_value=None),
        ):
            result = await PlanService.reconcile_plan_with_stripe(mock_db_session, user)
        assert result == UserPlan.FREE
        assert user.plan == "FREE"  # unchanged
        assert user.stripe_subscription_id == "sub_X"  # not cleared

    @pytest.mark.asyncio
    async def test_unknown_stripe_status_does_not_persist(self, make_user, mock_db_session):
        """``incomplete`` / ``paused`` stay as-is — webhook will catch up."""
        user = make_user(plan="FREE", stripe_subscription_id="sub_X")
        with (
            patch(
                "src.services.plan_service._fetch_subscription_snapshot",
                new=AsyncMock(return_value={"status": "incomplete", "current_period_end": None}),
            ),
            patch(
                "src.services.plan_service.AuditService.log",
            ) as audit,
        ):
            result = await PlanService.reconcile_plan_with_stripe(mock_db_session, user)
        assert result == UserPlan.FREE
        # Subscription id is preserved so a later transition catches up.
        assert user.stripe_subscription_id == "sub_X"
        audit.assert_not_called()

"""Unit tests for `PlanService` — quota enforcement and feature gating."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta

import pytest

from src.config.plans import UserPlan
from src.services.plan_service import PlanService
from src.utils.errors import AppError


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


class TestCheckAiGenerationQuota:
    def test_free_user_under_limit_allows(self, make_user, mock_db_session):
        user = make_user(plan="FREE", ai_generations_count=1)
        # Should not raise
        PlanService.check_ai_generation_quota(mock_db_session, user)

    def test_free_user_at_limit_raises(self, make_user, mock_db_session):
        user = make_user(plan="FREE", ai_generations_count=3)
        with pytest.raises(AppError) as exc_info:
            PlanService.check_ai_generation_quota(mock_db_session, user)
        assert exc_info.value.code == "AI_QUOTA_EXCEEDED"
        assert exc_info.value.status_code == 402

    def test_premium_user_bypasses_quota(self, make_user, mock_db_session):
        user = make_user(plan="PREMIUM", ai_generations_count=9999)
        # Unlimited — must not raise even with huge count
        PlanService.check_ai_generation_quota(mock_db_session, user)

    def test_auto_reset_on_new_month(self, make_user, mock_db_session):
        now = datetime.now(UTC)
        last_month = now - timedelta(days=32)  # safely previous month
        user = make_user(
            plan="FREE",
            ai_generations_count=3,
            ai_generations_reset_at=last_month,
        )
        PlanService.check_ai_generation_quota(mock_db_session, user)
        assert user.ai_generations_count == 0
        assert mock_db_session.commit.called

    def test_no_auto_reset_in_same_month(self, make_user, mock_db_session):
        now = datetime.now(UTC)
        user = make_user(
            plan="FREE",
            ai_generations_count=2,
            ai_generations_reset_at=now,
        )
        PlanService.check_ai_generation_quota(mock_db_session, user)
        assert user.ai_generations_count == 2  # unchanged


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


class TestGetPlanInfo:
    def test_free_user_info(self, make_user, mock_db_session):
        user = make_user(plan="FREE", ai_generations_count=1)
        info = PlanService.get_plan_info(mock_db_session, user)
        assert info["plan"] == "FREE"
        assert info["ai_generations_remaining"] == 2
        assert info["viewers_per_trip"] == 2
        assert info["post_voyage_ai"] is False

    def test_premium_user_info(self, make_user, mock_db_session):
        user = make_user(plan="PREMIUM", ai_generations_count=42)
        info = PlanService.get_plan_info(mock_db_session, user)
        assert info["plan"] == "PREMIUM"
        assert info["ai_generations_remaining"] is None  # unlimited
        assert info["viewers_per_trip"] == 10
        assert info["post_voyage_ai"] is True

    def test_info_resets_count_across_month_boundary(self, make_user, mock_db_session):
        last_month = datetime.now(UTC) - timedelta(days=45)
        user = make_user(
            plan="FREE",
            ai_generations_count=3,
            ai_generations_reset_at=last_month,
        )
        info = PlanService.get_plan_info(mock_db_session, user)
        # get_plan_info does NOT commit the reset (read-only), but should
        # compute remaining as if the count were zero.
        assert info["ai_generations_remaining"] == 3

    def test_info_handles_none_count(self, make_user, mock_db_session):
        user = make_user(plan="FREE", ai_generations_count=None)
        info = PlanService.get_plan_info(mock_db_session, user)
        assert info["ai_generations_remaining"] == 3

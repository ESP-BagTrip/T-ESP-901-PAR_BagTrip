"""Unit tests for the small standalone services — `post_trip_ai`, `profile`, `audit`.

These services are <50 LoC each; they share a single test file to keep the
tests/services/ tree from exploding with one-class-one-file boilerplate.
"""

from __future__ import annotations

import uuid
from unittest.mock import MagicMock, patch

import pytest

from src.services.audit_service import AuditService
from src.services.post_trip_ai_service import PostTripAIService
from src.services.profile_service import ProfileService
from src.utils.errors import AppError

# ---------------------------------------------------------------------------
# PostTripAIService
# ---------------------------------------------------------------------------


class TestPostTripAIService:
    def test_suggest_next_trip_raises_when_no_feedback(self, mock_db_session):
        mock_db_session.query.return_value.join.return_value.filter.return_value.order_by.return_value.limit.return_value.all.return_value = []
        with pytest.raises(AppError) as exc:
            PostTripAIService.suggest_next_trip(mock_db_session, uuid.uuid4())
        assert exc.value.code == "NO_FEEDBACK_HISTORY"
        assert exc.value.status_code == 400

    def test_suggest_next_trip_calls_llm_with_history(self, mock_db_session, make_trip):
        trip = make_trip(destination_name="Lisbon", title="City break")
        feedback = MagicMock(
            overall_rating=5,
            highlights="Food, weather",
            lowlights="Crowded",
            would_recommend=True,
        )
        mock_db_session.query.return_value.join.return_value.filter.return_value.order_by.return_value.limit.return_value.all.return_value = [
            (feedback, trip)
        ]

        fake_llm = MagicMock()
        fake_llm.call_llm = MagicMock(
            return_value={"suggestion": {"destination": "Porto", "durationDays": 5}}
        )
        with patch(
            "src.services.post_trip_ai_service.LLMService",
            return_value=fake_llm,
        ):
            result = PostTripAIService.suggest_next_trip(mock_db_session, trip.user_id)

        assert result["suggestion"]["destination"] == "Porto"
        fake_llm.call_llm.assert_called_once()
        # Check the user prompt embeds the feedback
        _, user_prompt = fake_llm.call_llm.call_args.args
        assert "Lisbon" in user_prompt
        assert "5/5" in user_prompt
        assert "Food, weather" in user_prompt

    def test_suggest_handles_missing_highlights(self, mock_db_session, make_trip):
        trip = make_trip(destination_name=None, destination_iata="CDG")
        feedback = MagicMock(
            overall_rating=3,
            highlights=None,
            lowlights=None,
            would_recommend=False,
        )
        mock_db_session.query.return_value.join.return_value.filter.return_value.order_by.return_value.limit.return_value.all.return_value = [
            (feedback, trip)
        ]
        fake_llm = MagicMock()
        fake_llm.call_llm = MagicMock(return_value={"suggestion": {}})
        with patch("src.services.post_trip_ai_service.LLMService", return_value=fake_llm):
            PostTripAIService.suggest_next_trip(mock_db_session, trip.user_id)
        _, user_prompt = fake_llm.call_llm.call_args.args
        # Falls back to destination_iata when destination_name is missing
        assert "CDG" in user_prompt


# ---------------------------------------------------------------------------
# ProfileService
# ---------------------------------------------------------------------------


class TestProfileService:
    def test_get_profile_returns_existing(self, mock_db_session):
        existing = MagicMock()
        mock_db_session.query.return_value.filter.return_value.first.return_value = existing
        result = ProfileService.get_profile(mock_db_session, uuid.uuid4())
        assert result is existing

    def test_get_profile_returns_none_when_missing(self, mock_db_session):
        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        result = ProfileService.get_profile(mock_db_session, uuid.uuid4())
        assert result is None

    def test_create_or_update_creates_new_profile(self, mock_db_session):
        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        profile = ProfileService.create_or_update_profile(
            mock_db_session,
            uuid.uuid4(),
            travel_types=["beach", "nature"],
            travel_style="relaxed",
            budget="mid",
            companions="couple",
        )
        assert mock_db_session.add.called
        assert mock_db_session.commit.called
        assert profile.travel_types == ["beach", "nature"]
        assert profile.is_completed is True

    def test_create_or_update_patches_existing_profile(self, mock_db_session):
        existing = MagicMock(
            travel_types=None,
            travel_style="relaxed",
            budget=None,
            companions=None,
            medical_constraints=None,
            travel_frequency=None,
        )
        mock_db_session.query.return_value.filter.return_value.first.return_value = existing
        ProfileService.create_or_update_profile(
            mock_db_session,
            uuid.uuid4(),
            travel_types=["beach"],
        )
        # Existing row reused; no .add()
        assert not mock_db_session.add.called
        assert existing.travel_types == ["beach"]

    def test_is_completed_false_when_missing_field(self, mock_db_session):
        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        profile = ProfileService.create_or_update_profile(
            mock_db_session,
            uuid.uuid4(),
            travel_types=["beach"],
            travel_style="relaxed",
            budget="mid",
            # companions missing → not completed
        )
        assert profile.is_completed is False

    def test_check_completion_returns_all_missing_when_no_profile(self, mock_db_session):
        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        ok, missing = ProfileService.check_completion(mock_db_session, uuid.uuid4())
        assert ok is False
        assert missing == ["travelTypes", "travelStyle", "budget", "companions"]

    def test_check_completion_returns_partial_missing(self, mock_db_session):
        existing = MagicMock(
            travel_types=["beach"],
            travel_style=None,
            budget="mid",
            companions=None,
        )
        mock_db_session.query.return_value.filter.return_value.first.return_value = existing
        ok, missing = ProfileService.check_completion(mock_db_session, uuid.uuid4())
        assert ok is False
        assert "travelStyle" in missing
        assert "companions" in missing
        assert "travelTypes" not in missing

    def test_check_completion_ok_when_all_fields_set(self, mock_db_session):
        existing = MagicMock(
            travel_types=["beach"],
            travel_style="relaxed",
            budget="mid",
            companions="couple",
        )
        mock_db_session.query.return_value.filter.return_value.first.return_value = existing
        ok, missing = ProfileService.check_completion(mock_db_session, uuid.uuid4())
        assert ok is True
        assert missing == []


# ---------------------------------------------------------------------------
# AuditService
# ---------------------------------------------------------------------------


class TestAuditService:
    def test_log_creates_entry(self, mock_db_session):
        entry = AuditService.log(
            mock_db_session,
            actor_id=uuid.uuid4(),
            action="UPDATE_USER",
            entity_type="user",
            entity_id=uuid.uuid4(),
            diff={"plan": ["FREE", "PREMIUM"]},
            metadata={"source": "admin_panel"},
        )
        assert entry.action == "UPDATE_USER"
        assert entry.diff_json == {"plan": ["FREE", "PREMIUM"]}
        mock_db_session.add.assert_called_once()
        assert mock_db_session.commit.called

    def test_log_without_optional_fields(self, mock_db_session):
        entry = AuditService.log(
            mock_db_session,
            actor_id=uuid.uuid4(),
            action="DELETE_USER",
            entity_type="user",
            entity_id=uuid.uuid4(),
        )
        assert entry.diff_json is None
        assert entry.metadata_ is None

    def test_get_logs_no_filters(self, mock_db_session):
        query = mock_db_session.query.return_value.join.return_value.order_by.return_value
        query.count.return_value = 2
        query.offset.return_value.limit.return_value.all.return_value = [
            (
                MagicMock(
                    id=uuid.uuid4(),
                    actor_id=uuid.uuid4(),
                    action="UPDATE",
                    entity_type="trip",
                    entity_id=uuid.uuid4(),
                    diff_json=None,
                    metadata_=None,
                    created_at=None,
                ),
                "admin@example.com",
            )
            for _ in range(2)
        ]
        items, total, total_pages = AuditService.get_logs(mock_db_session, page=1, limit=20)
        assert total == 2
        assert total_pages == 1
        assert len(items) == 2
        assert items[0]["actor_email"] == "admin@example.com"

    def test_get_logs_applies_filters(self, mock_db_session):
        """With filters, the query chain adds `.filter()` calls — verify they're invoked."""
        query = mock_db_session.query.return_value.join.return_value.order_by.return_value
        query.filter.return_value = query
        query.count.return_value = 0
        query.offset.return_value.limit.return_value.all.return_value = []

        AuditService.get_logs(
            mock_db_session,
            entity_type="user",
            entity_id="abc",
            actor_id="xyz",
            action="BAN",
        )
        # Four optional filters → four `.filter()` calls
        assert query.filter.call_count == 4

    def test_get_logs_pagination_math(self, mock_db_session):
        query = mock_db_session.query.return_value.join.return_value.order_by.return_value
        query.count.return_value = 45
        query.offset.return_value.limit.return_value.all.return_value = []
        _items, total, total_pages = AuditService.get_logs(mock_db_session, page=2, limit=10)
        assert total == 45
        assert total_pages == 5

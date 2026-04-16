"""Unit tests for `FeedbackService`."""

from __future__ import annotations

import uuid
from unittest.mock import MagicMock

import pytest
from sqlalchemy.exc import IntegrityError

from src.models.feedback import Feedback
from src.services.feedback_service import FeedbackService
from src.utils.errors import AppError


class TestCreateFeedback:
    def _make_chains(self, trip, existing=None):
        """Build a db mock where:
        1st query(Trip) → trip
        2nd query(Feedback) → existing
        """
        trip_chain = MagicMock()
        trip_chain.filter.return_value = trip_chain
        trip_chain.first.return_value = trip

        fb_chain = MagicMock()
        fb_chain.filter.return_value = fb_chain
        fb_chain.first.return_value = existing

        db = MagicMock()
        db.query.side_effect = [trip_chain, fb_chain]
        return db

    def test_happy_path(self, make_trip):
        trip = make_trip(status="COMPLETED")
        db = self._make_chains(trip)

        result = FeedbackService.create_feedback(
            db=db,
            trip_id=trip.id,
            user_id=uuid.uuid4(),
            overall_rating=5,
            highlights="Loved it",
            lowlights=None,
            would_recommend=True,
            ai_experience_rating=4,
        )

        assert isinstance(result, Feedback)
        assert result.overall_rating == 5
        assert result.highlights == "Loved it"
        db.add.assert_called_once()
        assert db.commit.called

    def test_trip_not_found(self, mock_db_session):
        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        with pytest.raises(AppError) as exc:
            FeedbackService.create_feedback(
                db=mock_db_session,
                trip_id=uuid.uuid4(),
                user_id=uuid.uuid4(),
                overall_rating=4,
                highlights=None,
                lowlights=None,
                would_recommend=True,
            )
        assert exc.value.code == "TRIP_NOT_COMPLETED"

    def test_trip_not_completed(self, mock_db_session, make_trip):
        trip = make_trip(status="PLANNED")
        mock_db_session.query.return_value.filter.return_value.first.return_value = trip
        with pytest.raises(AppError) as exc:
            FeedbackService.create_feedback(
                db=mock_db_session,
                trip_id=trip.id,
                user_id=uuid.uuid4(),
                overall_rating=4,
                highlights=None,
                lowlights=None,
                would_recommend=True,
            )
        assert exc.value.code == "TRIP_NOT_COMPLETED"

    def test_invalid_rating_low(self, make_trip):
        trip = make_trip(status="COMPLETED")
        db = self._make_chains(trip)
        with pytest.raises(AppError) as exc:
            FeedbackService.create_feedback(
                db=db,
                trip_id=trip.id,
                user_id=uuid.uuid4(),
                overall_rating=0,
                highlights=None,
                lowlights=None,
                would_recommend=True,
            )
        assert exc.value.code == "INVALID_RATING"

    def test_invalid_rating_high(self, make_trip):
        trip = make_trip(status="COMPLETED")
        db = self._make_chains(trip)
        with pytest.raises(AppError) as exc:
            FeedbackService.create_feedback(
                db=db,
                trip_id=trip.id,
                user_id=uuid.uuid4(),
                overall_rating=6,
                highlights=None,
                lowlights=None,
                would_recommend=True,
            )
        assert exc.value.code == "INVALID_RATING"

    def test_existing_feedback_raises_conflict(self, make_trip):
        trip = make_trip(status="COMPLETED")
        existing = Feedback(
            trip_id=trip.id,
            user_id=uuid.uuid4(),
            overall_rating=5,
            would_recommend=True,
        )
        db = self._make_chains(trip, existing=existing)

        with pytest.raises(AppError) as exc:
            FeedbackService.create_feedback(
                db=db,
                trip_id=trip.id,
                user_id=uuid.uuid4(),
                overall_rating=5,
                highlights=None,
                lowlights=None,
                would_recommend=True,
            )
        assert exc.value.code == "FEEDBACK_EXISTS"
        assert exc.value.status_code == 409

    def test_integrity_error_rolls_back(self, make_trip):
        trip = make_trip(status="COMPLETED")
        db = self._make_chains(trip)
        db.commit.side_effect = IntegrityError("stmt", {}, Exception("dup"))

        with pytest.raises(AppError) as exc:
            FeedbackService.create_feedback(
                db=db,
                trip_id=trip.id,
                user_id=uuid.uuid4(),
                overall_rating=4,
                highlights=None,
                lowlights=None,
                would_recommend=True,
            )
        assert exc.value.code == "FEEDBACK_EXISTS"
        assert db.rollback.called


class TestGetFeedbacksByTrip:
    def test_returns_list(self, mock_db_session):
        fbs = [
            Feedback(
                trip_id=uuid.uuid4(), user_id=uuid.uuid4(), overall_rating=5, would_recommend=True
            )
        ]
        mock_db_session.query.return_value.filter.return_value.order_by.return_value.all.return_value = fbs
        result = FeedbackService.get_feedbacks_by_trip(mock_db_session, uuid.uuid4())
        assert result == fbs


class TestGetUserFeedback:
    def test_returns_feedback_or_none(self, mock_db_session):
        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        assert (
            FeedbackService.get_user_feedback(mock_db_session, uuid.uuid4(), uuid.uuid4()) is None
        )

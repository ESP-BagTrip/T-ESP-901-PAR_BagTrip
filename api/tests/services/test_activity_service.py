"""Unit tests for `ActivityService`."""

from __future__ import annotations

import uuid
from datetime import date, time
from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from src.models.activity import Activity
from src.services.activity_service import ActivityService
from src.utils.errors import AppError


class TestCreate:
    def test_happy_path(self, mock_db_session, make_trip):
        trip = make_trip(status="PLANNED")
        activity = ActivityService.create(
            db=mock_db_session,
            trip=trip,
            title="Visit Sagrada",
            date=date(2026, 5, 1),
            description="Cathedral",
            start_time=time(10, 0),
            end_time=time(12, 0),
            location="Barcelona",
            category="CULTURE",
            estimated_cost=25.0,
            is_booked=False,
            validation_status="MANUAL",
        )

        assert isinstance(activity, Activity)
        assert activity.title == "Visit Sagrada"
        assert activity.trip_id == trip.id
        mock_db_session.add.assert_called_once()
        assert mock_db_session.commit.called

    def test_blocked_on_completed_trip(self, mock_db_session, make_trip):
        trip = make_trip(status="COMPLETED")
        with pytest.raises(AppError) as exc:
            ActivityService.create(db=mock_db_session, trip=trip, title="X", date=date.today())
        assert exc.value.code == "TRIP_COMPLETED"
        assert exc.value.status_code == 403


class TestGetByTrip:
    def test_returns_list(self, mock_db_session, make_activity):
        acts = [make_activity(), make_activity()]
        mock_db_session.query.return_value.filter.return_value.order_by.return_value.all.return_value = acts
        result = ActivityService.get_by_trip(mock_db_session, uuid.uuid4())
        assert result == acts


class TestGetByTripPaginated:
    def test_pagination_math(self, make_activity):
        items = [make_activity() for _ in range(5)]

        chain = MagicMock()
        chain.filter.return_value = chain
        chain.order_by.return_value = chain
        chain.count.return_value = 42
        chain.offset.return_value.limit.return_value.all.return_value = items

        db = MagicMock()
        db.query.return_value = chain

        result_items, total, total_pages = ActivityService.get_by_trip_paginated(
            db, uuid.uuid4(), page=2, limit=20
        )
        assert result_items == items
        assert total == 42
        assert total_pages == 3  # ceil(42/20)
        chain.offset.assert_called_with(20)

    def test_zero_limit_returns_zero_pages(self, make_activity):
        chain = MagicMock()
        chain.filter.return_value = chain
        chain.order_by.return_value = chain
        chain.count.return_value = 10
        chain.offset.return_value.limit.return_value.all.return_value = []

        db = MagicMock()
        db.query.return_value = chain

        _, _, total_pages = ActivityService.get_by_trip_paginated(db, uuid.uuid4(), page=1, limit=0)
        assert total_pages == 0


class TestGetById:
    def test_returns_activity(self, mock_db_session, make_activity):
        act = make_activity()
        mock_db_session.query.return_value.filter.return_value.first.return_value = act
        result = ActivityService.get_by_id(mock_db_session, act.id, act.trip_id)
        assert result is act

    def test_not_found(self, mock_db_session):
        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        with pytest.raises(AppError) as exc:
            ActivityService.get_by_id(mock_db_session, uuid.uuid4(), uuid.uuid4())
        assert exc.value.code == "ACTIVITY_NOT_FOUND"
        assert exc.value.status_code == 404


class TestUpdate:
    def test_applies_fields(self, mock_db_session, make_trip, make_activity):
        trip = make_trip(status="PLANNED")
        act = make_activity(trip_id=trip.id)
        mock_db_session.query.return_value.filter.return_value.first.return_value = act

        result = ActivityService.update(
            db=mock_db_session,
            trip=trip,
            activity_id=act.id,
            title="New title",
            description="New desc",
            date=date(2026, 6, 1),
            start_time=time(9, 0),
            end_time=time(11, 0),
            location="Paris",
            category="FOOD",
            estimated_cost=99.0,
            is_booked=True,
            validation_status="VALIDATED",
        )

        assert result.title == "New title"
        assert result.description == "New desc"
        assert result.category == "FOOD"
        assert result.estimated_cost == 99.0
        assert result.is_booked is True
        assert mock_db_session.commit.called

    def test_blocked_on_completed_trip(self, mock_db_session, make_trip):
        trip = make_trip(status="COMPLETED")
        with pytest.raises(AppError) as exc:
            ActivityService.update(
                db=mock_db_session, trip=trip, activity_id=uuid.uuid4(), title="X"
            )
        assert exc.value.code == "TRIP_COMPLETED"


class TestDelete:
    def test_happy_path(self, mock_db_session, make_trip, make_activity):
        trip = make_trip(status="PLANNED")
        act = make_activity(trip_id=trip.id)
        mock_db_session.query.return_value.filter.return_value.first.return_value = act

        ActivityService.delete(mock_db_session, trip, act.id)

        mock_db_session.delete.assert_called_once_with(act)
        assert mock_db_session.commit.called

    def test_blocked_on_completed_trip(self, mock_db_session, make_trip):
        trip = make_trip(status="COMPLETED")
        with pytest.raises(AppError) as exc:
            ActivityService.delete(mock_db_session, trip, uuid.uuid4())
        assert exc.value.code == "TRIP_COMPLETED"

    def test_not_found_raises(self, mock_db_session, make_trip):
        trip = make_trip(status="PLANNED")
        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        with pytest.raises(AppError) as exc:
            ActivityService.delete(mock_db_session, trip, uuid.uuid4())
        assert exc.value.code == "ACTIVITY_NOT_FOUND"


class TestBatchUpdate:
    def test_applies_updates_to_each_activity(self, mock_db_session, make_trip, make_activity):
        trip = make_trip(status="PLANNED")
        a1 = make_activity(trip_id=trip.id)
        a2 = make_activity(trip_id=trip.id)

        mock_db_session.query.return_value.filter.return_value.first.side_effect = [a1, a2]

        updates = SimpleNamespace(
            title="Batch",
            description=None,
            date=None,
            startTime=None,
            endTime=None,
            location=None,
            category="CULTURE",
            estimatedCost=None,
            isBooked=True,
            validationStatus=None,
        )

        results = ActivityService.batch_update(
            db=mock_db_session, trip=trip, activity_ids=[a1.id, a2.id], updates=updates
        )
        assert len(results) == 2
        assert all(a.title == "Batch" for a in results)
        assert all(a.category == "CULTURE" for a in results)
        assert all(a.is_booked is True for a in results)
        assert mock_db_session.commit.called

    def test_blocked_on_completed_trip(self, mock_db_session, make_trip):
        trip = make_trip(status="COMPLETED")
        updates = SimpleNamespace(
            title=None,
            description=None,
            date=None,
            startTime=None,
            endTime=None,
            location=None,
            category=None,
            estimatedCost=None,
            isBooked=None,
            validationStatus=None,
        )
        with pytest.raises(AppError) as exc:
            ActivityService.batch_update(
                db=mock_db_session, trip=trip, activity_ids=[uuid.uuid4()], updates=updates
            )
        assert exc.value.code == "TRIP_COMPLETED"


class TestSuggest:
    @pytest.mark.asyncio
    async def test_returns_activities_from_llm(self, mock_db_session, make_trip):
        trip = make_trip(
            destination_name="Barcelona",
            start_date=date(2026, 5, 1),
            end_date=date(2026, 5, 5),
            nb_travelers=2,
        )
        fake_llm = MagicMock()
        fake_llm.acall_llm = AsyncMock(return_value={"activities": [{"title": "A"}]})

        with patch("src.services.llm_service.LLMService", return_value=fake_llm):
            result = await ActivityService.suggest(mock_db_session, trip, day=1)

        assert result == [{"title": "A"}]
        fake_llm.acall_llm.assert_awaited_once()

    @pytest.mark.asyncio
    async def test_llm_error_returns_empty(self, mock_db_session, make_trip):
        trip = make_trip(destination_name="Paris")
        fake_llm = MagicMock()
        fake_llm.acall_llm = AsyncMock(side_effect=RuntimeError("boom"))

        with patch("src.services.llm_service.LLMService", return_value=fake_llm):
            result = await ActivityService.suggest(mock_db_session, trip)

        assert result == []

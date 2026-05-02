"""Unit tests for `BudgetItemService`."""

from __future__ import annotations

import uuid
from datetime import date
from unittest.mock import MagicMock

import pytest

from src.models.budget_item import BudgetItem
from src.services.budget_item_service import BudgetItemService
from src.utils.errors import AppError


class TestCreate:
    def test_happy_path(self, mock_db_session, make_trip):
        trip = make_trip(status="PLANNED")
        item = BudgetItemService.create(
            db=mock_db_session,
            trip=trip,
            label="Lunch",
            amount=25.0,
            category="FOOD",
            date=date(2026, 5, 2),
            is_planned=True,
        )
        assert isinstance(item, BudgetItem)
        assert item.label == "Lunch"
        assert item.amount == 25.0
        mock_db_session.add.assert_called_once()
        assert mock_db_session.commit.called

    def test_blocked_on_completed_trip(self, mock_db_session, make_trip):
        trip = make_trip(status="COMPLETED")
        with pytest.raises(AppError) as exc:
            BudgetItemService.create(db=mock_db_session, trip=trip, label="X", amount=1.0)
        assert exc.value.code == "TRIP_COMPLETED"


class TestFindBySource:
    def test_returns_match(self, mock_db_session):
        bi = BudgetItem(trip_id=uuid.uuid4(), label="x", amount=1)
        mock_db_session.query.return_value.filter.return_value.first.return_value = bi
        result = BudgetItemService.find_by_source(mock_db_session, "accommodation", uuid.uuid4())
        assert result is bi

    def test_returns_none_on_miss(self, mock_db_session):
        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        assert BudgetItemService.find_by_source(mock_db_session, "activity", uuid.uuid4()) is None


class TestGetByTrip:
    def test_returns_list(self, mock_db_session):
        items = [BudgetItem(trip_id=uuid.uuid4(), label="x", amount=1)]
        mock_db_session.query.return_value.filter.return_value.order_by.return_value.all.return_value = items
        assert BudgetItemService.get_by_trip(mock_db_session, uuid.uuid4()) == items


class TestGetById:
    def test_not_found(self, mock_db_session):
        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        with pytest.raises(AppError) as exc:
            BudgetItemService.get_by_id(mock_db_session, uuid.uuid4(), uuid.uuid4())
        assert exc.value.code == "BUDGET_ITEM_NOT_FOUND"

    def test_returns_item(self, mock_db_session):
        bi = BudgetItem(trip_id=uuid.uuid4(), label="x", amount=1)
        mock_db_session.query.return_value.filter.return_value.first.return_value = bi
        assert BudgetItemService.get_by_id(mock_db_session, uuid.uuid4(), uuid.uuid4()) is bi


class TestUpdate:
    def test_applies_fields(self, mock_db_session, make_trip):
        trip = make_trip(status="PLANNED")
        bi = BudgetItem(trip_id=trip.id, label="old", amount=1, is_planned=True)
        mock_db_session.query.return_value.filter.return_value.first.return_value = bi

        result = BudgetItemService.update(
            db=mock_db_session,
            trip=trip,
            item_id=uuid.uuid4(),
            label="new",
            amount=50.0,
            category="FOOD",
            date=date(2026, 1, 1),
            is_planned=False,
        )

        assert result.label == "new"
        assert result.amount == 50.0
        assert result.category == "FOOD"
        assert result.is_planned is False
        assert mock_db_session.commit.called

    def test_blocked_on_completed_trip(self, mock_db_session, make_trip):
        trip = make_trip(status="COMPLETED")
        with pytest.raises(AppError) as exc:
            BudgetItemService.update(db=mock_db_session, trip=trip, item_id=uuid.uuid4(), label="x")
        assert exc.value.code == "TRIP_COMPLETED"


class TestDelete:
    def test_happy_path(self, mock_db_session, make_trip):
        trip = make_trip(status="PLANNED")
        bi = BudgetItem(trip_id=trip.id, label="x", amount=1)
        mock_db_session.query.return_value.filter.return_value.first.return_value = bi

        BudgetItemService.delete(mock_db_session, trip, bi.id)

        mock_db_session.delete.assert_called_once_with(bi)
        assert mock_db_session.commit.called

    def test_blocked_on_completed_trip(self, mock_db_session, make_trip):
        trip = make_trip(status="COMPLETED")
        with pytest.raises(AppError) as exc:
            BudgetItemService.delete(mock_db_session, trip, uuid.uuid4())
        assert exc.value.code == "TRIP_COMPLETED"


class TestGetBudgetSummary:
    def _build_db(self, items, activities):
        """Chain 1: BudgetItem query, Chain 2: Activity query."""
        budget_chain = MagicMock()
        budget_chain.filter.return_value = budget_chain
        budget_chain.order_by.return_value = budget_chain
        budget_chain.all.return_value = items

        activity_chain = MagicMock()
        activity_chain.filter.return_value = activity_chain
        activity_chain.all.return_value = activities

        db = MagicMock()
        db.query.side_effect = [budget_chain, activity_chain]
        return db

    def test_danger_alert_when_over_budget(self, make_trip, make_activity):
        trip = make_trip(budget_target=100.0)
        items = [
            BudgetItem(
                trip_id=trip.id,
                label="A",
                amount=150.0,
                category="FOOD",
                is_planned=True,
                source_type=None,
            )
        ]
        db = self._build_db(items, [])

        summary = BudgetItemService.get_budget_summary(db, trip)

        assert summary["total_spent"] == 150.0
        assert summary["alert_level"] == "DANGER"
        assert "exceeded" in summary["alert_message"]
        assert summary["remaining"] == -50.0

    def test_warning_alert_at_80_percent(self, make_trip):
        trip = make_trip(budget_target=100.0)
        items = [
            BudgetItem(
                trip_id=trip.id,
                label="A",
                amount=85.0,
                category="FOOD",
                is_planned=True,
                source_type=None,
            )
        ]
        db = self._build_db(items, [])

        summary = BudgetItemService.get_budget_summary(db, trip)
        assert summary["alert_level"] == "WARNING"

    def test_no_alert_under_threshold(self, make_trip):
        trip = make_trip(budget_target=100.0)
        items = [
            BudgetItem(
                trip_id=trip.id,
                label="A",
                amount=10.0,
                category="FOOD",
                is_planned=True,
                source_type=None,
            )
        ]
        db = self._build_db(items, [])

        summary = BudgetItemService.get_budget_summary(db, trip)
        assert summary["alert_level"] is None

    def test_no_budget_total_gives_no_alert(self, make_trip):
        trip = make_trip(budget_target=None)
        db = self._build_db([], [])
        summary = BudgetItemService.get_budget_summary(db, trip)
        assert summary["alert_level"] is None
        assert summary["total_budget"] == 0.0

    def test_confirmed_vs_forecasted_split(self, make_trip, make_activity):
        trip = make_trip(budget_target=500.0)
        items = [
            # confirmed (source_type set)
            BudgetItem(
                trip_id=trip.id,
                label="hotel",
                amount=100.0,
                category="ACCOMMODATION",
                is_planned=True,
                source_type="accommodation",
            ),
            # forecasted (planned + no source)
            BudgetItem(
                trip_id=trip.id,
                label="tip",
                amount=20.0,
                category="FOOD",
                is_planned=True,
                source_type=None,
            ),
            # confirmed (not planned)
            BudgetItem(
                trip_id=trip.id,
                label="snack",
                amount=5.0,
                category="FOOD",
                is_planned=False,
                source_type=None,
            ),
        ]
        validated_act = make_activity(
            trip_id=trip.id, estimated_cost=30.0, validation_status="VALIDATED"
        )
        suggested_act = make_activity(
            trip_id=trip.id, estimated_cost=40.0, validation_status="SUGGESTED"
        )
        no_cost_act = make_activity(
            trip_id=trip.id, estimated_cost=None, validation_status="MANUAL"
        )

        db = self._build_db(items, [validated_act, suggested_act, no_cost_act])

        summary = BudgetItemService.get_budget_summary(db, trip)

        # confirmed: 100 (source) + 5 (not planned) + 30 (validated activity) = 135
        assert summary["confirmed_total"] == 135.0
        # forecasted: 20 (planned+no source) + 40 (suggested activity) = 60
        assert summary["forecasted_total"] == 60.0
        assert summary["total_spent"] == 125.0  # budget items only
        assert summary["by_category"]["ACCOMMODATION"] == 100.0
        assert summary["by_category"]["FOOD"] == 25.0

"""Unit tests for `BaggageItemsService`."""

from __future__ import annotations

import uuid
from datetime import date
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from src.models.baggage_item import BaggageItem
from src.services.baggage_items_service import BaggageItemsService, _default_baggage_items
from src.utils.errors import AppError


class TestCreateBaggageItem:
    def test_happy_path(self, mock_db_session, make_trip):
        trip = make_trip(status="PLANNED")
        item = BaggageItemsService.create_baggage_item(
            db=mock_db_session,
            trip=trip,
            name="Passport",
            quantity=1,
            is_packed=False,
            category="DOCUMENTS",
            notes="main",
        )
        assert isinstance(item, BaggageItem)
        assert item.name == "Passport"
        mock_db_session.add.assert_called_once()
        assert mock_db_session.commit.called

    def test_blocked_on_completed_trip(self, mock_db_session, make_trip):
        trip = make_trip(status="COMPLETED")
        with pytest.raises(AppError) as exc:
            BaggageItemsService.create_baggage_item(db=mock_db_session, trip=trip, name="X")
        assert exc.value.code == "TRIP_COMPLETED"


class TestGetters:
    def test_get_by_trip(self, mock_db_session):
        items = [BaggageItem(trip_id=uuid.uuid4(), name="x")]
        mock_db_session.query.return_value.filter.return_value.all.return_value = items
        assert BaggageItemsService.get_baggage_items_by_trip(mock_db_session, uuid.uuid4()) == items

    def test_get_by_id_none(self, mock_db_session):
        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        assert (
            BaggageItemsService.get_baggage_item_by_id(mock_db_session, uuid.uuid4(), uuid.uuid4())
            is None
        )


class TestUpdate:
    def test_happy_path(self, mock_db_session, make_trip):
        trip = make_trip(status="PLANNED")
        item = BaggageItem(trip_id=trip.id, name="old")
        mock_db_session.query.return_value.filter.return_value.first.return_value = item

        result = BaggageItemsService.update_baggage_item(
            db=mock_db_session,
            baggage_item_id=uuid.uuid4(),
            trip=trip,
            name="new",
            quantity=3,
            is_packed=True,
            category="CLOTHING",
            notes="packed",
        )
        assert result.name == "new"
        assert result.quantity == 3
        assert result.is_packed is True
        assert result.category == "CLOTHING"
        assert mock_db_session.commit.called

    def test_not_found(self, mock_db_session, make_trip):
        trip = make_trip(status="PLANNED")
        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        with pytest.raises(AppError) as exc:
            BaggageItemsService.update_baggage_item(
                db=mock_db_session, baggage_item_id=uuid.uuid4(), trip=trip, name="x"
            )
        assert exc.value.code == "BAGGAGE_ITEM_NOT_FOUND"

    def test_blocked_on_completed_trip(self, mock_db_session, make_trip):
        trip = make_trip(status="COMPLETED")
        with pytest.raises(AppError) as exc:
            BaggageItemsService.update_baggage_item(
                db=mock_db_session, baggage_item_id=uuid.uuid4(), trip=trip, name="x"
            )
        assert exc.value.code == "TRIP_COMPLETED"


class TestDelete:
    def test_happy_path(self, mock_db_session, make_trip):
        trip = make_trip(status="PLANNED")
        item = BaggageItem(trip_id=trip.id, name="x")
        mock_db_session.query.return_value.filter.return_value.first.return_value = item

        BaggageItemsService.delete_baggage_item(mock_db_session, uuid.uuid4(), trip)

        mock_db_session.delete.assert_called_once_with(item)
        assert mock_db_session.commit.called

    def test_not_found(self, mock_db_session, make_trip):
        trip = make_trip(status="PLANNED")
        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        with pytest.raises(AppError) as exc:
            BaggageItemsService.delete_baggage_item(mock_db_session, uuid.uuid4(), trip)
        assert exc.value.code == "BAGGAGE_ITEM_NOT_FOUND"

    def test_blocked_on_completed_trip(self, mock_db_session, make_trip):
        trip = make_trip(status="COMPLETED")
        with pytest.raises(AppError) as exc:
            BaggageItemsService.delete_baggage_item(mock_db_session, uuid.uuid4(), trip)
        assert exc.value.code == "TRIP_COMPLETED"


class TestDefaultItemsFallback:
    def test_returns_canonical_list(self):
        items = _default_baggage_items()
        assert len(items) >= 4
        assert any(i["name"] == "Passport" for i in items)


class TestSuggest:
    @pytest.mark.asyncio
    async def test_dedups_against_existing(self, mock_db_session, make_trip):
        trip = make_trip(
            destination_name="Barcelona",
            start_date=date(2026, 5, 1),
            end_date=date(2026, 5, 5),
            nb_travelers=2,
        )
        trip.activities = []

        existing = [BaggageItem(trip_id=trip.id, name="Passport")]
        mock_db_session.query.return_value.filter.return_value.all.return_value = existing

        fake_llm = MagicMock()
        fake_llm.acall_llm = AsyncMock(
            return_value={
                "items": [
                    {"name": "Passport", "quantity": 1},
                    {"name": "Camera", "quantity": 1},
                ]
            }
        )

        with patch("src.services.llm_service.LLMService", return_value=fake_llm):
            result = await BaggageItemsService.suggest_baggage_items(mock_db_session, trip)

        names = [i["name"] for i in result]
        assert "Passport" not in names
        assert "Camera" in names

    @pytest.mark.asyncio
    async def test_llm_failure_uses_fallback(self, mock_db_session, make_trip):
        trip = make_trip(destination_name="Paris")
        trip.activities = []
        mock_db_session.query.return_value.filter.return_value.all.return_value = []

        fake_llm = MagicMock()
        fake_llm.acall_llm = AsyncMock(side_effect=RuntimeError("boom"))

        with patch("src.services.llm_service.LLMService", return_value=fake_llm):
            result = await BaggageItemsService.suggest_baggage_items(mock_db_session, trip)

        # Fallback is returned and nothing is deduped
        assert len(result) >= 4

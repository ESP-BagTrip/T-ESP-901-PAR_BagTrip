"""Unit tests for `AccommodationsService`."""

from __future__ import annotations

import uuid
from datetime import date, datetime
from decimal import Decimal
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from src.models.accommodation import Accommodation
from src.models.budget_item import BudgetItem
from src.services.accommodations_service import AccommodationsService
from src.utils.errors import AppError


class TestCreateAccommodation:
    def test_happy_path_with_price_creates_budget_item(self, mock_db_session, make_trip):
        trip = make_trip(status="PLANNED")
        check_in = datetime(2026, 5, 1)
        check_out = datetime(2026, 5, 4)

        acc = AccommodationsService.create_accommodation(
            db=mock_db_session,
            trip=trip,
            name="Hotel Arts",
            address="123 Street",
            check_in=check_in,
            check_out=check_out,
            price_per_night=Decimal("100"),
            currency="EUR",
        )

        assert isinstance(acc, Accommodation)
        assert acc.name == "Hotel Arts"
        # 2 db.add calls: accommodation + budget_item (3 nights × 100)
        assert mock_db_session.add.call_count == 2

    def test_happy_path_without_price(self, mock_db_session, make_trip):
        trip = make_trip(status="PLANNED")
        AccommodationsService.create_accommodation(
            db=mock_db_session, trip=trip, name="Hostel", price_per_night=None
        )
        assert mock_db_session.add.call_count == 1

    def test_blocked_on_completed_trip(self, mock_db_session, make_trip):
        trip = make_trip(status="COMPLETED")
        with pytest.raises(AppError) as exc:
            AccommodationsService.create_accommodation(db=mock_db_session, trip=trip, name="X")
        assert exc.value.code == "TRIP_COMPLETED"


class TestCalcNights:
    def test_uses_date_difference(self):
        nights = AccommodationsService._calc_nights(datetime(2026, 5, 1), datetime(2026, 5, 4))
        assert nights == 3

    def test_date_types_supported(self):
        nights = AccommodationsService._calc_nights(date(2026, 5, 1), date(2026, 5, 3))
        assert nights == 2

    def test_returns_1_on_none_or_invalid(self):
        assert AccommodationsService._calc_nights(None, None) == 1
        assert AccommodationsService._calc_nights(datetime(2026, 5, 5), datetime(2026, 5, 1)) == 1


class TestGetters:
    def test_get_by_trip(self, mock_db_session):
        items = [Accommodation(trip_id=uuid.uuid4(), name="x")]
        mock_db_session.query.return_value.filter.return_value.all.return_value = items
        assert (
            AccommodationsService.get_accommodations_by_trip(mock_db_session, uuid.uuid4()) == items
        )

    def test_get_by_id_returns_none(self, mock_db_session):
        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        assert (
            AccommodationsService.get_accommodation_by_id(
                mock_db_session, uuid.uuid4(), uuid.uuid4()
            )
            is None
        )


class TestUpdateAccommodation:
    def test_not_found(self, mock_db_session, make_trip):
        trip = make_trip(status="PLANNED")
        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        with pytest.raises(AppError) as exc:
            AccommodationsService.update_accommodation(
                db=mock_db_session, accommodation_id=uuid.uuid4(), trip=trip, name="X"
            )
        assert exc.value.code == "ACCOMMODATION_NOT_FOUND"

    def test_blocked_on_completed_trip(self, mock_db_session, make_trip):
        trip = make_trip(status="COMPLETED")
        with pytest.raises(AppError) as exc:
            AccommodationsService.update_accommodation(
                db=mock_db_session, accommodation_id=uuid.uuid4(), trip=trip
            )
        assert exc.value.code == "TRIP_COMPLETED"

    def test_updates_fields_and_syncs_existing_budget_item(self, mock_db_session, make_trip):
        trip = make_trip(status="PLANNED")
        acc = Accommodation(
            trip_id=trip.id,
            name="old",
            price_per_night=Decimal("100"),
            check_in=datetime(2026, 5, 1),
            check_out=datetime(2026, 5, 4),
        )
        linked = BudgetItem(trip_id=trip.id, label="old", amount=Decimal("300"))
        mock_db_session.query.return_value.filter.return_value.first.return_value = acc

        with patch(
            "src.services.accommodations_service.BudgetItemService.find_by_source",
            return_value=linked,
        ):
            result = AccommodationsService.update_accommodation(
                db=mock_db_session,
                accommodation_id=acc.id,
                trip=trip,
                name="New Hotel",
                address="New Addr",
                check_in=datetime(2026, 5, 2),
                check_out=datetime(2026, 5, 5),
                price_per_night=Decimal("150"),
                currency="USD",
                booking_reference="B123",
                notes="notes",
            )

        assert result.name == "New Hotel"
        assert result.price_per_night == Decimal("150")
        assert "New Hotel" in linked.label
        assert linked.amount == Decimal("450")  # 3 nights × 150

    def test_price_cleared_deletes_linked_item(self, mock_db_session, make_trip):
        trip = make_trip(status="PLANNED")
        acc = Accommodation(trip_id=trip.id, name="x", price_per_night=Decimal("100"))
        linked = BudgetItem(trip_id=trip.id, label="x", amount=Decimal("100"))
        mock_db_session.query.return_value.filter.return_value.first.return_value = acc

        with patch(
            "src.services.accommodations_service.BudgetItemService.find_by_source",
            return_value=linked,
        ):
            AccommodationsService.update_accommodation(
                db=mock_db_session,
                accommodation_id=acc.id,
                trip=trip,
                price_explicitly_cleared=True,
            )

        mock_db_session.delete.assert_called_once_with(linked)

    def test_price_set_creates_budget_item_when_none(self, mock_db_session, make_trip):
        trip = make_trip(status="PLANNED")
        acc = Accommodation(
            trip_id=trip.id,
            name="x",
            price_per_night=None,
            check_in=datetime(2026, 5, 1),
            check_out=datetime(2026, 5, 3),
        )
        mock_db_session.query.return_value.filter.return_value.first.return_value = acc

        with patch(
            "src.services.accommodations_service.BudgetItemService.find_by_source",
            return_value=None,
        ):
            AccommodationsService.update_accommodation(
                db=mock_db_session,
                accommodation_id=acc.id,
                trip=trip,
                price_per_night=Decimal("80"),
            )

        assert acc.price_per_night == Decimal("80")
        assert mock_db_session.add.called


class TestDeleteAccommodation:
    def test_happy_path_with_linked(self, mock_db_session, make_trip):
        trip = make_trip(status="PLANNED")
        acc = Accommodation(trip_id=trip.id, name="x")
        linked = BudgetItem(trip_id=trip.id, label="x", amount=Decimal("100"))
        mock_db_session.query.return_value.filter.return_value.first.return_value = acc

        with patch(
            "src.services.accommodations_service.BudgetItemService.find_by_source",
            return_value=linked,
        ):
            AccommodationsService.delete_accommodation(mock_db_session, acc.id, trip)

        assert mock_db_session.delete.call_count == 2
        assert mock_db_session.commit.called

    def test_not_found(self, mock_db_session, make_trip):
        trip = make_trip(status="PLANNED")
        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        with pytest.raises(AppError) as exc:
            AccommodationsService.delete_accommodation(mock_db_session, uuid.uuid4(), trip)
        assert exc.value.code == "ACCOMMODATION_NOT_FOUND"

    def test_blocked_on_completed_trip(self, mock_db_session, make_trip):
        trip = make_trip(status="COMPLETED")
        with pytest.raises(AppError) as exc:
            AccommodationsService.delete_accommodation(mock_db_session, uuid.uuid4(), trip)
        assert exc.value.code == "TRIP_COMPLETED"


class TestSuggestAccommodations:
    @pytest.mark.asyncio
    async def test_returns_llm_results(self, mock_db_session, make_trip):
        trip = make_trip(
            destination_name="Barcelona",
            destination_iata="BCN",
            start_date=date(2026, 5, 1),
            end_date=date(2026, 5, 5),
            nb_travelers=2,
            budget_total=1000,
        )
        mock_db_session.query.return_value.filter.return_value.all.return_value = []

        fake_llm = MagicMock()
        fake_llm.acall_llm = AsyncMock(return_value={"accommodations": [{"name": "Hotel A"}]})

        with patch("src.services.llm_service.LLMService", return_value=fake_llm):
            result = await AccommodationsService.suggest_accommodations(mock_db_session, trip)

        assert result == [{"name": "Hotel A"}]

    @pytest.mark.asyncio
    async def test_llm_failure_returns_empty(self, mock_db_session, make_trip):
        trip = make_trip(destination_name="Paris")
        existing = [Accommodation(trip_id=trip.id, name="Hilton")]
        mock_db_session.query.return_value.filter.return_value.all.return_value = existing

        fake_llm = MagicMock()
        fake_llm.acall_llm = AsyncMock(side_effect=RuntimeError("boom"))

        with patch("src.services.llm_service.LLMService", return_value=fake_llm):
            result = await AccommodationsService.suggest_accommodations(mock_db_session, trip)

        assert result == []

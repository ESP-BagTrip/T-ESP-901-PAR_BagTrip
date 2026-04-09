"""Unit tests for BookingIntentsService."""

import uuid
from decimal import Decimal
from unittest.mock import MagicMock

import pytest

from src.models.booking_intent import BookingIntent
from src.models.flight_offer import FlightOffer
from src.services.booking_intents_service import BookingIntentsService
from src.utils.errors import AppError


@pytest.fixture
def mock_db_session():
    """Mock database session."""
    return MagicMock()


class TestBookingIntentsService:
    """Tests for BookingIntentsService."""

    def test_create_intent_flight_success(self, mock_db_session):
        """Test creating a flight booking intent."""
        trip_id = uuid.uuid4()
        user_id = uuid.uuid4()
        flight_offer_id = uuid.uuid4()

        # Mock flight offer exists
        flight_offer = FlightOffer(
            id=flight_offer_id,
            grand_total=100.50,
            currency="EUR",
            offer_json={"price": {"grandTotal": "100.50", "currency": "EUR"}},
        )
        mock_db_session.query.return_value.filter.return_value.first.return_value = flight_offer

        intent = BookingIntentsService.create_intent(
            mock_db_session, trip_id, user_id, "flight", flight_offer_id=flight_offer_id
        )

        assert intent.type == "flight"
        assert intent.amount == Decimal("100.50")
        assert intent.selected_offer_id == flight_offer_id
        mock_db_session.add.assert_called_once()
        mock_db_session.commit.assert_called_once()

    def test_create_intent_flight_priced_offer(self, mock_db_session):
        """Test creating a flight booking intent with priced_offer_json."""
        trip_id = uuid.uuid4()
        user_id = uuid.uuid4()
        flight_offer_id = uuid.uuid4()

        # Offer with priced_offer_json — service prefers this over offer_json
        flight_offer = FlightOffer(
            id=flight_offer_id,
            grand_total=100.00,
            priced_offer_json={"price": {"grandTotal": "120.00", "currency": "USD"}},
        )
        mock_db_session.query.return_value.filter.return_value.first.return_value = flight_offer

        intent = BookingIntentsService.create_intent(
            mock_db_session, trip_id, user_id, "flight", flight_offer_id=flight_offer_id
        )

        assert intent.amount == Decimal("120.00")
        assert intent.currency == "USD"

    def test_create_intent_invalid_type(self, mock_db_session):
        """Test error for invalid type."""
        with pytest.raises(AppError) as exc:
            BookingIntentsService.create_intent(
                mock_db_session, uuid.uuid4(), uuid.uuid4(), "invalid"
            )
        assert exc.value.code == "INVALID_REQUEST"

    def test_create_intent_missing_offer_id(self, mock_db_session):
        """Test error when offer ID is missing for flight type."""
        with pytest.raises(AppError) as exc:
            BookingIntentsService.create_intent(
                mock_db_session, uuid.uuid4(), uuid.uuid4(), "flight"
            )
        assert exc.value.code == "INVALID_REQUEST"

    def test_create_intent_offer_not_found(self, mock_db_session):
        """Test error when flight offer not found in DB."""
        mock_db_session.query.return_value.filter.return_value.first.return_value = None

        with pytest.raises(AppError) as exc:
            BookingIntentsService.create_intent(
                mock_db_session, uuid.uuid4(), uuid.uuid4(), "flight",
                flight_offer_id=uuid.uuid4(),
            )
        assert exc.value.code == "OFFER_NOT_FOUND"

    def test_get_intent_by_id(self, mock_db_session):
        """Test retrieving booking intent by ID."""
        intent = BookingIntent(id=uuid.uuid4())
        mock_db_session.query.return_value.filter.return_value.first.return_value = intent

        result = BookingIntentsService.get_intent_by_id(
            mock_db_session, intent.id, uuid.uuid4()
        )
        assert result == intent

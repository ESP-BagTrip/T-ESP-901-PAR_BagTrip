"""Unit tests for BookingOrchestratorService."""

import uuid
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from src.models.booking_intent import BookingIntent
from src.models.flight_offer import FlightOffer
from src.models.traveler import TripTraveler
from src.services.booking_orchestrator_service import BookingOrchestratorService
from src.utils.errors import AppError


@pytest.fixture
def mock_db_session():
    """Mock database session."""
    return MagicMock()


class TestBookingOrchestratorService:
    """Tests for BookingOrchestratorService."""

    @patch("src.services.booking_orchestrator_service.amadeus_client")
    @pytest.mark.asyncio
    async def test_book_flight_success(self, mock_amadeus, mock_db_session):
        """Test successful flight booking."""
        intent_id = uuid.uuid4()
        user_id = uuid.uuid4()
        offer_id = uuid.uuid4()
        traveler_id = uuid.uuid4()
        
        # Mock intent
        intent = BookingIntent(
            id=intent_id,
            user_id=user_id,
            trip_id=uuid.uuid4(),
            type="flight",
            status="AUTHORIZED",
            selected_offer_id=offer_id
        )
        
        # Valid FlightOffer structure
        valid_offer_json = {
            "type": "flight-offer",
            "id": "1",
            "source": "GDS",
            "instantTicketingRequired": False,
            "nonHomogeneous": False,
            "oneWay": False,
            "itineraries": [
                {
                    "duration": "PT2H",
                    "segments": [
                        {
                            "departure": {"iataCode": "CDG", "at": "2025-12-25T10:00:00"},
                            "arrival": {"iataCode": "LHR", "at": "2025-12-25T12:00:00"},
                            "carrierCode": "BA",
                            "number": "123",
                            "duration": "PT2H",
                            "id": "1",
                            "numberOfStops": 0,
                            "blacklistedInEU": False
                        }
                    ]
                }
            ],
            "price": {
                "currency": "EUR",
                "total": "100.00",
                "base": "80.00",
                "grandTotal": "100.00",
                "fees": [{"amount": "0.00", "type": "SUPPLIER"}]
            },
            "pricingOptions": {
                "fareType": ["PUBLISHED"],
                "includedCheckedBagsOnly": True
            },
            "validatingAirlineCodes": ["BA"],
            "travelerPricings": [
                {
                    "travelerId": "1",
                    "fareOption": "STANDARD",
                    "travelerType": "ADULT",
                    "price": {"currency": "EUR", "total": "100.00", "base": "80.00"},
                    "fareDetailsBySegment": [
                        {
                            "segmentId": "1",
                            "cabin": "ECONOMY",
                            "fareBasis": "Y",
                            "class": "Y",
                            "includedCheckedBags": {"quantity": 1}
                        }
                    ]
                }
            ]
        }

        # Mock flight offer
        flight_offer = FlightOffer(
            id=offer_id,
            offer_json=valid_offer_json
        )
        
        # Mock traveler
        traveler = TripTraveler(
            id=traveler_id, 
            trip_id=intent.trip_id,
            first_name="John",
            last_name="Doe",
            date_of_birth=uuid.uuid4(), # Mocking date object, but we need actual date
            gender="MALE"
        )
        # Fix date_of_birth to be a date object
        from datetime import date
        traveler.date_of_birth = date(1990, 1, 1)
        
        # Setup DB queries
        mock_db_session.query.return_value.filter.return_value.first.side_effect = [
            intent, flight_offer, traveler
        ]
        
        # Mock Amadeus response
        mock_response = MagicMock()
        mock_response.data = {"id": "ORDER_123"}
        
        # Ensure create_flight_order is an AsyncMock
        mock_amadeus.create_flight_order = AsyncMock(return_value=mock_response)
        
        result = await BookingOrchestratorService.book(
            mock_db_session, intent_id, user_id, traveler_ids=[traveler_id]
        )
        
        assert result.status == "BOOKED"
        assert result.amadeus_order_id == "ORDER_123"
        mock_db_session.add.assert_called() # FlightOrder added

    @pytest.mark.asyncio
    async def test_book_flight_missing_offer(self, mock_db_session):
        """Test booking flight without selected offer."""
        intent = BookingIntent(id=uuid.uuid4(), status="AUTHORIZED", type="flight", selected_offer_id=None)
        mock_db_session.query.return_value.filter.return_value.first.return_value = intent
        
        with pytest.raises(AppError) as exc:
            await BookingOrchestratorService.book(mock_db_session, intent.id, uuid.uuid4())
        assert exc.value.code == "MISSING_OFFER"

    @pytest.mark.asyncio
    async def test_book_intent_not_found(self, mock_db_session):
        """Test error when intent not found."""
        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        
        with pytest.raises(AppError) as exc:
            await BookingOrchestratorService.book(mock_db_session, uuid.uuid4(), uuid.uuid4())
        assert exc.value.code == "BOOKING_INTENT_NOT_FOUND"

    @pytest.mark.asyncio
    async def test_book_invalid_status(self, mock_db_session):
        """Test error when intent status is not AUTHORIZED."""
        intent = BookingIntent(status="INIT")
        mock_db_session.query.return_value.filter.return_value.first.return_value = intent
        
        with pytest.raises(AppError) as exc:
            await BookingOrchestratorService.book(mock_db_session, uuid.uuid4(), uuid.uuid4())
        assert exc.value.code == "INVALID_STATUS"

    @pytest.mark.asyncio
    async def test_book_failed_rollback(self, mock_db_session):
        """Test rollback on error."""
        intent = BookingIntent(status="AUTHORIZED", type="flight")
        mock_db_session.query.return_value.filter.return_value.first.return_value = intent
        
        # Simulate error during processing (missing offer)
        with pytest.raises(AppError):
            await BookingOrchestratorService.book(mock_db_session, uuid.uuid4(), uuid.uuid4())
            
        mock_db_session.rollback.assert_called()
        assert intent.status == "FAILED"

    @pytest.mark.asyncio
    async def test_book_invalid_type(self, mock_db_session):
        """Test error for invalid intent type."""
        intent = BookingIntent(status="AUTHORIZED", type="car_rental")
        mock_db_session.query.return_value.filter.return_value.first.return_value = intent
        
        with pytest.raises(AppError) as exc:
            await BookingOrchestratorService.book(mock_db_session, uuid.uuid4(), uuid.uuid4())
        assert exc.value.code == "INVALID_TYPE"

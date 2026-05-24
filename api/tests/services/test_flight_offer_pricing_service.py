"""Unit tests for FlightOfferPricingService."""

import uuid
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from src.models.flight_offer import FlightOffer
from src.services.flight_offer_pricing_service import FlightOfferPricingService
from src.utils.errors import AppError


@pytest.fixture
def mock_db_session():
    """Mock database session."""
    return MagicMock()


class TestFlightOfferPricingService:
    """Tests for FlightOfferPricingService."""

    @patch("src.services.flight_offer_pricing_service.amadeus_client")
    @pytest.mark.asyncio
    async def test_price_offer_success(self, mock_amadeus, mock_db_session):
        """Test successful offer pricing."""
        trip_id = uuid.uuid4()
        offer_id = uuid.uuid4()

        # Valid FlightOffer structure that satisfies the Amadeus FlightOffer pydantic model
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
                            "blacklistedInEU": False,
                        }
                    ],
                }
            ],
            "price": {
                "currency": "EUR",
                "total": "100.00",
                "base": "80.00",
                "grandTotal": "100.00",
                "fees": [{"amount": "0.00", "type": "SUPPLIER"}],
            },
            "pricingOptions": {
                "fareType": ["PUBLISHED"],
                "includedCheckedBagsOnly": True,
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
                            "includedCheckedBags": {"quantity": 1},
                        }
                    ],
                }
            ],
        }

        offer = FlightOffer(
            id=offer_id,
            trip_id=trip_id,
            offer_json=valid_offer_json,
            grand_total=100.0,
            currency="EUR",
        )
        mock_db_session.query.return_value.filter.return_value.first.return_value = offer

        # Mock Amadeus response
        mock_response = MagicMock()
        mock_response.data = {
            "flightOffers": [{"price": {"grandTotal": "120.00", "currency": "USD"}}]
        }
        mock_response.model_dump.return_value = mock_response.data

        mock_amadeus.confirm_flight_price = AsyncMock(return_value=mock_response)

        result = await FlightOfferPricingService.price_offer(mock_db_session, offer_id, trip_id)

        assert result.grand_total == 120.0
        assert result.currency == "USD"
        assert result.priced_offer_json == mock_response.data
        mock_db_session.commit.assert_called_once()

    @pytest.mark.asyncio
    async def test_price_offer_not_found(self, mock_db_session):
        """Test error when offer not found."""
        mock_db_session.query.return_value.filter.return_value.first.return_value = None

        with pytest.raises(AppError) as exc:
            await FlightOfferPricingService.price_offer(mock_db_session, uuid.uuid4(), uuid.uuid4())
        assert exc.value.code == "OFFER_NOT_FOUND"

"""Unit tests for HotelSearchService."""

import uuid
from datetime import date
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from src.models.hotel_offer import HotelOffer
from src.models.hotel_search import HotelSearch
from src.models.trip import Trip
from src.services.hotel_search_service import HotelSearchService
from src.utils.errors import AppError


@pytest.fixture
def mock_db_session():
    """Mock database session."""
    return MagicMock()


class TestHotelSearchService:
    """Tests for HotelSearchService."""

    @patch("src.services.hotel_search_service.amadeus_client")
    @patch("src.services.hotel_search_service.TripsService.get_trip_by_id")
    @pytest.mark.asyncio
    async def test_create_search_success(self, mock_get_trip, mock_amadeus, mock_db_session):
        """Test successful hotel search creation."""
        trip_id = uuid.uuid4()
        user_id = uuid.uuid4()
        
        mock_get_trip.return_value = Trip(id=trip_id)
        
        # Mock Amadeus response
        mock_response = {
            "data": [
                {
                    "hotel": {
                        "hotelId": "H1",
                        "chainCode": "CH",
                        "name": "Hotel 1"
                    },
                    "offers": [
                        {
                            "id": "OFFER1",
                            "price": {"currency": "EUR", "total": "150.00"},
                            "room": {"type": "Double"}
                        }
                    ]
                }
            ]
        }
        
        # Use AsyncMock for async method
        mock_amadeus.search_hotel_offers = AsyncMock(return_value=mock_response)
        
        search, offers = await HotelSearchService.create_search(
            mock_db_session,
            trip_id,
            user_id,
            city_code="PAR",
            check_in=date(2025, 12, 1),
            check_out=date(2025, 12, 5),
            adults=2,
            room_qty=1
        )
        
        assert search.city_code == "PAR"
        assert len(offers) == 1
        assert offers[0].total_price == 150.0
        assert offers[0].hotel_id == "H1"
        
        mock_db_session.add.assert_called()
        mock_db_session.commit.assert_called_once()

    @patch("src.services.hotel_search_service.TripsService.get_trip_by_id")
    @pytest.mark.asyncio
    async def test_create_search_invalid_dates(self, mock_get_trip, mock_db_session):
        """Test error when dates are missing."""
        mock_get_trip.return_value = Trip(id=uuid.uuid4())
        
        with pytest.raises(AppError) as exc:
            await HotelSearchService.create_search(
                mock_db_session,
                uuid.uuid4(),
                uuid.uuid4(),
                city_code="PAR"
            )
        assert exc.value.code == "INVALID_REQUEST"

    @patch("src.services.hotel_search_service.TripsService.get_trip_by_id")
    def test_get_search_by_id_success(self, mock_get_trip, mock_db_session):
        """Test retrieving search by ID."""
        trip_id = uuid.uuid4()
        search_id = uuid.uuid4()
        
        mock_get_trip.return_value = Trip(id=trip_id)
        mock_search = HotelSearch(id=search_id, trip_id=trip_id)
        mock_db_session.query.return_value.filter.return_value.first.return_value = mock_search
        
        result = HotelSearchService.get_search_by_id(
            mock_db_session, search_id, trip_id, uuid.uuid4()
        )
        assert result == mock_search

    @patch("src.services.hotel_search_service.HotelSearchService.get_search_by_id")
    def test_get_offers_by_search_success(self, mock_get_search, mock_db_session):
        """Test retrieving offers by search."""
        search_id = uuid.uuid4()
        mock_get_search.return_value = HotelSearch(id=search_id)
        
        mock_offers = [HotelOffer(id=uuid.uuid4())]
        mock_db_session.query.return_value.filter.return_value.all.return_value = mock_offers
        
        result = HotelSearchService.get_offers_by_search(
            mock_db_session, search_id, uuid.uuid4(), uuid.uuid4()
        )
        assert len(result) == 1

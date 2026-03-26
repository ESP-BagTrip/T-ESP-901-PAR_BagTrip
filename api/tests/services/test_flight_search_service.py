"""Unit tests for FlightSearchService."""

import uuid
from datetime import date
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from src.models.flight_offer import FlightOffer
from src.models.flight_search import FlightSearch
from src.models.trip import Trip
from src.services.flight_search_service import FlightSearchService
from src.utils.errors import AppError


@pytest.fixture
def mock_db_session():
    """Mock database session."""
    return MagicMock()


class TestFlightSearchService:
    """Tests for FlightSearchService."""

    @patch("src.services.flight_search_service.amadeus_client")
    @patch("src.services.flight_search_service.TripsService.get_trip_by_id")
    @pytest.mark.asyncio
    async def test_create_search_success(self, mock_get_trip, mock_amadeus, mock_db_session):
        """Test successful flight search creation."""
        trip_id = uuid.uuid4()
        user_id = uuid.uuid4()
        
        mock_get_trip.return_value = Trip(id=trip_id)
        
        # Mock Amadeus response
        mock_response = MagicMock()
        mock_response.data = [
            {
                "id": "1",
                "source": "GDS",
                "validatingAirlineCodes": ["AF"],
                "price": {
                    "grandTotal": "100.00",
                    "base": "80.00",
                    "currency": "EUR"
                }
            }
        ]
        mock_response.model_dump.return_value = {"data": mock_response.data}
        
        # Use AsyncMock for async method
        mock_amadeus.search_flight_offers = AsyncMock(return_value=mock_response)
        
        search, offers = await FlightSearchService.create_search(
            mock_db_session,
            trip_id,
            user_id,
            "PAR",
            "NYC",
            date(2025, 12, 1),
            adults=1
        )
        
        assert search.origin_iata == "PAR"
        assert len(offers) == 1
        assert offers[0].grand_total == 100.0
        assert offers[0].currency == "EUR"
        
        mock_db_session.add.assert_called()
        mock_db_session.commit.assert_called_once()

    @patch("src.services.flight_search_service.TripsService.get_trip_by_id")
    @pytest.mark.asyncio
    async def test_create_search_trip_not_found(self, mock_get_trip, mock_db_session):
        """Test error when trip not found."""
        mock_get_trip.return_value = None
        
        with pytest.raises(AppError) as exc:
            await FlightSearchService.create_search(
                mock_db_session,
                uuid.uuid4(),
                uuid.uuid4(),
                "PAR",
                "NYC",
                date(2025, 12, 1)
            )
        assert exc.value.code == "TRIP_NOT_FOUND"

    @patch("src.services.flight_search_service.TripsService.get_trip_by_id")
    def test_get_search_by_id_success(self, mock_get_trip, mock_db_session):
        """Test retrieving search by ID."""
        trip_id = uuid.uuid4()
        user_id = uuid.uuid4()
        search_id = uuid.uuid4()
        
        mock_get_trip.return_value = Trip(id=trip_id)
        
        mock_search = FlightSearch(id=search_id, trip_id=trip_id)
        mock_db_session.query.return_value.filter.return_value.first.return_value = mock_search
        
        result = FlightSearchService.get_search_by_id(mock_db_session, search_id, trip_id, user_id)
        assert result == mock_search

    @patch("src.services.flight_search_service.FlightSearchService.get_search_by_id")
    def test_get_offers_by_search_success(self, mock_get_search, mock_db_session):
        """Test retrieving offers by search."""
        search_id = uuid.uuid4()
        
        mock_get_search.return_value = FlightSearch(id=search_id)
        
        mock_offers = [FlightOffer(id=uuid.uuid4()), FlightOffer(id=uuid.uuid4())]
        mock_db_session.query.return_value.filter.return_value.all.return_value = mock_offers
        
        result = FlightSearchService.get_offers_by_search(
            mock_db_session, search_id, uuid.uuid4(), uuid.uuid4()
        )
        assert len(result) == 2

    @patch("src.services.flight_search_service.FlightSearchService.get_search_by_id")
    def test_get_offers_by_search_not_found(self, mock_get_search, mock_db_session):
        """Test error when search not found."""
        mock_get_search.return_value = None
        
        with pytest.raises(AppError) as exc:
            FlightSearchService.get_offers_by_search(
                mock_db_session, uuid.uuid4(), uuid.uuid4(), uuid.uuid4()
            )
        assert exc.value.code == "SEARCH_NOT_FOUND"

"""Unit tests for FlightSearchService."""

import uuid
from datetime import date
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from src.models.flight_offer import FlightOffer
from src.models.flight_search import FlightSearch
from src.services.flight_search_service import FlightSearchService
from src.utils.errors import AppError


@pytest.fixture
def mock_db_session():
    """Mock database session."""
    return MagicMock()


class TestFlightSearchService:
    """Tests for FlightSearchService."""

    @patch("src.services.flight_search_service.amadeus_client")
    @pytest.mark.asyncio
    async def test_create_search_success(self, mock_amadeus, mock_db_session):
        """Test successful flight search creation."""
        trip_id = uuid.uuid4()

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
                    "currency": "EUR",
                },
            }
        ]
        mock_response.model_dump.return_value = {"data": mock_response.data}

        mock_amadeus.search_flight_offers = AsyncMock(return_value=mock_response)

        search, offers = await FlightSearchService.create_search(
            mock_db_session,
            trip_id,
            "PAR",
            "NYC",
            date(2025, 12, 1),
            adults=1,
        )

        assert search.origin_iata == "PAR"
        assert len(offers) == 1
        assert offers[0].grand_total == 100.0
        assert offers[0].currency == "EUR"

        mock_db_session.add.assert_called()
        mock_db_session.commit.assert_called_once()

    @patch("src.services.flight_search_service.amadeus_client")
    @pytest.mark.asyncio
    async def test_create_search_no_offers(self, mock_amadeus, mock_db_session):
        """Test search creation when Amadeus returns no offers."""
        trip_id = uuid.uuid4()

        mock_response = MagicMock()
        mock_response.data = []
        mock_response.model_dump.return_value = {"data": []}

        mock_amadeus.search_flight_offers = AsyncMock(return_value=mock_response)

        search, offers = await FlightSearchService.create_search(
            mock_db_session,
            trip_id,
            "PAR",
            "NYC",
            date(2025, 12, 1),
        )

        assert len(offers) == 0
        mock_db_session.commit.assert_called_once()

    def test_get_search_by_id_success(self, mock_db_session):
        """Test retrieving search by ID."""
        trip_id = uuid.uuid4()
        search_id = uuid.uuid4()

        mock_search = FlightSearch(id=search_id, trip_id=trip_id)
        mock_db_session.query.return_value.filter.return_value.first.return_value = mock_search

        result = FlightSearchService.get_search_by_id(mock_db_session, search_id, trip_id)
        assert result == mock_search

    def test_get_offers_by_search_success(self, mock_db_session):
        """Test retrieving offers by search."""
        search_id = uuid.uuid4()
        trip_id = uuid.uuid4()

        mock_search = FlightSearch(id=search_id)
        mock_offers = [FlightOffer(id=uuid.uuid4()), FlightOffer(id=uuid.uuid4())]

        # get_offers_by_search calls get_search_by_id (filter.first) then filter.all for offers
        mock_db_session.query.return_value.filter.return_value.first.return_value = mock_search
        mock_db_session.query.return_value.filter.return_value.all.return_value = mock_offers

        result = FlightSearchService.get_offers_by_search(mock_db_session, search_id, trip_id)
        assert len(result) == 2

    def test_get_offers_by_search_not_found(self, mock_db_session):
        """Test error when search not found."""
        mock_db_session.query.return_value.filter.return_value.first.return_value = None

        with pytest.raises(AppError) as exc:
            FlightSearchService.get_offers_by_search(mock_db_session, uuid.uuid4(), uuid.uuid4())
        assert exc.value.code == "SEARCH_NOT_FOUND"

    @patch("src.services.flight_search_service.amadeus_client")
    @pytest.mark.asyncio
    async def test_create_multi_dest_search_success(self, mock_amadeus, mock_db_session):
        """Test multi-destination search with 2 segments."""
        trip_id = uuid.uuid4()

        mock_response = MagicMock()
        mock_response.data = [
            {
                "id": "1",
                "source": "GDS",
                "validatingAirlineCodes": ["AF"],
                "price": {
                    "grandTotal": "200.00",
                    "base": "160.00",
                    "currency": "EUR",
                },
            }
        ]
        mock_response.model_dump.return_value = {"data": mock_response.data}

        mock_amadeus.search_flight_offers = AsyncMock(return_value=mock_response)

        segments = [
            {"originIata": "CDG", "destinationIata": "NRT", "departureDate": date(2027, 6, 1)},
            {"originIata": "NRT", "destinationIata": "BKK", "departureDate": date(2027, 6, 5)},
        ]

        results = await FlightSearchService.create_multi_dest_search(
            mock_db_session, trip_id, segments, adults=1
        )

        assert len(results) == 2
        # Each segment should produce a (search, offers) tuple
        for search, offers in results:
            assert search.trip_id == trip_id
            assert len(offers) == 1
            assert offers[0].grand_total == 200.0

        # Amadeus should be called twice (once per segment)
        assert mock_amadeus.search_flight_offers.call_count == 2
        mock_db_session.commit.assert_called_once()

    @patch("src.services.flight_search_service.amadeus_client")
    @pytest.mark.asyncio
    async def test_create_multi_dest_search_partial_failure(self, mock_amadeus, mock_db_session):
        """Test multi-dest where one segment fails — other still succeeds."""
        trip_id = uuid.uuid4()

        mock_good_response = MagicMock()
        mock_good_response.data = [
            {
                "id": "1",
                "source": "GDS",
                "validatingAirlineCodes": ["AF"],
                "price": {"grandTotal": "100.00", "base": "80.00", "currency": "EUR"},
            }
        ]
        mock_good_response.model_dump.return_value = {"data": mock_good_response.data}

        # First call succeeds, second raises an exception
        mock_amadeus.search_flight_offers = AsyncMock(
            side_effect=[mock_good_response, Exception("Amadeus timeout")]
        )

        segments = [
            {"originIata": "CDG", "destinationIata": "NRT", "departureDate": date(2027, 6, 1)},
            {"originIata": "NRT", "destinationIata": "BKK", "departureDate": date(2027, 6, 5)},
        ]

        results = await FlightSearchService.create_multi_dest_search(
            mock_db_session, trip_id, segments, adults=1
        )

        # Only 1 segment should succeed
        assert len(results) == 1
        search, offers = results[0]
        assert search.origin_iata == "CDG"

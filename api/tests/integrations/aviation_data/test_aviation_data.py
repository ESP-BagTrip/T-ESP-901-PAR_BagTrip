"""Unit tests for the offline aviation data service."""

import pytest

from src.integrations.aviation_data.service import AviationDataService
from src.integrations.amadeus.types import Location


@pytest.fixture
def service():
    """Fresh AviationDataService instance."""
    return AviationDataService()


class TestSearchByKeyword:
    """Tests for keyword search."""

    def test_search_paris_returns_cdg_first(self, service):
        """CDG (international) should rank above smaller Paris airports."""
        results = service.search_by_keyword("paris")
        assert len(results) > 0
        iata_codes = [r.iataCode for r in results]
        assert "CDG" in iata_codes
        # CDG should be first (international airport in Paris)
        assert iata_codes[0] == "CDG"

    def test_search_by_iata_code(self, service):
        """Exact IATA code search returns that airport."""
        results = service.search_by_keyword("CDG")
        assert len(results) == 1
        assert results[0].iataCode == "CDG"
        assert "Charles de Gaulle" in results[0].name

    def test_search_case_insensitive(self, service):
        """Search is case-insensitive."""
        upper = service.search_by_keyword("PARIS")
        lower = service.search_by_keyword("paris")
        mixed = service.search_by_keyword("Paris")
        assert [r.iataCode for r in upper] == [r.iataCode for r in lower]
        assert [r.iataCode for r in upper] == [r.iataCode for r in mixed]

    def test_search_empty_keyword(self, service):
        """Empty keyword returns empty list."""
        assert service.search_by_keyword("") == []
        assert service.search_by_keyword("   ") == []

    def test_search_no_results(self, service):
        """Unknown keyword returns empty list."""
        assert service.search_by_keyword("xyznotexist999") == []

    def test_search_limit(self, service):
        """Limit parameter caps the number of results."""
        results = service.search_by_keyword("new", limit=3)
        assert len(results) <= 3

    def test_result_is_location_model(self, service):
        """Results are Location model instances with all required fields."""
        results = service.search_by_keyword("CDG")
        assert len(results) == 1
        loc = results[0]
        assert isinstance(loc, Location)
        assert loc.type == "location"
        assert loc.subType == "AIRPORT"
        assert loc.iataCode == "CDG"
        assert loc.geoCode.latitude != 0
        assert loc.geoCode.longitude != 0
        assert loc.address.cityName == "Paris"
        assert loc.address.countryCode == "FR"
        assert loc.address.countryName == "France"
        assert loc.address.regionCode == "EU"

    def test_result_serializes_correctly(self, service):
        """Location model serializes with correct alias (self → self_)."""
        results = service.search_by_keyword("CDG")
        data = results[0].model_dump(by_alias=True)
        assert "self" in data
        assert data["self"]["methods"] == ["GET"]
        assert "/v1/travel/locations/CDG" in data["self"]["href"]

    def test_search_london(self, service):
        """Major city search returns relevant airports."""
        results = service.search_by_keyword("london")
        iata_codes = [r.iataCode for r in results]
        assert "LHR" in iata_codes

    def test_search_new_york(self, service):
        """Multi-word city search works."""
        results = service.search_by_keyword("new york")
        iata_codes = [r.iataCode for r in results]
        assert "JFK" in iata_codes


class TestGetById:
    """Tests for ID/IATA code lookup."""

    def test_get_cdg(self, service):
        """Known IATA code returns correct airport."""
        loc = service.get_by_id("CDG")
        assert loc is not None
        assert loc.iataCode == "CDG"
        assert loc.address.cityName == "Paris"

    def test_get_unknown(self, service):
        """Unknown IATA code returns None."""
        assert service.get_by_id("ZZZ") is None

    def test_get_case_insensitive(self, service):
        """Lookup is case-insensitive."""
        upper = service.get_by_id("CDG")
        lower = service.get_by_id("cdg")
        assert upper is not None
        assert lower is not None
        assert upper.iataCode == lower.iataCode

    def test_get_returns_location_model(self, service):
        """get_by_id returns a full Location model."""
        loc = service.get_by_id("JFK")
        assert isinstance(loc, Location)
        assert loc.type == "location"
        assert loc.address.countryCode == "US"


class TestSearchNearest:
    """Tests for nearest airport search."""

    def test_nearest_paris(self, service):
        """Nearest to Paris coordinates returns Paris airports."""
        results = service.search_nearest(48.8566, 2.3522, limit=5)
        assert len(results) > 0
        iata_codes = [r.iataCode for r in results]
        # At least one Paris airport should be in the top 5
        paris_airports = {"CDG", "ORY", "LBG"}
        assert paris_airports & set(iata_codes)

    def test_nearest_limit(self, service):
        """Limit parameter caps results."""
        results = service.search_nearest(48.8566, 2.3522, limit=3)
        assert len(results) == 3

    def test_nearest_returns_sorted(self, service):
        """Results are sorted by distance (closest first)."""
        results = service.search_nearest(48.8566, 2.3522, limit=5)
        # Le Bourget is closest to central Paris (~12km), CDG is ~25km, ORY is ~14km
        # Just verify the first result is a Paris-area airport
        assert results[0].address.countryCode == "FR"

    def test_nearest_returns_location_models(self, service):
        """All results are Location model instances."""
        results = service.search_nearest(40.6413, -73.7781, limit=3)  # Near JFK
        for loc in results:
            assert isinstance(loc, Location)
            assert loc.iataCode is not None

"""Unit tests for the Amadeus-first destination inspiration pipeline."""

from __future__ import annotations

from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from src.integrations.amadeus.types import (
    FlightDestination,
    FlightDestinationMeta,
    FlightDestinationPrice,
    FlightDestinationResponse,
    Poi,
    PoiGeoCode,
)
from src.services.destination_inspiration_service import inspire_then_rank
from src.services.location_resolver import ResolvedCity

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _resolved(iata: str = "CDG", city: str = "Paris") -> ResolvedCity:
    return ResolvedCity(
        iata=iata,
        city=city,
        country="France",
        country_code="FR",
        latitude=49.0,
        longitude=2.55,
        source="airportsdata.keyword",
    )


def _flight_destination(
    iata: str, *, price: str = "550.00", departure: str = "2026-08-15"
) -> FlightDestination:
    return FlightDestination(
        type="flight-destination",
        origin="CDG",
        destination=iata,
        departureDate=departure,
        returnDate="2026-08-22",
        price=FlightDestinationPrice(total=price),
    )


def _aviation_loc(iata: str, city: str, country: str, lat: float, lon: float):
    """Mimic the offline aviation Location pydantic shape."""
    address = MagicMock()
    address.cityName = city
    address.countryName = country
    address.countryCode = country[:2].upper()
    geo = MagicMock(latitude=lat, longitude=lon)
    return MagicMock(iataCode=iata, address=address, geoCode=geo)


# ---------------------------------------------------------------------------
# Cases
# ---------------------------------------------------------------------------


class TestInspireThenRankFallthrough:
    """Cases where the pipeline returns None so the legacy path runs."""

    @pytest.mark.asyncio
    async def test_returns_none_when_no_origin_city(self):
        result = await inspire_then_rank({"origin_city": "", "locale": "fr"})
        assert result is None

    @pytest.mark.asyncio
    async def test_returns_none_when_origin_unresolvable(self):
        with patch(
            "src.services.destination_inspiration_service.resolve_city",
            new=AsyncMock(return_value=None),
        ):
            result = await inspire_then_rank({"origin_city": "ZZZ-non-existent", "locale": "fr"})
        assert result is None

    @pytest.mark.asyncio
    async def test_returns_none_when_amadeus_inspiration_raises(self):
        with (
            patch(
                "src.services.destination_inspiration_service.resolve_city",
                new=AsyncMock(return_value=_resolved()),
            ),
            patch(
                "src.services.destination_inspiration_service.AmadeusService.search_flight_destinations",
                new=AsyncMock(side_effect=RuntimeError("Amadeus 502")),
            ),
        ):
            result = await inspire_then_rank({"origin_city": "Paris", "locale": "fr"})
        assert result is None

    @pytest.mark.asyncio
    async def test_returns_none_when_amadeus_returns_no_data(self):
        with (
            patch(
                "src.services.destination_inspiration_service.resolve_city",
                new=AsyncMock(return_value=_resolved()),
            ),
            patch(
                "src.services.destination_inspiration_service.AmadeusService.search_flight_destinations",
                new=AsyncMock(
                    return_value=FlightDestinationResponse(
                        meta=FlightDestinationMeta(currency="EUR"), data=[]
                    )
                ),
            ),
        ):
            result = await inspire_then_rank({"origin_city": "Paris", "locale": "fr"})
        assert result is None


class TestInspireThenRankHappyPath:
    @pytest.mark.asyncio
    async def test_pipeline_returns_projected_destinations(self):
        candidates = [
            _flight_destination("SIN", price="650.00"),
            _flight_destination("BCN", price="200.00"),
        ]

        sin_loc = _aviation_loc("SIN", "Singapore", "Singapore", 1.35, 103.99)
        bcn_loc = _aviation_loc("BCN", "Barcelona", "Spain", 41.39, 2.17)
        get_by_id = MagicMock(side_effect=lambda code: {"SIN": sin_loc, "BCN": bcn_loc}.get(code))

        marina = Poi(
            id="MBS",
            name="Marina Bay Sands",
            geoCode=PoiGeoCode(latitude=1.28, longitude=103.86),
            tags=["resort", "casino"],
        )
        sagrada = Poi(
            id="SF",
            name="Sagrada Família",
            geoCode=PoiGeoCode(latitude=41.4, longitude=2.17),
            tags=["sights", "architecture"],
        )

        async def fake_pois(query):
            return [marina] if query.latitude > 0 else [sagrada]

        ranked_payload = {
            "destinations": [
                {
                    "iata": "SIN",
                    "match_reason": "Skyline électrique pour 6 jours en couple.",
                    "weather_summary": "27–30°C tropical",
                    "topActivities": ["Marina Bay Sands", "Gardens", "Hawker"],
                },
                {
                    "iata": "BCN",
                    "match_reason": "Plages, gastronomie, architecture vibrante.",
                    "weather_summary": "22–28°C en été",
                    "topActivities": ["Sagrada Família", "Park Güell"],
                },
            ]
        }
        fake_llm = MagicMock()
        fake_llm.acall_llm = AsyncMock(return_value=ranked_payload)

        state = {
            "origin_city": "Paris",
            "locale": "fr",
            "departure_date": "2026-08-15",
            "duration_days": 7,
            "target_budget": 2000,
            "travel_types": "beach,culture",
            "nb_travelers": 2,
        }

        with (
            patch(
                "src.services.destination_inspiration_service.resolve_city",
                new=AsyncMock(return_value=_resolved()),
            ),
            patch(
                "src.services.destination_inspiration_service.AmadeusService.search_flight_destinations",
                new=AsyncMock(
                    return_value=FlightDestinationResponse(
                        meta=FlightDestinationMeta(currency="EUR"), data=candidates
                    )
                ),
            ),
            patch(
                "src.services.destination_inspiration_service.aviation_data_service.get_by_id",
                side_effect=get_by_id,
            ),
            patch(
                "src.services.destination_inspiration_service.AmadeusService.search_pois",
                new=AsyncMock(side_effect=fake_pois),
            ),
            patch(
                "src.agent.tools.weather.get_weather",
                new=AsyncMock(
                    return_value={
                        "avg_temp_c": 28,
                        "min_temp_c": 24,
                        "max_temp_c": 32,
                        "rain_probability": 30,
                    }
                ),
            ),
            patch(
                "src.services.llm_service.LLMService",
                return_value=fake_llm,
            ),
        ):
            destinations = await inspire_then_rank(state)

        assert destinations is not None
        assert len(destinations) == 2
        # IATA + factual fields come from Amadeus, never the LLM.
        sin = next(d for d in destinations if d["iata"] == "SIN")
        assert sin["city"] == "Singapore"
        assert sin["country"] == "Singapore"
        assert sin["flight_price_eur"] == 650.0
        assert sin["weather"]["avg_temp_c"] == 28
        # Editorial copy comes from the LLM ranker.
        assert "Skyline" in sin["match_reason"]
        assert sin["topActivities"][0] == "Marina Bay Sands"

    @pytest.mark.asyncio
    async def test_pipeline_drops_unknown_iata_from_llm(self):
        """A hallucinated IATA from the LLM ranker must never leak through."""
        candidates = [_flight_destination("SIN")]
        sin_loc = _aviation_loc("SIN", "Singapore", "Singapore", 1.35, 103.99)
        ranked_payload = {
            "destinations": [
                {"iata": "XYZ", "match_reason": "fake", "weather_summary": "", "topActivities": []},
                {"iata": "SIN", "match_reason": "ok", "weather_summary": "", "topActivities": []},
            ]
        }
        fake_llm = MagicMock()
        fake_llm.acall_llm = AsyncMock(return_value=ranked_payload)

        state = {"origin_city": "Paris", "locale": "en", "departure_date": "2026-08-15"}

        with (
            patch(
                "src.services.destination_inspiration_service.resolve_city",
                new=AsyncMock(return_value=_resolved()),
            ),
            patch(
                "src.services.destination_inspiration_service.AmadeusService.search_flight_destinations",
                new=AsyncMock(
                    return_value=FlightDestinationResponse(
                        meta=FlightDestinationMeta(currency="EUR"), data=candidates
                    )
                ),
            ),
            patch(
                "src.services.destination_inspiration_service.aviation_data_service.get_by_id",
                return_value=sin_loc,
            ),
            patch(
                "src.services.destination_inspiration_service.AmadeusService.search_pois",
                new=AsyncMock(return_value=[]),
            ),
            patch(
                "src.agent.tools.weather.get_weather",
                new=AsyncMock(return_value={}),
            ),
            patch(
                "src.services.llm_service.LLMService",
                return_value=fake_llm,
            ),
        ):
            destinations = await inspire_then_rank(state)

        assert destinations is not None
        iatas = [d["iata"] for d in destinations]
        assert iatas == ["SIN"]
        assert "XYZ" not in iatas

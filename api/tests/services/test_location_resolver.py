"""Unit tests for ``services.location_resolver``."""

from __future__ import annotations

from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from src.integrations.open_meteo import GeocodedPlace
from src.services.location_resolver import (
    ResolvedCity,
    _slug,
    resolve_city,
)


def _aviation_location(
    iata: str,
    city: str,
    country: str,
    lat: float,
    lon: float,
    *,
    country_code: str = "",
    city_code: str = "",
):
    """Build a stub mimicking the Pydantic ``Location`` returned by aviation_data."""
    address = MagicMock()
    address.cityName = city
    address.countryName = country
    address.countryCode = country_code
    address.cityCode = city_code
    geo = MagicMock(latitude=lat, longitude=lon)
    loc = MagicMock(iataCode=iata, address=address, geoCode=geo)
    return loc


class TestSlug:
    @pytest.mark.parametrize(
        ("raw", "expected"),
        [
            ("Singapour", "singapour"),
            ("SAINT-PÉTERSBOURG", "saint_petersbourg"),
            ("saint petersbourg", "saint_petersbourg"),
            ("Köln", "koln"),
            ("São Paulo", "sao_paulo"),
            ("  spaced  ", "spaced"),
            ("", ""),
        ],
    )
    def test_slug_normalizes(self, raw: str, expected: str) -> None:
        assert _slug(raw) == expected


class TestResolveCityCascade:
    @pytest.mark.asyncio
    async def test_empty_input_returns_none(self):
        assert await resolve_city("") is None
        assert await resolve_city("   ") is None
        assert await resolve_city(None) is None  # type: ignore[arg-type]

    @pytest.mark.asyncio
    async def test_iata_passthrough_short_circuits(self):
        loc = _aviation_location("CDG", "Paris", "France", 49.0, 2.55)
        with (
            patch(
                "src.services.location_resolver.aviation_data_service.get_by_id",
                return_value=loc,
            ) as get_by_id,
            patch("src.services.location_resolver._read_cache", return_value=None),
            patch("src.services.location_resolver._write_cache") as write_cache,
            patch("src.services.location_resolver.search_places", new=AsyncMock()) as omg,
        ):
            result = await resolve_city("CDG")
        assert result is not None
        assert result.iata == "CDG"
        assert result.source == "airportsdata.iata"
        get_by_id.assert_called_once_with("CDG")
        omg.assert_not_called()
        write_cache.assert_called_once()

    @pytest.mark.asyncio
    async def test_iata_passthrough_unknown_falls_through(self):
        with (
            patch(
                "src.services.location_resolver.aviation_data_service.get_by_id",
                return_value=None,
            ),
            patch("src.services.location_resolver._read_cache", return_value=None),
            patch(
                "src.services.location_resolver._try_airportsdata_keyword",
                return_value=None,
            ),
            patch(
                "src.services.location_resolver.search_places",
                new=AsyncMock(return_value=[]),
            ),
        ):
            result = await resolve_city("ZZZ")
        assert result is None

    @pytest.mark.asyncio
    async def test_cache_hit_skips_resolution(self):
        cached = ResolvedCity(
            iata="SIN",
            city="Singapour",
            country="Singapour",
            country_code="SG",
            latitude=1.35,
            longitude=103.99,
            source="cached",
        )
        with (
            patch("src.services.location_resolver._read_cache", return_value=cached),
            patch(
                "src.services.location_resolver._try_iata_passthrough",
                return_value=None,
            ),
            patch("src.services.location_resolver.aviation_data_service") as aviation,
            patch("src.services.location_resolver.search_places", new=AsyncMock()) as omg,
        ):
            result = await resolve_city("Singapour", locale="fr")
        assert result == cached
        aviation.search_by_keyword.assert_not_called()
        omg.assert_not_called()

    @pytest.mark.asyncio
    async def test_english_keyword_match(self):
        loc = _aviation_location("SIN", "Singapore", "Singapore", 1.35, 103.99)
        with (
            patch("src.services.location_resolver._read_cache", return_value=None),
            patch(
                "src.services.location_resolver._try_iata_passthrough",
                return_value=None,
            ),
            patch(
                "src.services.location_resolver.aviation_data_service.search_by_keyword",
                return_value=[loc],
            ),
            patch("src.services.location_resolver.search_places", new=AsyncMock()) as omg,
            patch("src.services.location_resolver._write_cache"),
        ):
            result = await resolve_city("Singapore", locale="en")
        assert result is not None
        assert result.iata == "SIN"
        assert result.source == "airportsdata.keyword"
        omg.assert_not_called()

    @pytest.mark.asyncio
    async def test_french_input_falls_back_to_geocoding(self):
        # Step 3 (English keyword) misses for "Singapour".
        # Step 4: Open-Meteo returns Singapore in EN, then airportsdata
        # finds SIN with that English name.
        place = GeocodedPlace(
            name="Singapore",
            latitude=1.28967,
            longitude=103.85007,
            country="Singapore",
            country_code="SG",
        )
        sin_loc = _aviation_location("SIN", "Singapore", "Singapore", 1.35, 103.99)

        keyword_calls = {"count": 0}

        def keyword_side_effect(name, sub_type="CITY,AIRPORT", limit=1):
            keyword_calls["count"] += 1
            # First call (raw "Singapour") misses, second ("Singapore") hits.
            if keyword_calls["count"] == 1:
                return []
            return [sin_loc]

        with (
            patch("src.services.location_resolver._read_cache", return_value=None),
            patch(
                "src.services.location_resolver._try_iata_passthrough",
                return_value=None,
            ),
            patch(
                "src.services.location_resolver.aviation_data_service.search_by_keyword",
                side_effect=keyword_side_effect,
            ),
            patch(
                "src.services.location_resolver.search_places",
                new=AsyncMock(return_value=[place]),
            ),
            patch("src.services.location_resolver._write_cache"),
        ):
            result = await resolve_city("Singapour", locale="fr")
        assert result is not None
        assert result.iata == "SIN"
        assert result.source == "open_meteo+airportsdata"
        # The user-facing city name preserves the localized label.
        assert result.city == "Singapore"
        # Coordinates come from Open-Meteo (more precise than airport coords).
        assert result.latitude == pytest.approx(1.28967)
        assert result.longitude == pytest.approx(103.85007)
        assert keyword_calls["count"] == 2

    @pytest.mark.asyncio
    async def test_geocoding_falls_back_to_nearest_airport(self):
        # Even the English re-attempt misses (niche city) — we should fall
        # back to nearest airport to the geocoded coords.
        place = GeocodedPlace(
            name="Faaa",
            latitude=-17.55,
            longitude=-149.61,
            country="French Polynesia",
            country_code="PF",
        )
        ppt = _aviation_location("PPT", "Papeete", "French Polynesia", -17.55, -149.61)

        with (
            patch("src.services.location_resolver._read_cache", return_value=None),
            patch(
                "src.services.location_resolver._try_iata_passthrough",
                return_value=None,
            ),
            patch(
                "src.services.location_resolver.aviation_data_service.search_by_keyword",
                return_value=[],
            ),
            patch(
                "src.services.location_resolver.search_places",
                new=AsyncMock(return_value=[place]),
            ),
            patch(
                "src.services.location_resolver.aviation_data_service.search_nearest",
                return_value=[ppt],
            ),
            patch("src.services.location_resolver._write_cache"),
        ):
            result = await resolve_city("Faaa", locale="fr")
        assert result is not None
        assert result.iata == "PPT"
        assert result.source == "open_meteo+nearest"

    @pytest.mark.asyncio
    async def test_locale_normalization(self):
        # ``fr-FR`` and ``fr_FR`` collapse to ``fr`` for cache keying.
        place = GeocodedPlace(
            name="Singapore",
            latitude=1.28,
            longitude=103.85,
            country="Singapore",
            country_code="SG",
        )
        sin_loc = _aviation_location("SIN", "Singapore", "Singapore", 1.35, 103.99)
        cache_writes: list[tuple[str, str, str]] = []

        def fake_write(query, locale, resolved):
            cache_writes.append((query, locale, resolved.iata))

        keyword_calls = {"count": 0}

        def keyword_side_effect(name, sub_type="CITY,AIRPORT", limit=1):
            keyword_calls["count"] += 1
            return [] if keyword_calls["count"] == 1 else [sin_loc]

        with (
            patch("src.services.location_resolver._read_cache", return_value=None),
            patch(
                "src.services.location_resolver._try_iata_passthrough",
                return_value=None,
            ),
            patch(
                "src.services.location_resolver.aviation_data_service.search_by_keyword",
                side_effect=keyword_side_effect,
            ),
            patch(
                "src.services.location_resolver.search_places",
                new=AsyncMock(return_value=[place]),
            ),
            patch(
                "src.services.location_resolver._write_cache",
                side_effect=fake_write,
            ),
        ):
            await resolve_city("Singapour", locale="fr-FR,en;q=0.8")
        assert cache_writes, "expected resolver to persist a cache entry"
        _, locale_used, iata = cache_writes[0]
        assert locale_used == "fr"
        assert iata == "SIN"

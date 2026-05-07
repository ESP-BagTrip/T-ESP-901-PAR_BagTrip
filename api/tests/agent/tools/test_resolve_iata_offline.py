"""Smoke tests for the ``resolve_iata_code`` agent tool façade.

Since SMP-324 the heavy cascade lives in
:mod:`src.services.location_resolver` and is exhaustively tested in
``tests/services/test_location_resolver.py``. The thin façade kept
under ``src.agent.tools.locations`` only transforms the resolver's
``ResolvedCity | None`` into the dict shape the agent expects, so the
tests below stay focused on that dict translation and on the
exception-safety contract.
"""

from unittest.mock import AsyncMock, patch

import pytest

from src.agent.tools import resolve_iata_code
from src.services.location_resolver import ResolvedCity


def _make_resolved(
    iata: str,
    city: str,
    country: str,
    lat: float,
    lon: float,
    *,
    source: str = "airportsdata.keyword",
) -> ResolvedCity:
    return ResolvedCity(
        iata=iata,
        city=city,
        country=country,
        country_code="",
        latitude=lat,
        longitude=lon,
        source=source,
    )


class TestResolveIataCodeFacade:
    @pytest.mark.asyncio
    async def test_translates_resolved_city_into_legacy_dict(self):
        with patch(
            "src.agent.tools.locations.resolve_city",
            new=AsyncMock(return_value=_make_resolved("CDG", "Paris", "France", 49.01, 2.55)),
        ):
            result = await resolve_iata_code("Paris")
        assert result == {
            "iata": "CDG",
            "city": "Paris",
            "country": "France",
            "lat": 49.01,
            "lon": 2.55,
        }

    @pytest.mark.asyncio
    async def test_unresolved_returns_error_dict(self):
        with patch(
            "src.agent.tools.locations.resolve_city",
            new=AsyncMock(return_value=None),
        ):
            result = await resolve_iata_code("Atlantis")
        assert "error" in result
        assert "Atlantis" in result["error"]

    @pytest.mark.asyncio
    async def test_resolver_exception_is_translated_into_error_dict(self):
        with patch(
            "src.agent.tools.locations.resolve_city",
            new=AsyncMock(side_effect=RuntimeError("data corrupted")),
        ):
            result = await resolve_iata_code("Berlin")
        assert "error" in result
        assert "data corrupted" in result["error"]

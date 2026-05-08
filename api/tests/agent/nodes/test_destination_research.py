"""Unit tests for ``agent.nodes.destination_research`` pre-selected path."""

from __future__ import annotations

from unittest.mock import AsyncMock, patch

import pytest

from src.agent.nodes.destination_research import destination_research_node
from src.services.location_resolver import ResolvedCity


def _resolved_singapore() -> ResolvedCity:
    return ResolvedCity(
        iata="SIN",
        city="Singapore",
        country="Singapore",
        country_code="SG",
        latitude=1.35,
        longitude=103.99,
        source="open_meteo+airportsdata",
    )


def _resolved_paris() -> ResolvedCity:
    return ResolvedCity(
        iata="CDG",
        city="Paris",
        country="France",
        country_code="FR",
        latitude=49.0,
        longitude=2.55,
        source="airportsdata.keyword",
    )


@pytest.mark.asyncio
async def test_pre_selected_destination_resolves_localized_city():
    """The Singapour bug: French city name must reach the resolver cascade."""

    async def fake_resolve(value, *, locale):
        if value in ("Singapour", "SIN"):
            return _resolved_singapore()
        if value in ("Paris", "CDG"):
            return _resolved_paris()
        return None

    state = {
        "destination_city": "Singapour",
        "destination_iata": "",
        "origin_city": "Paris",
        "departure_date": "2026-08-15",
        "return_date": "2026-08-22",
        "locale": "fr",
    }

    fake_weather = {"avg_temp_c": 28, "min_temp_c": 24, "max_temp_c": 32}
    weather_fn = AsyncMock(return_value=fake_weather)

    with (
        patch(
            "src.agent.nodes.destination_research.resolve_city",
            new=AsyncMock(side_effect=fake_resolve),
        ),
        patch.dict(
            "src.agent.nodes.destination_research.TOOL_REGISTRY",
            {"get_weather": {"fn": weather_fn}},
            clear=False,
        ),
    ):
        result = await destination_research_node(state)

    assert result["selected_destination"]["iata"] == "SIN"
    assert result["selected_destination"]["city"] == "Singapore"
    assert result["selected_destination"]["country"] == "Singapore"
    assert result["selected_destination"]["lat"] == 1.35
    assert result["origin_iata"] == "CDG"
    # Weather tool got real coords from the resolver, not 0/0.
    weather_fn.assert_awaited_once()
    weather_kwargs = weather_fn.call_args.kwargs
    assert weather_kwargs["latitude"] == 1.35
    assert weather_kwargs["longitude"] == 103.99
    # SSE event echoes the same data so the front renders the right card.
    events = result["events"]
    assert events[0]["event"] == "destinations"
    assert events[0]["data"]["origin_iata"] == "CDG"


@pytest.mark.asyncio
async def test_pre_selected_destination_with_iata_only():
    """Passing only the IATA must hydrate city + country via the cascade."""

    async def fake_resolve(value, *, locale):
        return _resolved_singapore() if value == "SIN" else None

    state = {
        "destination_city": "",
        "destination_iata": "SIN",
        "origin_city": "",
        "departure_date": "2026-08-15",
        "return_date": "2026-08-22",
        "locale": "en",
    }

    weather_fn = AsyncMock(return_value={"avg_temp_c": 28})

    with (
        patch(
            "src.agent.nodes.destination_research.resolve_city",
            new=AsyncMock(side_effect=fake_resolve),
        ),
        patch.dict(
            "src.agent.nodes.destination_research.TOOL_REGISTRY",
            {"get_weather": {"fn": weather_fn}},
            clear=False,
        ),
    ):
        result = await destination_research_node(state)

    assert result["selected_destination"]["iata"] == "SIN"
    assert result["selected_destination"]["city"] == "Singapore"
    assert result["selected_destination"]["country"] == "Singapore"


@pytest.mark.asyncio
async def test_pre_selected_destination_resolver_miss_keeps_originals():
    """When the cascade returns nothing the node must not crash and must
    still emit the destinations event with whatever data it has."""

    state = {
        "destination_city": "Atlantis",
        "destination_iata": "",
        "origin_city": "Paris",
        "departure_date": "2026-08-15",
        "return_date": "2026-08-22",
        "locale": "en",
    }

    async def resolver_returning_none(value, *, locale):
        return None

    with (
        patch(
            "src.agent.nodes.destination_research.resolve_city",
            new=AsyncMock(side_effect=resolver_returning_none),
        ),
        patch.dict(
            "src.agent.nodes.destination_research.TOOL_REGISTRY",
            {"get_weather": {"fn": AsyncMock(return_value={})}},
            clear=False,
        ),
    ):
        result = await destination_research_node(state)

    assert result["selected_destination"]["city"] == "Atlantis"
    assert result["selected_destination"]["iata"] == ""
    # The pipeline still shipped a destinations event so SSE doesn't stall.
    assert result["events"][0]["event"] == "destinations"

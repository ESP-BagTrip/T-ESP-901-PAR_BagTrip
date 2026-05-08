"""Shared fixtures + stubs for the eval harness.

The eval harness is hermetic: every external integration (Amadeus,
Open-Meteo, BGE-M3 embeddings, the LLM router) is stubbed. The point
of these tests is to pin the **shape** of the output a real production
run must produce given a fixed input — they do not exercise the
external services themselves (those are covered by the Phase 0 PoC
script and live smoke runs).

Stubs are applied through ``monkeypatch`` so the suite stays parallel-
safe: each test gets a fresh router/cache state via the autouse fixture
below.
"""

from __future__ import annotations

import json
from collections.abc import Generator, Iterable
from typing import Any
from unittest.mock import AsyncMock, MagicMock

import pytest

from src.services.llm_router import LLMRouter
from src.utils.idempotency import idempotency_cache


@pytest.fixture(autouse=True)
def _isolate_eval_state() -> Generator[None]:
    """Reset router + cache between every eval case."""
    LLMRouter.reset_for_tests()
    idempotency_cache._memory_cache.clear()  # type: ignore[attr-defined]
    yield
    LLMRouter.reset_for_tests()
    idempotency_cache._memory_cache.clear()  # type: ignore[attr-defined]


# ── LLM stubs ─────────────────────────────────────────────────────────


def llm_chat_stub(content: str | dict | list) -> AsyncMock:
    """Build an :class:`AsyncMock` that returns an OpenAI-shaped reply.

    The ``content`` argument is serialised to JSON when it isn't already
    a string, which keeps the call sites tidy.
    """
    payload = content if isinstance(content, str) else json.dumps(content)
    return AsyncMock(
        return_value={
            "choices": [{"message": {"role": "assistant", "content": payload}}],
            "usage": {"prompt_tokens": 100, "completion_tokens": 100},
        }
    )


def llm_embed_stub(vectors: Iterable[list[float]]) -> AsyncMock:
    """Return a fixed batch of embedding vectors per call."""
    return AsyncMock(return_value=list(vectors))


# ── Amadeus inspire stubs ─────────────────────────────────────────────


def amadeus_inspire_response(rows: list[dict[str, Any]]) -> Any:
    """Return a stub matching the bits the inspire orchestrator reads.

    Each row is ``{iata, dep_date, ret_date, price}`` (the same shape
    the W1 unit test fixtures use).
    """
    data = []
    for r in rows:
        item = MagicMock()
        item.destination = r["iata"]
        item.departureDate = r.get("dep_date", "2026-07-04")
        item.returnDate = r.get("ret_date", "2026-07-10")
        price = MagicMock()
        price.total = str(r.get("price", "120"))
        item.price = price
        data.append(item)
    return _SimpleResponse(data=data)


# ── Amadeus hotel stubs ───────────────────────────────────────────────


def amadeus_hotel_list_response(hotel_ids: list[str]) -> Any:
    return _SimpleResponse(data=[MagicMock(hotelId=hid, name=f"Hotel {hid}") for hid in hotel_ids])


def amadeus_hotel_offers_response(rows: list[dict[str, Any]]) -> Any:
    """Each row is ``{name, hotel_id, price_total, currency}``."""
    out = []
    for r in rows:
        offer_price = MagicMock()
        offer_price.total = str(r["price_total"])
        offer_price.currency = r.get("currency", "EUR")
        offer = MagicMock()
        offer.price = offer_price
        out.append(
            MagicMock(
                hotel={"name": r["name"], "hotelId": r["hotel_id"]},
                offers=[offer],
            )
        )
    return _SimpleResponse(data=out)


# ── Amadeus flight offers stubs ───────────────────────────────────────


def amadeus_flight_offers_response(legs: list[dict[str, Any]]) -> Any:
    """Build a single FlightOffer with the supplied itinerary segments.

    Each leg dict provides ``carrier``, ``number``, ``origin``,
    ``destination``, ``departure_at``, ``arrival_at``, ``price`` and
    optionally ``currency``.
    """
    if not legs:
        return _SimpleResponse(data=[])
    total = sum(leg.get("price", 0) for leg in legs)
    currency = legs[0].get("currency", "EUR")
    price = MagicMock()
    price.total = str(total)
    price.currency = currency
    itineraries = []
    for leg in legs:
        dep_endpoint = MagicMock(iataCode=leg["origin"], at=leg["departure_at"])
        arr_endpoint = MagicMock(iataCode=leg["destination"], at=leg["arrival_at"])
        seg = MagicMock(
            departure=dep_endpoint,
            arrival=arr_endpoint,
            carrierCode=leg.get("carrier", ""),
            number=leg.get("number", ""),
        )
        itineraries.append(MagicMock(segments=[seg]))
    offer = MagicMock(price=price, itineraries=itineraries)
    return _SimpleResponse(data=[offer])


# ── Helpers ───────────────────────────────────────────────────────────


class _SimpleResponse:
    """Mimic the ``data`` attribute of every Amadeus pydantic response."""

    def __init__(self, data: list[Any]) -> None:
        self.data = data


async def drain(agen) -> list[tuple[str, dict]]:
    """Drain an SSE-shaped async generator into a list of ``(event, data)``."""
    return [item async for item in agen]


# Re-exported for tests
__all__ = [
    "_SimpleResponse",
    "amadeus_flight_offers_response",
    "amadeus_hotel_list_response",
    "amadeus_hotel_offers_response",
    "amadeus_inspire_response",
    "drain",
    "llm_chat_stub",
    "llm_embed_stub",
]

"""Accommodation node — direct Amadeus hotel lookup, no ReAct.

The previous implementation wrapped ``search_real_hotels`` in a ReAct
loop and asked the LLM to "use the tool". On the Paris -> Tokyo
generation that surfaced exactly the same fragility as the budget node:

    [INFO]  ReAct LLM response (iter 1):
            "Thought: Use the search_real_hotels tool to find hotels in Tokyo
             for the given dates for 2 adults."
    [WARN]  ReAct parse: no Action or Final Answer found, treating as final answer
    [WARN]  react_executor: JSON parse failed, attempting repair
    [INFO]  Accommodation search complete  count: 0  source: estimated

The LLM emitted a thought without an action, the parser treated the
text as a Final Answer, JSON parsing fell back to ``{"thought": ...}``
with no ``accommodations`` key, and the review screen rendered the
"À déterminer" placeholder with no hotel attached.

There is no actual reasoning required at this step — we just need the
hotel list for a given city + dates. Call the Amadeus wrapper
directly, fall back to a deterministic placeholder when Amadeus
returns nothing, and remove the ReAct dependency entirely.
"""

from __future__ import annotations

from src.agent.runtime_budget import guard
from src.agent.state import TripPlanState
from src.agent.tools.hotels import search_real_hotels
from src.utils.logger import logger


async def accommodation_node(state: TripPlanState) -> dict:
    """Search real hotel prices using Amadeus directly."""
    guard(state, min_required=2.0)
    logger.info("=== Accommodation Node ===")

    dest = state.get("selected_destination", {})
    iata = dest.get("iata", "")
    check_in = state.get("departure_date", "")
    check_out = state.get("return_date", "") or check_in
    nb_travelers = int(state.get("nb_travelers") or 1) or 1

    accommodations: list[dict] = []
    source = "estimated"

    if iata and check_in and check_out:
        try:
            result = await search_real_hotels(
                city_code=iata,
                check_in=check_in,
                check_out=check_out,
                adults=nb_travelers,
            )
        except Exception as exc:
            logger.warn(
                "accommodation_node: Amadeus hotel search raised",
                {"iata": iata, "error": str(exc)},
            )
            result = {"hotels": [], "source": "error"}
        accommodations = result.get("hotels", []) or []
        if accommodations and result.get("source") == "amadeus":
            source = "amadeus"

    if not accommodations:
        # Synthesize a placeholder so the review screen shows a tile
        # instead of "À déterminer". The user can still book later via
        # trip_detail; the placeholder is clearly marked as estimated.
        placeholder = _synthesize_accommodation_placeholder(state, dest)
        if placeholder:
            accommodations = [placeholder]

    logger.info(
        "Accommodation search complete",
        {"count": len(accommodations), "source": source},
    )

    return {
        "accommodations": accommodations,
        "events": [
            {
                "event": "accommodations",
                "data": {"accommodations": accommodations, "source": source},
            },
        ],
    }


# Per-night placeholder budget (EUR / room / night). Coarse but shaped to
# the same budget bands the budget node uses, so the review screen
# numbers stay internally consistent.
_PLACEHOLDER_NIGHTLY_RATE: dict[str, float] = {
    "low": 60.0,
    "mid": 120.0,
    "premium": 280.0,
}


def _synthesize_accommodation_placeholder(state: TripPlanState, destination: dict) -> dict | None:
    """Build a single ``estimated`` accommodation entry.

    Used when Amadeus returns no offers (sandbox unavailable, niche
    city, dates outside the inventory window). Mirrors the ``estimated``
    flight-offer pattern: a clearly marked source = "estimated", a
    plausible price tied to ``budget_preset``, and the trip dates so
    downstream code (budget aggregation, persist on accept) can reason
    about nights × rate without re-deriving them.
    """
    check_in = state.get("departure_date", "") or ""
    check_out = state.get("return_date", "") or ""
    if not (check_in and check_out):
        return None
    duration_days = int(state.get("duration_days") or 1) or 1
    nights = max(duration_days, 1)
    preset = (state.get("budget_preset") or "mid").lower()
    nightly = _PLACEHOLDER_NIGHTLY_RATE.get(preset, _PLACEHOLDER_NIGHTLY_RATE["mid"])
    price_total = round(nightly * nights, 2)

    city = destination.get("city") or ""
    return {
        "name": f"À déterminer · {city}".strip(" ·") or "À déterminer",
        "hotel_id": "",
        "rating": None,
        "price_total": price_total,
        "price_per_night": nightly,
        "nights": nights,
        "adults": int(state.get("nb_travelers") or 1) or 1,
        "currency": "EUR",
        "check_in": check_in,
        "check_out": check_out,
        "source": "estimated",
    }

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


def _synthesize_accommodation_placeholder(state: TripPlanState, destination: dict) -> dict | None:
    """Return a deferred-accommodation marker for the review screen.

    Used when Amadeus returns no offers (sandbox unavailable, niche
    city, dates outside the inventory window). The previous version
    fabricated a hotel called ``"À déterminer · {city}"`` with a
    ``price_per_night`` from a coarse budget-preset table. That
    backfired in two ways the user immediately spotted on the Tokyo
    trial:

    - the front renders the per-night value with no unit suffix, so
      "120 EUR" reads as "for the whole stay", which is absurd next
      to a 7-night Tokyo trip;
    - the value was made up — there is no ground truth that says a
      mid-band Tokyo hotel costs 120 EUR/night, and presenting an
      invented number as if it were real undermines the rest of the
      generated plan.

    We now return a minimal marker (no name, no per-night, no total)
    and let the front render an unambiguous "Hôtel à choisir · {city}
    · N nuits" placeholder. The accommodation budget line is still
    produced by ``budget_node`` from its per-diem table, so the
    *budget* the user sees stays informed; we just stop pretending we
    found a *hotel*.

    The ``source="deferred"`` marker lets the front widget tell this
    case apart from a real Amadeus hit (``"amadeus"``).
    """
    check_in = state.get("departure_date", "") or ""
    check_out = state.get("return_date", "") or ""
    if not (check_in and check_out):
        return None
    duration_days = int(state.get("duration_days") or 1) or 1
    nights = max(duration_days, 1)

    return {
        "name": "",
        "hotel_id": "",
        "rating": None,
        "price_total": None,
        "price_per_night": None,
        "nights": nights,
        "adults": int(state.get("nb_travelers") or 1) or 1,
        "currency": "EUR",
        "check_in": check_in,
        "check_out": check_out,
        "source": "deferred",
    }

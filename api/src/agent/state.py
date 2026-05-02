"""Trip planning graph state definition."""

from __future__ import annotations

import operator
from typing import Annotated, TypedDict


class TripPlanState(TypedDict, total=False):
    """State shared across all nodes in the trip planning graph.

    Fields with Annotated[..., operator.add] use a reducer — parallel nodes
    can safely append to them without overwriting each other.
    """

    # === Input (set once at graph invocation) ===
    travel_types: str
    budget_range: str
    duration_days: int
    companions: str
    constraints: str
    departure_date: str  # YYYY-MM-DD
    return_date: str  # YYYY-MM-DD
    origin_city: str
    travel_style: str
    season: str
    nb_travelers: int
    budget_preset: str
    date_mode: str
    destination_city: str  # Pre-selected destination (manual flow)
    destination_iata: str  # Pre-selected destination IATA code

    # === Destination research output ===
    origin_iata: str  # Resolved IATA for user's origin city
    destinations: list[dict]
    selected_destination: dict  # {city, country, iata, lat, lon}
    weather_data: dict  # {avg_temp_c, min_temp_c, max_temp_c, rain_probability, description}

    # === Parallel agent outputs (each node writes its own field) ===
    activities: list[dict]
    accommodations: list[dict]
    baggage_items: list[dict]

    # === Budget output ===
    budget_estimation: dict
    flight_offers: list[dict]  # Raw Amadeus flight offers for Flutter display

    # === Accumulated across nodes (need reducer for parallel fan-in) ===
    events: Annotated[list[dict], operator.add]
    errors: Annotated[list[str], operator.add]

    # === Final assembled plan ===
    trip_plan: dict

    # === Graph budget tracking (Sprint 3) ===
    # Monotonic deadline past which the graph must abort — set once by
    # `TripPlannerService._build_initial_state`. Nodes consult it via
    # `src.agent.runtime_budget.remaining` / `guard`.
    budget_deadline_monotonic: float
    budget_consumed_seconds: float

    # === Locale (Sprint 4) ===
    # Picked from `PlanTripRequest.locale` or `Accept-Language`, then passed
    # to `prompts.render(name, locale=...)` by every node. `"en"` is the
    # canonical fallback and is what ships today — FR templates are stubs
    # that include the EN versions until they're translated.
    locale: str

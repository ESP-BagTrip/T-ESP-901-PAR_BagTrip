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

    # === Destination research output ===
    destinations: list[dict]
    selected_destination: dict  # {city, country, iata, lat, lon}
    weather_data: dict  # {avg_temp_c, min_temp_c, max_temp_c, rain_probability, description}

    # === Parallel agent outputs (each node writes its own field) ===
    activities: list[dict]
    accommodations: list[dict]
    baggage_items: list[dict]

    # === Budget output ===
    budget_estimation: dict

    # === Accumulated across nodes (need reducer for parallel fan-in) ===
    events: Annotated[list[dict], operator.add]
    errors: Annotated[list[str], operator.add]

    # === Final assembled plan ===
    trip_plan: dict

"""Tests for Phase 2a (API-3): new fields flow to initial_state."""

from src.agent.state import TripPlanState
from src.api.ai.plan_trip_schemas import PlanTripRequest


def _build_initial_state(request: PlanTripRequest) -> TripPlanState:
    """Mirror the initial_state construction from plan_trip_routes._trip_plan_generator."""
    return {
        "travel_types": request.travelTypes or "",
        "budget_range": request.budgetRange or "",
        "duration_days": request.durationDays or 7,
        "companions": request.companions or "solo",
        "constraints": request.constraints or "",
        "departure_date": request.departureDate or "",
        "return_date": request.returnDate or "",
        "origin_city": request.originCity or "",
        "travel_style": request.travelStyle or "",
        "season": request.season or "",
        "nb_travelers": request.nbTravelers or 1,
        "budget_preset": request.budgetPreset or "",
        "date_mode": request.dateMode or "",
        "events": [],
        "errors": [],
    }


def test_initial_state_includes_all_new_fields():
    req = PlanTripRequest(
        travelStyle="adventure",
        season="summer",
        nbTravelers=3,
        budgetPreset="PREMIUM",
        dateMode="FLEXIBLE",
    )
    state = _build_initial_state(req)

    assert state["travel_style"] == "adventure"
    assert state["season"] == "summer"
    assert state["nb_travelers"] == 3
    assert state["budget_preset"] == "PREMIUM"
    assert state["date_mode"] == "FLEXIBLE"


def test_initial_state_defaults_when_fields_omitted():
    req = PlanTripRequest()
    state = _build_initial_state(req)

    assert state["travel_style"] == ""
    assert state["season"] == ""
    assert state["nb_travelers"] == 1
    assert state["budget_preset"] == ""
    assert state["date_mode"] == ""


def test_initial_state_preserves_existing_fields():
    req = PlanTripRequest(
        originCity="Paris",
        durationDays=10,
        travelTypes="beach",
    )
    state = _build_initial_state(req)

    assert state["origin_city"] == "Paris"
    assert state["duration_days"] == 10
    assert state["travel_types"] == "beach"

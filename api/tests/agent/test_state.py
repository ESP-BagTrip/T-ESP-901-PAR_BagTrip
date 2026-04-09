"""Unit tests for agent state."""

from src.agent.state import TripPlanState


def test_trip_plan_state_structure():
    """Test that TripPlanState has the expected fields."""

    state: TripPlanState = {
        "travel_types": "leisure",
        "budget_range": "medium",
        "duration_days": 7,
    }

    assert state["travel_types"] == "leisure"
    assert state["budget_range"] == "medium"
    assert state["duration_days"] == 7

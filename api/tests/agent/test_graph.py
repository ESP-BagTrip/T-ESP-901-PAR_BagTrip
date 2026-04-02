"""Unit tests for agent graph structure."""

from unittest.mock import patch

import pytest


@pytest.fixture(autouse=True)
def _mock_llm():
    """Mock LLM to avoid real API calls during import."""
    with patch("src.services.llm_service.ChatOpenAI"):
        yield


def test_build_graph_has_expected_nodes():
    """Test that the main graph has the expected pipeline nodes."""
    from src.agent.graph import build_graph

    builder = build_graph()
    compiled = builder.compile()
    drawable = compiled.get_graph()
    node_names = set(drawable.nodes.keys())

    expected = {
        "destination_research",
        "activity_planner",
        "accommodation",
        "baggage",
        "budget",
        "assemble",
    }
    assert expected.issubset(node_names)


def test_build_destinations_only_graph_has_expected_nodes():
    """Test that the destinations-only graph has the expected nodes."""
    from src.agent.graph import build_destinations_only_graph

    builder = build_destinations_only_graph()
    compiled = builder.compile()
    drawable = compiled.get_graph()
    node_names = set(drawable.nodes.keys())

    assert "destination_research" in node_names
    assert "assemble_destinations" in node_names


@pytest.mark.asyncio
async def test_assemble_node_returns_trip_plan():
    """Test that assemble_node produces the expected output shape."""
    from src.agent.graph import assemble_node

    state = {
        "selected_destination": {"city": "Paris", "country": "France", "iata": "CDG"},
        "origin_iata": "JFK",
        "weather_data": {},
        "destinations": [
            {"city": "Paris", "country": "France", "iata": "CDG"},
            {"city": "Rome", "country": "Italy", "iata": "FCO"},
        ],
        "activities": [{"name": "Eiffel Tower"}],
        "accommodations": [{"name": "Hotel Le Marais"}],
        "baggage_items": [{"name": "Passport"}],
        "budget_estimation": {"total": 1500},
        "duration_days": 7,
        "departure_date": "2026-06-01",
        "return_date": "2026-06-08",
    }

    result = await assemble_node(state)

    assert "trip_plan" in result
    assert "events" in result
    assert result["trip_plan"]["destination"]["city"] == "Paris"
    assert result["trip_plan"]["origin_iata"] == "JFK"
    assert len(result["events"]) == 1
    assert result["events"][0]["event"] == "complete"

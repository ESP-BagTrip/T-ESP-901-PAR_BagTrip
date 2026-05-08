"""Unit tests for agent graph structure."""

import pytest


@pytest.fixture(autouse=True)
def _mock_llm():
    """Reset the LLMRouter singleton so graph tests stay hermetic.

    The graph wiring imports llm_service which lazy-instantiates the
    router; we don't run any LLM calls here, but we drop the cached
    HTTP client between tests to avoid leaking handlers across the
    suite.
    """
    from src.services.llm_router import LLMRouter

    LLMRouter.reset_for_tests()
    yield
    LLMRouter.reset_for_tests()


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

"""Tests for Phase 3 (API-2): destinations_only mode."""

import asyncio

from src.agent.graph import assemble_destinations_node, build_destinations_only_graph
from src.api.ai.plan_trip_schemas import PlanTripRequest


def test_schema_accepts_destinations_only_mode():
    req = PlanTripRequest(mode="destinations_only")
    assert req.mode == "destinations_only"


def test_schema_default_mode_is_none():
    req = PlanTripRequest()
    assert req.mode is None


def test_destinations_only_graph_has_two_nodes():
    g = build_destinations_only_graph()
    node_names = set(g.nodes.keys())
    assert "destination_research" in node_names
    assert "assemble_destinations" in node_names
    # Should NOT have activity_planner, accommodation, etc.
    assert "activity_planner" not in node_names
    assert "accommodation" not in node_names
    assert "baggage" not in node_names
    assert "budget" not in node_names


def test_assemble_destinations_node_returns_correct_structure():
    state = {
        "destinations": [
            {"city": "Tokyo", "country": "Japan", "iata": "TYO"},
            {"city": "Kyoto", "country": "Japan", "iata": "KIX"},
        ],
        "origin_iata": "CDG",
    }
    result = asyncio.get_event_loop().run_until_complete(
        assemble_destinations_node(state)
    )

    assert "events" in result
    assert len(result["events"]) == 1

    event = result["events"][0]
    assert event["event"] == "complete"
    assert event["data"]["mode"] == "destinations_only"
    assert event["data"]["origin_iata"] == "CDG"
    assert len(event["data"]["destinations"]) == 2


def test_assemble_destinations_node_empty_state():
    state = {}
    result = asyncio.get_event_loop().run_until_complete(
        assemble_destinations_node(state)
    )

    event = result["events"][0]
    assert event["data"]["destinations"] == []
    assert event["data"]["origin_iata"] == ""

"""LangGraph trip planning graph — orchestrates multi-agent pipeline.

Referenced by langgraph.json as: ./src/agent/graph.py:graph
"""

from __future__ import annotations

from langgraph.graph import END, START, StateGraph

from src.agent.nodes.accommodation import accommodation_node
from src.agent.nodes.activity_planner import activity_planner_node
from src.agent.nodes.baggage import baggage_node
from src.agent.nodes.budget import budget_node
from src.agent.nodes.destination_research import destination_research_node
from src.agent.state import TripPlanState
from src.utils.logger import logger


async def assemble_node(state: TripPlanState) -> dict:
    """Final assembly — combine all agent outputs into a unified trip plan."""
    logger.info("=== Assemble Node ===")

    dest = state.get("selected_destination", {})
    trip_plan = {
        "destination": {
            "city": dest.get("city", ""),
            "country": dest.get("country", ""),
            "iata": dest.get("iata", ""),
        },
        "weather": state.get("weather_data", {}),
        "alternatives": state.get("destinations", [])[1:],  # Other proposed destinations
        "activities": state.get("activities", []),
        "accommodations": state.get("accommodations", []),
        "baggage": state.get("baggage_items", []),
        "budget": state.get("budget_estimation", {}),
        "duration_days": state.get("duration_days"),
        "departure_date": state.get("departure_date"),
        "return_date": state.get("return_date"),
    }

    return {
        "trip_plan": trip_plan,
        "events": [
            {
                "event": "complete",
                "data": {"tripPlan": trip_plan},
            },
        ],
    }


def build_graph() -> StateGraph:
    """Build the trip planning state graph.

    Flow:
      START → destination_research → [activity_planner, accommodation, baggage] → budget → assemble → END

    The three middle nodes run in PARALLEL (LangGraph fan-out/fan-in).
    """
    builder = StateGraph(TripPlanState)

    # Add nodes
    builder.add_node("destination_research", destination_research_node)
    builder.add_node("activity_planner", activity_planner_node)
    builder.add_node("accommodation", accommodation_node)
    builder.add_node("baggage", baggage_node)
    builder.add_node("budget", budget_node)
    builder.add_node("assemble", assemble_node)

    # START → destination_research
    builder.add_edge(START, "destination_research")

    # destination_research → parallel fan-out to 3 nodes
    builder.add_edge("destination_research", "activity_planner")
    builder.add_edge("destination_research", "accommodation")
    builder.add_edge("destination_research", "baggage")

    # Parallel fan-in → budget (waits for all 3)
    builder.add_edge("activity_planner", "budget")
    builder.add_edge("accommodation", "budget")
    builder.add_edge("baggage", "budget")

    # budget → assemble → END
    builder.add_edge("budget", "assemble")
    builder.add_edge("assemble", END)

    return builder


# Compiled graph instance (referenced by langgraph.json)
graph = build_graph().compile()

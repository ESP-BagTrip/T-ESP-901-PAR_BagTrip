"""Retry wrapper for LangGraph nodes with graceful degradation."""

from __future__ import annotations

from src.utils.logger import logger

_NODE_FIELD_MAP = {
    "activity_planner": "activities",
    "accommodation": "accommodations",
    "baggage": "baggage_items",
}


async def with_retry(node_fn, state, node_name: str, max_retries: int = 1):
    """Run a node with retry. On total failure, return degraded result + warning SSE."""
    last_error = None
    for attempt in range(max_retries + 1):
        try:
            return await node_fn(state)
        except Exception as e:
            last_error = e
            if attempt < max_retries:
                logger.warn(
                    f"Node {node_name} attempt {attempt + 1} failed, retrying",
                    {"error": str(e)},
                )

    # All retries exhausted — graceful degradation
    logger.error(
        f"Node {node_name} failed after {max_retries + 1} attempts",
        {"error": str(last_error)},
    )
    field = _NODE_FIELD_MAP.get(node_name, node_name)
    return {
        field: [],
        "events": [
            {
                "event": "warning",
                "data": {"section": node_name, "message": f"{node_name} unavailable"},
            }
        ],
        "errors": [f"{node_name} failed after {max_retries + 1} attempts: {last_error}"],
    }

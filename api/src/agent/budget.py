"""Graph-level time budget primitive for the LangGraph pipeline.

## Problem

`settings.GRAPH_TIMEOUT_SECONDS` caps the **total** time the stream can run,
enforced outside the graph by `async_generator_with_timeout` in
`trip_planner_service`. `settings.NODE_TIMEOUT_SECONDS` caps each individual
`with_retry`-wrapped node. Neither ensures the graph respects a **cumulative**
budget — a chain of slow nodes can each finish under its per-node timeout
while collectively blowing past the total. And three nodes
(`destination_research`, `budget`, `assemble`) aren't wrapped at all.

## Solution

A shared deadline stored in the graph state as a `time.monotonic()` value.
Every node can check "how much time do I have left?" and abort early if the
remainder wouldn't justify another LLM call. The budget is set once at graph
entry (`TripPlannerService._build_initial_state`) and referenced by every
node wrapper.

## Usage

```python
from src.agent.budget import BudgetExceeded, guard, remaining, track

async def my_node(state: TripPlanState) -> dict:
    guard(state, min_required=5.0)  # raise if < 5s left
    async with track(state, "my_node"):
        # ... heavy work, respects remaining(state) internally
        await asyncio.wait_for(heavy_call(), timeout=remaining(state))
```

`BudgetExceeded` propagates to `trip_planner_service`, which emits an `error`
SSE event and still sends the `done` signal via the existing `try/finally`
block so clients don't hang.
"""

from __future__ import annotations

import time
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from typing import Any

from src.utils.logger import logger

# The agent graph state is a `TypedDict` (`TripPlanState`), which mypy
# treats as distinct from `MutableMapping[str, Any]` because TypedDicts
# restrict their key set. `Any` lets both TypedDict instances (production
# nodes) and plain dicts (unit tests) flow through without explicit casts.
_StateLike = Any


class BudgetExceededError(Exception):
    """Raised when a node tries to run past the graph's cumulative deadline."""


# Backward-compat alias for the exception — some nodes may still import the
# shorter name. `BudgetExceededError` is the canonical name going forward.
BudgetExceeded = BudgetExceededError


def remaining(state: _StateLike) -> float:
    """Return seconds left before the graph deadline.

    A state without `budget_deadline_monotonic` (e.g. legacy picklend
    checkpoints, test fixtures) is treated as unbounded so behavior stays
    backward compatible.
    """
    deadline = state.get("budget_deadline_monotonic")
    if deadline is None:
        return float("inf")
    return max(0.0, float(deadline) - time.monotonic())


def consumed(state: _StateLike) -> float:
    """Return how many seconds node bodies have already burned."""
    return float(state.get("budget_consumed_seconds", 0.0))


def guard(state: _StateLike, *, min_required: float = 0.0) -> None:
    """Raise `BudgetExceededError` if less than `min_required` seconds remain.

    Call this at the top of each node to fail fast instead of starting a
    long-running LLM call that has no chance of finishing inside the budget.
    """
    left = remaining(state)
    if left < min_required:
        raise BudgetExceededError(
            f"Graph budget exhausted: {left:.1f}s left, need at least "
            f"{min_required:.1f}s. Consumed so far: {consumed(state):.1f}s.",
        )


@asynccontextmanager
async def track(state: _StateLike, node_name: str) -> AsyncIterator[None]:
    """Record how long the wrapped block takes and add it to the cumulative total.

    This runs regardless of whether the body raises — the `finally` branch
    ensures even failed nodes count against the budget (they consumed time).
    """
    start = time.monotonic()
    try:
        yield
    finally:
        elapsed = time.monotonic() - start
        state["budget_consumed_seconds"] = consumed(state) + elapsed
        left = remaining(state)
        if left < 5.0:
            logger.warn(
                f"agent.budget: node '{node_name}' finished with {left:.1f}s left "
                f"(consumed so far: {consumed(state):.1f}s)",
            )

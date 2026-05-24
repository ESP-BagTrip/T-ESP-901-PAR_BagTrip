"""Role-aware redaction helpers (topic 06, B9).

Centralises the rule "a masked value must never be reconstructible from
another field still exposed" (CLAUDE.md). Today only the budget summary
is concerned, but the helper is shaped so additional surfaces can be
plugged in.
"""

from __future__ import annotations

from typing import Literal

from src.api.auth.trip_access import TripRole

BudgetSemanticStatus = Literal["onTrack", "tight", "overBudget"]


def _semantic_status(target: float, spent: float) -> BudgetSemanticStatus | None:
    """Map a (target, spent) pair to a coarse-grained status the viewer can see.

    Three buckets, no exact ratio leaked:
    - ``onTrack`` — under 80% of the target
    - ``tight``  — between 80% and 100%
    - ``overBudget`` — at or above 100%

    Returns ``None`` when the trip has no target — the viewer panel then
    shows nothing rather than a misleading bucket.
    """
    if target <= 0:
        return None
    ratio = spent / target
    if ratio >= 1.0:
        return "overBudget"
    if ratio >= 0.8:
        return "tight"
    return "onTrack"


def redact_budget_summary_for_role(summary: dict, role: TripRole) -> dict:
    """Strip viewer-only sensitive fields from a budget summary dict.

    Owners / editors get the dict unchanged. Viewers get a payload that
    keeps the target shape (so the panel can render its layout) and the
    semantic ``budget_status`` bucket but drops every reconstructible
    monetary field. The route still pads the response with the schema
    keys it requires (``total_spent=0``, ``remaining=0``, ``by_category={}``,
    ``budget_actual=0``); this helper is the single source of truth for
    what the viewer is allowed to know.
    """
    if role != TripRole.VIEWER:
        return summary

    target = float(summary.get("budget_target") or summary.get("total_budget") or 0)
    spent = float(summary.get("total_spent") or 0)
    return {
        "total_budget": target,
        "budget_target": target,
        # B9 — these three are reconstructible together, so all three drop.
        "budget_estimated": None,
        "budget_actual": 0.0,
        "total_spent": 0.0,
        "remaining": 0.0,
        "by_category": {},
        "percent_consumed": None,
        "confirmed_total": 0.0,
        "forecasted_total": 0.0,
        # Replaces the leak-prone f-string alert_message with a status
        # bucket the viewer can render as "On track / Tight / Over budget"
        # without revealing the underlying ratio.
        "alert_level": None,
        "alert_message": None,
        "budget_status": _semantic_status(target, spent),
    }

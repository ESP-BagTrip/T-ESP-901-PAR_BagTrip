"""Schemas for the plan-trip SSE endpoint."""

from pydantic import BaseModel, Field

BUDGET_PRESET_RANGES = {
    "BACKPACKER": {
        "min_per_day": 0,
        "max_per_day": 50,
        "label": "budget/backpacker (< 50 EUR/day/person)",
    },
    "COMFORTABLE": {
        "min_per_day": 50,
        "max_per_day": 150,
        "label": "comfortable (50-150 EUR/day/person)",
    },
    "PREMIUM": {
        "min_per_day": 150,
        "max_per_day": 500,
        "label": "premium (150-500 EUR/day/person)",
    },
    "NO_LIMIT": {"min_per_day": 0, "max_per_day": None, "label": "no budget limit"},
}


class PlanTripRequest(BaseModel):
    """Request body for POST /v1/ai/plan-trip/stream.

    Supports two modes:
    - ``mode=None`` or ``mode="full"`` — full multi-agent pipeline
    - ``mode="destinations_only"`` — lightweight destination research only
    """

    travelTypes: str | None = None
    budgetRange: str | None = None
    durationDays: int | None = None
    companions: str | None = None
    season: str | None = None
    constraints: str | None = None
    departureDate: str | None = Field(None, description="YYYY-MM-DD")
    returnDate: str | None = Field(None, description="YYYY-MM-DD")
    originCity: str | None = None
    destinationCity: str | None = None
    destinationIata: str | None = None
    travelStyle: str | None = None
    nbTravelers: int | None = 1
    dateMode: str | None = None
    budgetPreset: str | None = None
    targetBudget: float | None = Field(
        None,
        description=(
            "Numeric budget target the user explicitly committed to in the wizard "
            "(topic 01, B2/B6/B7). Lands in the LangGraph state as "
            "`target_budget` so the agent can treat it as a constraint instead "
            "of recomputing it from the breakdown."
        ),
    )
    preferredMonth: int | None = Field(None, description="1-12, for dateMode=month")
    preferredYear: int | None = Field(None, description="e.g. 2027, for dateMode=month")
    mode: str | None = Field(None, description="'full' (default) or 'destinations_only'")
    locale: str = Field(
        "en",
        description="Prompt locale ('en' or 'fr'). Missing translations fall back to English.",
    )


# Alias for Sprint 2.8 documentation
PlanTripUnifiedRequest = PlanTripRequest


class AcceptPlanRequest(BaseModel):
    """Request body for POST /v1/ai/plan-trip/accept."""

    suggestion: dict
    originCity: str | None = None
    startDate: str | None = None
    endDate: str | None = None
    dateMode: str | None = Field(None, description="EXACT, MONTH, or FLEXIBLE")
    selectedDestinationIndex: int = Field(0, description="Index in destinations list (0 = primary)")

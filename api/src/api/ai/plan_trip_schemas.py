"""Schemas for the plan-trip SSE endpoint."""

from pydantic import BaseModel, Field


class PlanTripRequest(BaseModel):
    """Request body for POST /v1/ai/plan-trip/stream."""

    travelTypes: str | None = None
    budgetRange: str | None = None
    durationDays: int | None = None
    companions: str | None = None
    season: str | None = None
    constraints: str | None = None
    departureDate: str | None = Field(None, description="YYYY-MM-DD")
    returnDate: str | None = Field(None, description="YYYY-MM-DD")
    originCity: str | None = None
    travelStyle: str | None = None
    nbTravelers: int | None = 1


class AcceptPlanRequest(BaseModel):
    """Request body for POST /v1/ai/plan-trip/accept."""

    suggestion: dict
    startDate: str | None = None
    endDate: str | None = None

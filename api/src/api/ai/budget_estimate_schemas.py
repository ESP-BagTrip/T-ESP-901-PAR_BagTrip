"""Schemas pour l'estimation de budget IA."""

from pydantic import BaseModel


class BudgetEstimationItem(BaseModel):
    accommodation_per_night: float | None = None
    meals_per_day_per_person: float | None = None
    local_transport_per_day: float | None = None
    activities_total: float | None = None
    total_min: float | None = None
    total_max: float | None = None
    currency: str = "EUR"
    breakdown_notes: str | None = None


class BudgetEstimationResponse(BaseModel):
    estimation: BudgetEstimationItem


class BudgetEstimateAcceptRequest(BaseModel):
    budget_total: float

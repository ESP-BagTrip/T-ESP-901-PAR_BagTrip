import datetime as dt
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from src.api.common.base_schema import BagtripRequestModel
from src.enums import BudgetCategory


class BudgetItemCreateRequest(BagtripRequestModel):
    label: str
    amount: float
    category: BudgetCategory | None = None
    date: dt.date | None = None
    isPlanned: bool | None = None


class BudgetItemUpdateRequest(BagtripRequestModel):
    label: str | None = None
    amount: float | None = None
    category: BudgetCategory | None = None
    date: dt.date | None = None
    isPlanned: bool | None = None


class BudgetItemResponse(BaseModel):
    id: UUID
    tripId: UUID = Field(alias="trip_id")
    label: str
    amount: float
    category: str
    date: dt.date | None = None
    isPlanned: bool = Field(alias="is_planned")
    sourceType: str | None = Field(None, alias="source_type")
    sourceId: UUID | None = Field(None, alias="source_id")
    createdAt: dt.datetime = Field(alias="created_at")
    updatedAt: dt.datetime = Field(alias="updated_at")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class BudgetItemListResponse(BaseModel):
    items: list[BudgetItemResponse]


class BudgetEstimateResponse(BaseModel):
    estimation: dict


class AcceptEstimateRequest(BagtripRequestModel):
    """Payload of POST /trips/{id}/budget/estimate/accept.

    The amount lands on ``Trip.budget_estimated``; the user's
    ``Trip.budget_target`` is preserved (B3, topic 02).
    """

    budget_estimated: float = Field(..., alias="budget_estimated", gt=0)


class BudgetSummaryResponse(BaseModel):
    totalBudget: float = Field(alias="total_budget")
    budgetTarget: float = Field(alias="budget_target")
    budgetEstimated: float | None = Field(None, alias="budget_estimated")
    budgetActual: float = Field(0, alias="budget_actual")
    totalSpent: float = Field(alias="total_spent")
    remaining: float
    byCategory: dict[str, float] = Field(alias="by_category")
    percentConsumed: float | None = Field(None, alias="percent_consumed")
    alertLevel: str | None = Field(None, alias="alert_level")
    alertMessage: str | None = Field(None, alias="alert_message")
    confirmedTotal: float = Field(0, alias="confirmed_total")
    forecastedTotal: float = Field(0, alias="forecasted_total")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

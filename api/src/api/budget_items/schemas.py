from datetime import date
from uuid import UUID

from pydantic import BaseModel, Field

from src.enums import BudgetCategory


class BudgetItemCreateRequest(BaseModel):
    label: str
    amount: float
    category: BudgetCategory | None = None
    date: date | None = None
    isPlanned: bool | None = None


class BudgetItemUpdateRequest(BaseModel):
    label: str | None = None
    amount: float | None = None
    category: BudgetCategory | None = None
    date: date | None = None
    isPlanned: bool | None = None


class BudgetItemResponse(BaseModel):
    id: UUID
    tripId: UUID = Field(alias="trip_id")
    label: str
    amount: float
    category: str
    date: date | None = None
    isPlanned: bool = Field(alias="is_planned")
    sourceType: str | None = Field(None, alias="source_type")
    sourceId: UUID | None = Field(None, alias="source_id")
    createdAt: str = Field(alias="created_at")
    updatedAt: str = Field(alias="updated_at")

    class Config:
        from_attributes = True
        populate_by_name = True


class BudgetItemListResponse(BaseModel):
    items: list[BudgetItemResponse]


class BudgetSummaryResponse(BaseModel):
    totalBudget: float = Field(alias="total_budget")
    totalSpent: float = Field(alias="total_spent")
    remaining: float
    byCategory: dict[str, float] = Field(alias="by_category")
    percentConsumed: float | None = Field(None, alias="percent_consumed")
    alertLevel: str | None = Field(None, alias="alert_level")
    alertMessage: str | None = Field(None, alias="alert_message")

    class Config:
        from_attributes = True
        populate_by_name = True

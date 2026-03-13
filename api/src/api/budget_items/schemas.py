from datetime import date
from uuid import UUID

from pydantic import BaseModel, Field


class BudgetItemCreateRequest(BaseModel):
    label: str
    amount: float
    category: str | None = None
    date: date | None = None
    isPlanned: bool | None = None


class BudgetItemUpdateRequest(BaseModel):
    label: str | None = None
    amount: float | None = None
    category: str | None = None
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

    class Config:
        from_attributes = True
        populate_by_name = True

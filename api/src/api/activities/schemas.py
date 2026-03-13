from datetime import date, time
from uuid import UUID

from pydantic import BaseModel, Field


class ActivityCreateRequest(BaseModel):
    title: str
    date: date
    description: str | None = None
    startTime: time | None = None
    endTime: time | None = None
    location: str | None = None
    category: str | None = None
    estimatedCost: float | None = None
    isBooked: bool | None = None


class ActivityUpdateRequest(BaseModel):
    title: str | None = None
    date: date | None = None
    description: str | None = None
    startTime: time | None = None
    endTime: time | None = None
    location: str | None = None
    category: str | None = None
    estimatedCost: float | None = None
    isBooked: bool | None = None


class ActivityResponse(BaseModel):
    id: UUID
    tripId: UUID = Field(alias="trip_id")
    title: str
    description: str | None = None
    date: date
    startTime: time | None = Field(default=None, alias="start_time")
    endTime: time | None = Field(default=None, alias="end_time")
    location: str | None = None
    category: str
    estimatedCost: float | None = Field(default=None, alias="estimated_cost")
    isBooked: bool = Field(alias="is_booked")
    createdAt: str = Field(alias="created_at")
    updatedAt: str = Field(alias="updated_at")

    class Config:
        from_attributes = True
        populate_by_name = True


class ActivityListResponse(BaseModel):
    items: list[ActivityResponse]

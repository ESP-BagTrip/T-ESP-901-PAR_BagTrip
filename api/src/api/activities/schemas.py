import datetime as dt
from uuid import UUID

from pydantic import BaseModel, Field

from src.enums import ActivityCategory



class ActivityCreateRequest(BaseModel):
    title: str
    date: dt.date
    description: str | None = None
    startTime: dt.time | None = None
    endTime: dt.time | None = None
    location: str | None = None
    category: ActivityCategory | None = None
    estimatedCost: float | None = None
    isBooked: bool | None = None
    validationStatus: str | None = None


class ActivityUpdateRequest(BaseModel):
    title: str | None = None
    date: dt.date | None = None
    description: str | None = None
    startTime: dt.time | None = None
    endTime: dt.time | None = None
    location: str | None = None
    category: ActivityCategory | None = None
    estimatedCost: float | None = None
    isBooked: bool | None = None
    validationStatus: str | None = None


class ActivityResponse(BaseModel):
    id: UUID
    tripId: UUID = Field(alias="trip_id")
    title: str
    description: str | None = None
    date: dt.date
    startTime: dt.time | None = Field(default=None, alias="start_time")
    endTime: dt.time | None = Field(default=None, alias="end_time")
    location: str | None = None
    category: str
    estimatedCost: float | None = Field(default=None, alias="estimated_cost")
    isBooked: bool = Field(alias="is_booked")
    validationStatus: str = Field(default="MANUAL", alias="validation_status")
    createdAt: dt.datetime = Field(alias="created_at")
    updatedAt: dt.datetime = Field(alias="updated_at")

    class Config:
        from_attributes = True
        populate_by_name = True


class ActivityListResponse(BaseModel):
    items: list[ActivityResponse]


class ActivityPaginatedResponse(BaseModel):
    items: list[ActivityResponse]
    total: int
    page: int
    limit: int
    totalPages: int = Field(alias="total_pages")

    class Config:
        populate_by_name = True

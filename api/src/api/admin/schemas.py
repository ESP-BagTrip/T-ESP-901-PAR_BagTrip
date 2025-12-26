"""Schémas Pydantic pour les endpoints admin."""

from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, Field


class AdminListResponse[T](BaseModel):
    """Réponse paginée générique pour les endpoints admin."""

    items: list[T]
    total: int
    page: int
    limit: int
    totalPages: int = Field(alias="total_pages")


class AdminUserResponse(BaseModel):
    """Réponse user pour admin."""

    id: UUID
    email: str
    createdAt: datetime = Field(alias="created_at")
    updatedAt: datetime | None = Field(None, alias="updated_at")

    class Config:
        from_attributes = True
        populate_by_name = True


class AdminTripResponse(BaseModel):
    """Réponse trip pour admin avec informations utilisateur."""

    id: UUID
    userId: UUID = Field(alias="user_id")
    userEmail: str = Field(alias="user_email")
    title: str | None = None
    originIata: str | None = Field(default=None, alias="origin_iata")
    destinationIata: str | None = Field(default=None, alias="destination_iata")
    startDate: date | None = Field(default=None, alias="start_date")
    endDate: date | None = Field(default=None, alias="end_date")
    status: str | None = None
    createdAt: datetime = Field(alias="created_at")
    updatedAt: datetime = Field(alias="updated_at")

    class Config:
        from_attributes = True
        populate_by_name = True


class AdminTravelerResponse(BaseModel):
    """Réponse traveler pour admin avec informations trip et utilisateur."""

    id: UUID
    tripId: UUID = Field(alias="trip_id")
    tripTitle: str | None = Field(default=None, alias="trip_title")
    userEmail: str = Field(alias="user_email")
    amadeusTravelerRef: str | None = Field(None, alias="amadeus_traveler_ref")
    travelerType: str = Field(..., alias="traveler_type")
    firstName: str = Field(..., alias="first_name")
    lastName: str = Field(..., alias="last_name")
    dateOfBirth: date | None = Field(None, alias="date_of_birth")
    gender: str | None = None
    createdAt: datetime = Field(..., alias="created_at")
    updatedAt: datetime = Field(..., alias="updated_at")

    class Config:
        from_attributes = True
        populate_by_name = True


class AdminHotelBookingResponse(BaseModel):
    """Réponse hotel booking pour admin avec informations trip et utilisateur."""

    id: UUID
    tripId: UUID = Field(alias="trip_id")
    tripTitle: str | None = Field(default=None, alias="trip_title")
    userEmail: str = Field(alias="user_email")
    hotelOfferId: UUID = Field(alias="hotel_offer_id")
    hotelId: str | None = Field(default=None, alias="hotel_id")
    bookingIntentId: UUID | None = Field(default=None, alias="booking_intent_id")
    amadeusBookingId: str | None = Field(default=None, alias="amadeus_booking_id")
    status: str | None = None
    createdAt: datetime = Field(alias="created_at")
    updatedAt: datetime = Field(alias="updated_at")

    class Config:
        from_attributes = True
        populate_by_name = True


class AdminFlightBookingResponse(BaseModel):
    """Réponse flight booking pour admin avec informations trip et utilisateur."""

    id: UUID
    tripId: UUID = Field(alias="trip_id")
    tripTitle: str | None = Field(default=None, alias="trip_title")
    userEmail: str = Field(alias="user_email")
    flightOfferId: UUID = Field(alias="flight_offer_id")
    bookingIntentId: UUID | None = Field(default=None, alias="booking_intent_id")
    amadeusFlightOrderId: str | None = Field(default=None, alias="amadeus_flight_order_id")
    status: str | None = None
    bookingReference: str | None = Field(default=None, alias="booking_reference")
    createdAt: datetime = Field(alias="created_at")
    updatedAt: datetime = Field(alias="updated_at")

    class Config:
        from_attributes = True
        populate_by_name = True

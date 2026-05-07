"""Schémas Pydantic pour les endpoints admin."""

import datetime as dt
from typing import Any
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_validator


class AuditLogResponse(BaseModel):
    """Single audit log entry."""

    id: UUID
    actorId: UUID = Field(alias="actor_id")
    actorEmail: str = Field(alias="actor_email")
    action: str
    entityType: str = Field(alias="entity_type")
    entityId: UUID = Field(alias="entity_id")
    diffJson: Any | None = Field(default=None, alias="diff_json")
    metadata_: Any | None = Field(default=None, alias="metadata")
    createdAt: dt.datetime = Field(alias="created_at")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


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
    plan: str = Field("FREE")
    createdAt: dt.datetime = Field(alias="created_at")
    updatedAt: dt.datetime | None = Field(None, alias="updated_at")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class UpdatePlanRequest(BaseModel):
    """Requête de mise à jour du plan utilisateur."""

    plan: str = Field(..., pattern="^(FREE|PREMIUM|ADMIN)$")


class DashboardMetricsResponse(BaseModel):
    """Dashboard KPI metrics."""

    totalUsers: int
    activeUsers: int
    inactiveUsers: int
    totalTrips: int
    totalRevenue: float
    totalFeedbacks: int
    pendingFeedbacks: int
    averageRating: float


class ChartDataResponse(BaseModel):
    """Single chart data point."""

    name: str
    value: float
    date: str | None = None


class AdminSendNotificationRequest(BaseModel):
    """Request to send notification from admin."""

    user_ids: list[UUID]
    title: str = Field(..., min_length=1, max_length=200)
    body: str = Field(..., min_length=1, max_length=1000)
    type: str = Field(default="ADMIN")
    trip_id: UUID | None = None

    @field_validator("user_ids")
    @classmethod
    def validate_user_ids(cls, v: list[UUID]) -> list[UUID]:
        if not v:
            msg = "At least one user_id is required"
            raise ValueError(msg)
        return v


class AdminUserDetailResponse(BaseModel):
    """Detailed user response for admin detail page."""

    id: UUID
    email: str
    fullName: str | None = Field(None, alias="full_name")
    phone: str | None = None
    plan: str = Field("FREE")
    planExpiresAt: dt.datetime | None = Field(None, alias="plan_expires_at")
    aiGenerationsCount: int = Field(0, alias="ai_generations_count")
    aiGenerationsResetAt: dt.datetime | None = Field(None, alias="ai_generations_reset_at")
    bannedAt: dt.datetime | None = Field(None, alias="banned_at")
    banReason: str | None = Field(None, alias="ban_reason")
    deletedAt: dt.datetime | None = Field(None, alias="deleted_at")
    tripsCount: int = Field(0, alias="trips_count")
    bookingsCount: int = Field(0, alias="bookings_count")
    createdAt: dt.datetime = Field(alias="created_at")
    updatedAt: dt.datetime | None = Field(None, alias="updated_at")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class AdminUserUpdateRequest(BaseModel):
    """Request to update user from admin."""

    email: str | None = None
    full_name: str | None = None
    phone: str | None = None
    plan: str | None = Field(None, pattern="^(FREE|PREMIUM|ADMIN)$")
    plan_expires_at: dt.datetime | None = None


class AdminBanRequest(BaseModel):
    """Request to ban a user."""

    reason: str = Field("", max_length=500)


class AdminBulkPlanRequest(BaseModel):
    """Bulk plan change request."""

    user_ids: list[UUID]
    plan: str = Field(..., pattern="^(FREE|PREMIUM|ADMIN)$")


class AdminBulkBanRequest(BaseModel):
    """Bulk ban request."""

    user_ids: list[UUID]
    reason: str = Field("", max_length=500)


class AdminTripResponse(BaseModel):
    """Réponse trip pour admin avec informations utilisateur."""

    id: UUID
    userId: UUID = Field(alias="user_id")
    userEmail: str = Field(alias="user_email")
    title: str | None = None
    originIata: str | None = Field(default=None, alias="origin_iata")
    destinationIata: str | None = Field(default=None, alias="destination_iata")
    destinationName: str | None = Field(default=None, alias="destination_name")
    startDate: dt.date | None = Field(default=None, alias="start_date")
    endDate: dt.date | None = Field(default=None, alias="end_date")
    status: str | None = None
    budgetTarget: float | None = Field(default=None, alias="budget_target")
    budgetEstimated: float | None = Field(default=None, alias="budget_estimated")
    budgetActual: float | None = Field(default=None, alias="budget_actual")
    nbTravelers: int | None = Field(default=None, alias="nb_travelers")
    origin: str | None = None
    createdAt: dt.datetime = Field(alias="created_at")
    updatedAt: dt.datetime = Field(alias="updated_at")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


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
    dateOfBirth: dt.date | None = Field(None, alias="date_of_birth")
    gender: str | None = None
    createdAt: dt.datetime = Field(..., alias="created_at")
    updatedAt: dt.datetime = Field(..., alias="updated_at")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class AdminTravelerProfileResponse(BaseModel):
    """Réponse traveler profile pour admin avec informations utilisateur."""

    id: UUID
    userId: UUID = Field(alias="user_id")
    userEmail: str = Field(alias="user_email")
    travelTypes: Any | None = Field(default=None, alias="travel_types")
    travelStyle: str | None = Field(default=None, alias="travel_style")
    budget: str | None = None
    companions: str | None = None
    isCompleted: bool = Field(alias="is_completed")
    createdAt: dt.datetime = Field(alias="created_at")
    updatedAt: dt.datetime = Field(alias="updated_at")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class AdminBookingIntentResponse(BaseModel):
    """Réponse booking intent pour admin avec informations trip et utilisateur."""

    id: UUID
    userId: UUID = Field(alias="user_id")
    userEmail: str = Field(alias="user_email")
    tripId: UUID = Field(alias="trip_id")
    tripTitle: str | None = Field(default=None, alias="trip_title")
    type: str
    status: str
    amount: float
    currency: str
    stripePaymentIntentId: str | None = Field(default=None, alias="stripe_payment_intent_id")
    createdAt: dt.datetime = Field(alias="created_at")
    updatedAt: dt.datetime = Field(alias="updated_at")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class AdminAccommodationResponse(BaseModel):
    """Réponse accommodation pour admin avec informations trip et utilisateur."""

    id: UUID
    tripId: UUID = Field(alias="trip_id")
    tripTitle: str | None = Field(default=None, alias="trip_title")
    userEmail: str = Field(alias="user_email")
    name: str
    address: str | None = None
    checkIn: dt.date | None = Field(default=None, alias="check_in")
    checkOut: dt.date | None = Field(default=None, alias="check_out")
    pricePerNight: float | None = Field(default=None, alias="price_per_night")
    currency: str | None = None
    bookingReference: str | None = Field(default=None, alias="booking_reference")
    createdAt: dt.datetime = Field(alias="created_at")
    updatedAt: dt.datetime = Field(alias="updated_at")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class AdminBaggageItemResponse(BaseModel):
    """Réponse baggage item pour admin avec informations trip et utilisateur."""

    id: UUID
    tripId: UUID = Field(alias="trip_id")
    tripTitle: str | None = Field(default=None, alias="trip_title")
    userEmail: str = Field(alias="user_email")
    name: str
    category: str | None = None
    quantity: int | None = None
    isPacked: bool | None = Field(default=None, alias="is_packed")
    createdAt: dt.datetime = Field(alias="created_at")
    updatedAt: dt.datetime = Field(alias="updated_at")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class AdminTripShareResponse(BaseModel):
    """Réponse trip share pour admin."""

    id: UUID
    tripId: UUID = Field(alias="trip_id")
    tripTitle: str | None = Field(default=None, alias="trip_title")
    userId: UUID = Field(alias="user_id")
    userEmail: str = Field(alias="user_email")
    role: str
    invitedAt: dt.datetime = Field(alias="invited_at")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class AdminFlightSearchResponse(BaseModel):
    """Réponse flight search pour admin avec informations trip."""

    id: UUID
    tripId: UUID = Field(alias="trip_id")
    tripTitle: str | None = Field(default=None, alias="trip_title")
    originIata: str = Field(alias="origin_iata")
    destinationIata: str = Field(alias="destination_iata")
    departureDate: dt.date = Field(alias="departure_date")
    returnDate: dt.date | None = Field(default=None, alias="return_date")
    adults: int
    children: int | None = None
    travelClass: str | None = Field(default=None, alias="travel_class")
    createdAt: dt.datetime = Field(alias="created_at")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class AdminActivityResponse(BaseModel):
    """Réponse activity pour admin avec informations trip et utilisateur."""

    id: UUID
    tripId: UUID = Field(alias="trip_id")
    tripTitle: str | None = Field(default=None, alias="trip_title")
    userEmail: str = Field(alias="user_email")
    title: str
    description: str | None = None
    # SMP-324 — see ActivityResponse: undated FOOD / TRANSPORT recos.
    date: dt.date | None = None
    startTime: Any | None = Field(default=None, alias="start_time")
    endTime: Any | None = Field(default=None, alias="end_time")
    location: str | None = None
    category: str
    estimatedCost: float | None = Field(default=None, alias="estimated_cost")
    isBooked: bool = Field(alias="is_booked")
    createdAt: dt.datetime = Field(alias="created_at")
    updatedAt: dt.datetime = Field(alias="updated_at")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class AdminBudgetItemResponse(BaseModel):
    """Réponse budget item pour admin avec informations trip et utilisateur."""

    id: UUID
    tripId: UUID = Field(alias="trip_id")
    tripTitle: str | None = Field(default=None, alias="trip_title")
    userEmail: str = Field(alias="user_email")
    label: str
    amount: float
    category: str
    date: dt.date | None = None
    isPlanned: bool = Field(alias="is_planned")
    createdAt: dt.datetime = Field(alias="created_at")
    updatedAt: dt.datetime = Field(alias="updated_at")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class AdminFeedbackResponse(BaseModel):
    """Réponse feedback pour admin."""

    id: UUID
    tripId: UUID = Field(alias="trip_id")
    tripTitle: str | None = Field(default=None, alias="trip_title")
    userId: UUID = Field(alias="user_id")
    userEmail: str = Field(alias="user_email")
    overallRating: int = Field(alias="overall_rating")
    highlights: str | None = None
    lowlights: str | None = None
    wouldRecommend: bool = Field(alias="would_recommend")
    createdAt: dt.datetime = Field(alias="created_at")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class AdminNotificationResponse(BaseModel):
    """Réponse notification pour admin."""

    id: UUID
    userId: UUID = Field(alias="user_id")
    userEmail: str = Field(alias="user_email")
    tripId: UUID | None = Field(default=None, alias="trip_id")
    tripTitle: str | None = Field(default=None, alias="trip_title")
    type: str
    title: str
    body: str
    isRead: bool = Field(alias="is_read")
    sentAt: dt.datetime | None = Field(default=None, alias="sent_at")
    createdAt: dt.datetime = Field(alias="created_at")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


# ──────────────────────── Trip Management Schemas ────────────────────────


class AdminTripDetailResponse(BaseModel):
    """Detailed trip response for admin detail page."""

    id: UUID
    userId: UUID = Field(alias="user_id")
    userEmail: str = Field(alias="user_email")
    title: str | None = None
    originIata: str | None = Field(default=None, alias="origin_iata")
    destinationIata: str | None = Field(default=None, alias="destination_iata")
    destinationName: str | None = Field(default=None, alias="destination_name")
    startDate: dt.date | None = Field(default=None, alias="start_date")
    endDate: dt.date | None = Field(default=None, alias="end_date")
    status: str | None = None
    budgetTarget: float | None = Field(default=None, alias="budget_target")
    budgetEstimated: float | None = Field(default=None, alias="budget_estimated")
    budgetActual: float | None = Field(default=None, alias="budget_actual")
    nbTravelers: int | None = Field(default=None, alias="nb_travelers")
    origin: str | None = None
    archivedAt: dt.datetime | None = Field(default=None, alias="archived_at")
    activitiesCount: int = Field(0, alias="activities_count")
    accommodationsCount: int = Field(0, alias="accommodations_count")
    sharesCount: int = Field(0, alias="shares_count")
    createdAt: dt.datetime = Field(alias="created_at")
    updatedAt: dt.datetime = Field(alias="updated_at")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class AdminTripUpdateRequest(BaseModel):
    """Request to update a trip from admin (topic 02 — only target writable)."""

    title: str | None = None
    status: str | None = Field(None, pattern="^(DRAFT|PLANNED|ONGOING|COMPLETED)$")
    start_date: dt.date | None = None
    end_date: dt.date | None = None
    destination_name: str | None = None
    budget_target: float | None = None
    nb_travelers: int | None = None


class AdminTripTransferRequest(BaseModel):
    """Request to transfer a trip to another user."""

    new_user_id: UUID


class AdminActivityCreateRequest(BaseModel):
    """Create activity via admin."""

    title: str
    date: dt.date
    description: str | None = None
    start_time: str | None = None
    end_time: str | None = None
    location: str | None = None
    category: str = "OTHER"
    estimated_cost: float | None = None


class AdminActivityUpdateRequest(BaseModel):
    """Update activity via admin."""

    title: str | None = None
    description: str | None = None
    date: dt.date | None = None
    start_time: str | None = None
    end_time: str | None = None
    location: str | None = None
    category: str | None = None
    estimated_cost: float | None = None
    is_booked: bool | None = None
    is_done: bool | None = None


class AdminAccommodationCreateRequest(BaseModel):
    """Create accommodation via admin."""

    name: str
    address: str | None = None
    check_in: dt.date | None = None
    check_out: dt.date | None = None
    price_per_night: float | None = None
    currency: str | None = None
    booking_reference: str | None = None
    notes: str | None = None


class AdminAccommodationUpdateRequest(BaseModel):
    """Update accommodation via admin."""

    name: str | None = None
    address: str | None = None
    check_in: dt.date | None = None
    check_out: dt.date | None = None
    price_per_night: float | None = None
    currency: str | None = None
    booking_reference: str | None = None
    notes: str | None = None


class AdminBudgetItemCreateRequest(BaseModel):
    """Create budget item via admin."""

    label: str
    amount: float
    category: str = "OTHER"
    date: dt.date | None = None
    is_planned: bool = True


class AdminBudgetItemUpdateRequest(BaseModel):
    """Update budget item via admin."""

    label: str | None = None
    amount: float | None = None
    category: str | None = None
    date: dt.date | None = None
    is_planned: bool | None = None


class AdminBaggageItemCreateRequest(BaseModel):
    """Create baggage item via admin."""

    name: str
    quantity: int | None = None
    is_packed: bool | None = None
    category: str | None = None
    notes: str | None = None


class AdminBaggageItemUpdateRequest(BaseModel):
    """Update baggage item via admin."""

    name: str | None = None
    quantity: int | None = None
    is_packed: bool | None = None
    category: str | None = None
    notes: str | None = None


class AdminShareCreateRequest(BaseModel):
    """Invite a user to a trip via admin."""

    email: str
    role: str = Field("VIEWER", pattern="^(VIEWER|EDITOR)$")


class AdminShareUpdateRequest(BaseModel):
    """Update share role via admin."""

    role: str = Field(..., pattern="^(VIEWER|EDITOR)$")


# ──────────────────────── Booking Management Schemas ────────────────────────


class AdminBookingIntentDetailResponse(BaseModel):
    """Detailed booking intent for admin detail page."""

    id: UUID
    userId: UUID = Field(alias="user_id")
    userEmail: str = Field(alias="user_email")
    tripId: UUID = Field(alias="trip_id")
    tripTitle: str | None = Field(default=None, alias="trip_title")
    type: str
    status: str
    amount: float
    currency: str
    stripePaymentIntentId: str | None = Field(default=None, alias="stripe_payment_intent_id")
    stripeChargeId: str | None = Field(default=None, alias="stripe_charge_id")
    amadeusOrderId: str | None = Field(default=None, alias="amadeus_order_id")
    lastError: Any | None = Field(default=None, alias="last_error")
    createdAt: dt.datetime = Field(alias="created_at")
    updatedAt: dt.datetime = Field(alias="updated_at")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class AdminBookingStatusRequest(BaseModel):
    """Force a booking intent status change."""

    status: str = Field(
        ...,
        pattern="^(INIT|AUTHORIZED|BOOKING_PENDING|BOOKED|CAPTURED|FAILED|CANCELLED|PAYMENT_CAPTURE_FAILED|REFUNDED)$",
    )


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
    createdAt: dt.datetime = Field(alias="created_at")
    updatedAt: dt.datetime = Field(alias="updated_at")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

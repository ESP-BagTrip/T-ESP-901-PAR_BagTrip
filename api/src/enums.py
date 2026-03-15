"""Enums centralisés pour l'application BagTrip."""

from enum import StrEnum


class TripStatus(StrEnum):
    DRAFT = "DRAFT"
    PLANNED = "PLANNED"
    ONGOING = "ONGOING"
    COMPLETED = "COMPLETED"


class TripOrigin(StrEnum):
    AI = "AI"
    MANUAL = "MANUAL"


class ActivityCategory(StrEnum):
    VISIT = "VISIT"
    RESTAURANT = "RESTAURANT"
    TRANSPORT = "TRANSPORT"
    LEISURE = "LEISURE"
    OTHER = "OTHER"


class BudgetCategory(StrEnum):
    FLIGHT = "FLIGHT"
    ACCOMMODATION = "ACCOMMODATION"
    FOOD = "FOOD"
    ACTIVITY = "ACTIVITY"
    TRANSPORT = "TRANSPORT"
    OTHER = "OTHER"


class BaggageCategory(StrEnum):
    CLOTHES = "CLOTHES"
    ELECTRONICS = "ELECTRONICS"
    DOCUMENTS = "DOCUMENTS"
    HYGIENE = "HYGIENE"
    OTHER = "OTHER"


class ShareRole(StrEnum):
    VIEWER = "VIEWER"


class FlightOrderStatus(StrEnum):
    CONFIRMED = "CONFIRMED"
    CANCELLED = "CANCELLED"


class BookingIntentStatus(StrEnum):
    INIT = "INIT"
    AUTHORIZED = "AUTHORIZED"
    BOOKING_PENDING = "BOOKING_PENDING"
    BOOKED = "BOOKED"
    CAPTURED = "CAPTURED"
    FAILED = "FAILED"
    CANCELLED = "CANCELLED"
    PAYMENT_CAPTURE_FAILED = "PAYMENT_CAPTURE_FAILED"


class BookingIntentType(StrEnum):
    FLIGHT = "flight"


class NotificationType(StrEnum):
    DEPARTURE_REMINDER = "DEPARTURE_REMINDER"
    FLIGHT_H4 = "FLIGHT_H4"
    FLIGHT_H1 = "FLIGHT_H1"
    MORNING_SUMMARY = "MORNING_SUMMARY"
    ACTIVITY_H1 = "ACTIVITY_H1"
    TRIP_ENDED = "TRIP_ENDED"
    BUDGET_ALERT = "BUDGET_ALERT"
    TRIP_SHARED = "TRIP_SHARED"
    ADMIN = "ADMIN"


class FlightType(StrEnum):
    MAIN = "MAIN"
    INTERNAL = "INTERNAL"

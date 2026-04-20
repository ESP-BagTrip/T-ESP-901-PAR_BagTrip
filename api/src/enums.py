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
    CULTURE = "CULTURE"
    NATURE = "NATURE"
    FOOD = "FOOD"
    SPORT = "SPORT"
    SHOPPING = "SHOPPING"
    NIGHTLIFE = "NIGHTLIFE"
    RELAXATION = "RELAXATION"
    OTHER = "OTHER"


class BudgetCategory(StrEnum):
    FLIGHT = "FLIGHT"
    ACCOMMODATION = "ACCOMMODATION"
    FOOD = "FOOD"
    ACTIVITY = "ACTIVITY"
    TRANSPORT = "TRANSPORT"
    OTHER = "OTHER"


class BaggageCategory(StrEnum):
    DOCUMENTS = "DOCUMENTS"
    CLOTHING = "CLOTHING"
    ELECTRONICS = "ELECTRONICS"
    TOILETRIES = "TOILETRIES"
    HEALTH = "HEALTH"
    ACCESSORIES = "ACCESSORIES"
    OTHER = "OTHER"


class ShareRole(StrEnum):
    VIEWER = "VIEWER"
    EDITOR = "EDITOR"


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
    REFUNDED = "REFUNDED"


class BookingIntentType(StrEnum):
    FLIGHT = "flight"


class NotificationType(StrEnum):
    DEPARTURE_REMINDER = "DEPARTURE_REMINDER"
    FLIGHT_H4 = "FLIGHT_H4"
    FLIGHT_H1 = "FLIGHT_H1"
    MORNING_SUMMARY = "MORNING_SUMMARY"
    ACTIVITY_H1 = "ACTIVITY_H1"
    TRIP_STARTED = "TRIP_STARTED"
    TRIP_ENDED = "TRIP_ENDED"
    BUDGET_ALERT = "BUDGET_ALERT"
    TRIP_SHARED = "TRIP_SHARED"
    ADMIN = "ADMIN"


class ValidationStatus(StrEnum):
    SUGGESTED = "SUGGESTED"
    VALIDATED = "VALIDATED"
    MANUAL = "MANUAL"


class DateMode(StrEnum):
    EXACT = "EXACT"
    MONTH = "MONTH"
    FLEXIBLE = "FLEXIBLE"


class BudgetPreset(StrEnum):
    BACKPACKER = "BACKPACKER"
    COMFORTABLE = "COMFORTABLE"
    PREMIUM = "PREMIUM"
    NO_LIMIT = "NO_LIMIT"


class FlightType(StrEnum):
    MAIN = "MAIN"
    RETURN = "RETURN"
    INTERNAL = "INTERNAL"
    AI_SUGGESTED = "AI_SUGGESTED"


class TrackingStatus(StrEnum):
    """Whether BagTrip is responsible for tracking a given domain of the trip."""

    TRACKED = "TRACKED"
    SKIPPED = "SKIPPED"

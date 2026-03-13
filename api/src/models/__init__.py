"""Modèles de données."""

from .accommodation import Accommodation
from .activity import Activity
from .amadeus_api_log import AmadeusApiLog
from .baggage_item import BaggageItem
from .booking import Booking  # Deprecated - replaced by booking_intents pattern
from .booking_intent import BookingIntent
from .budget_item import BudgetItem
from .flight_offer import FlightOffer
from .flight_order import FlightOrder
from .flight_search import FlightSearch
from .refresh_token import RefreshToken
from .stripe_event import StripeEvent
from .traveler import TripTraveler
from .traveler_profile import TravelerProfile
from .trip import Trip
from .trip_share import TripShare
from .user import User

__all__ = [
    "User",
    "Trip",
    "TripTraveler",
    "Activity",
    "Accommodation",
    "BaggageItem",
    "BudgetItem",
    "FlightSearch",
    "FlightOffer",
    "FlightOrder",
    "BookingIntent",
    "RefreshToken",
    "StripeEvent",
    "AmadeusApiLog",
    "TravelerProfile",
    "TripShare",
    "Booking",  # Deprecated
]

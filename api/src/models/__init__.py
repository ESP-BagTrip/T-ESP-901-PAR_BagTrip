"""Modèles de données."""

from .amadeus_api_log import AmadeusApiLog
from .booking import Booking  # Deprecated - replaced by booking_intents pattern
from .booking_intent import BookingIntent
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

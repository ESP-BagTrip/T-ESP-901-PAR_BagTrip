"""Modèles de données."""

from .amadeus_api_log import AmadeusApiLog
from .booking import Booking  # Deprecated - replaced by booking_intents pattern
from .booking_intent import BookingIntent
from .context import Context
from .conversation import Conversation
from .flight_offer import FlightOffer
from .flight_order import FlightOrder
from .flight_search import FlightSearch
from .hotel_booking import HotelBooking
from .hotel_offer import HotelOffer
from .hotel_search import HotelSearch
from .message import Message
from .stripe_event import StripeEvent
from .traveler import TripTraveler
from .trip import Trip
from .user import User

__all__ = [
    "User",
    "Trip",
    "TripTraveler",
    "Conversation",
    "Message",
    "Context",
    "FlightSearch",
    "FlightOffer",
    "FlightOrder",
    "HotelSearch",
    "HotelOffer",
    "HotelBooking",
    "BookingIntent",
    "StripeEvent",
    "AmadeusApiLog",
    "Booking",  # Deprecated
]

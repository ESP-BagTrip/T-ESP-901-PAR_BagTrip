"""Thin service wrapper around `amadeus_client`.

Routes should never import `amadeus_client` directly — they go through this
service so that the layering rule stays honest:

    Route (HTTP only) → Service (métier) → Integration wrapper

The wrapper is intentionally dumb: each method forwards the same query object
to the corresponding client call. Any business logic on top of Amadeus
responses (caching, domain mapping, error wrapping with `AppError`) belongs
here, not in the routes.

Today the wrapping is one-to-one because the routes used to invoke the client
directly. As soon as a route grows a pre/post hook (caching, aggregation, fare
de-duping, …) it goes into the matching method here rather than in the route
body.
"""

from __future__ import annotations

from src.integrations.amadeus.client import amadeus_client
from src.integrations.amadeus.types import (
    FlightCheapestDateSearchQuery,
    FlightInspirationSearchQuery,
    FlightOffer,
    FlightOfferSearchQuery,
    FlightOrderTraveler,
    HotelListSearchQuery,
    HotelOffersSearchQuery,
)


class AmadeusService:
    """Service facade exposing the Amadeus operations used by the API."""

    # ---- Flights -----------------------------------------------------------

    @staticmethod
    async def search_flight_offers(query: FlightOfferSearchQuery):
        return await amadeus_client.search_flight_offers(query)

    @staticmethod
    async def search_flight_destinations(query: FlightInspirationSearchQuery):
        return await amadeus_client.search_flight_destinations(query)

    @staticmethod
    async def search_flight_cheapest_dates(query: FlightCheapestDateSearchQuery):
        return await amadeus_client.search_flight_cheapest_dates(query)

    @staticmethod
    async def confirm_flight_price(flight_offer: FlightOffer):
        return await amadeus_client.confirm_flight_price(flight_offer)

    @staticmethod
    async def create_flight_order(
        flight_offer: FlightOffer,
        travelers: list[FlightOrderTraveler],
    ):
        return await amadeus_client.create_flight_order(flight_offer, travelers)

    # ---- Hotels ------------------------------------------------------------

    @staticmethod
    async def search_hotel_list(query: HotelListSearchQuery):
        return await amadeus_client.search_hotel_list(query)

    @staticmethod
    async def search_hotel_offers(query: HotelOffersSearchQuery):
        return await amadeus_client.search_hotel_offers(query)

"""Client unifié Amadeus pour vols et hôtels.

Les recherches de locations (aéroports, villes, codes IATA) sont gérées
par le module aviation_data (données offline).
"""

from .flights import (
    confirm_flight_price,
    create_flight_order,
    search_flight_cheapest_dates,
    search_flight_destinations,
    search_flight_offers,
)
from .hotels import (
    search_hotel_list,
    search_hotel_offers,
)
from .types import (
    FlightCheapestDateSearchQuery,
    FlightInspirationSearchQuery,
    FlightOffer,
    FlightOfferSearchQuery,
    FlightOrderTraveler,
    HotelListSearchQuery,
    HotelOffersSearchQuery,
)


class AmadeusClient:
    """Client unifié pour les appels Amadeus (vols + hôtels)."""

    # Flight methods
    async def search_flight_offers(self, query: FlightOfferSearchQuery):
        """Recherche d'offres de vols."""
        return await search_flight_offers(query)

    async def search_flight_destinations(self, query: FlightInspirationSearchQuery):
        """Recherche de destinations inspirantes."""
        return await search_flight_destinations(query)

    async def search_flight_cheapest_dates(self, query: FlightCheapestDateSearchQuery):
        """Recherche des dates les moins chères."""
        return await search_flight_cheapest_dates(query)

    async def confirm_flight_price(self, flight_offer: FlightOffer):
        """Confirme le prix d'une offre de vol."""
        return await confirm_flight_price(flight_offer)

    async def create_flight_order(
        self, flight_offer: FlightOffer, travelers: list[FlightOrderTraveler]
    ):
        """Crée une commande de vol."""
        return await create_flight_order(flight_offer, travelers)

    # Hotel methods
    async def search_hotel_list(self, query: HotelListSearchQuery):
        """Recherche d'hôtels par ville."""
        return await search_hotel_list(query)

    async def search_hotel_offers(self, query: HotelOffersSearchQuery):
        """Recherche d'offres d'hôtels."""
        return await search_hotel_offers(query)


# Instance globale du client
amadeus_client = AmadeusClient()

"""Client unifié Amadeus exposant toutes les méthodes."""

from .flights import (
    confirm_flight_price,
    create_flight_order,
    search_flight_cheapest_dates,
    search_flight_destinations,
    search_flight_offers,
)
from .hotels import book_hotel, search_hotel_offers
from .locations import (
    search_location_by_id,
    search_location_nearest,
    search_locations_by_keyword,
)
from .types import (
    FlightCheapestDateSearchQuery,
    FlightInspirationSearchQuery,
    FlightOffer,
    FlightOfferSearchQuery,
    FlightOrderTraveler,
    LocationIdSearchQuery,
    LocationKeywordSearchQuery,
    LocationNearestSearchQuery,
)


class AmadeusClient:
    """Client unifié pour les appels Amadeus."""

    # Location methods
    async def search_locations_by_keyword(self, query: LocationKeywordSearchQuery):
        """Recherche de locations par mot-clé."""
        return await search_locations_by_keyword(query)

    async def search_location_by_id(self, query: LocationIdSearchQuery):
        """Recherche de location par ID."""
        return await search_location_by_id(query)

    async def search_location_nearest(self, query: LocationNearestSearchQuery):
        """Recherche de locations les plus proches."""
        return await search_location_nearest(query)

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
    async def search_hotel_offers(
        self,
        city_code: str | None = None,
        latitude: float | None = None,
        longitude: float | None = None,
        check_in: str | None = None,
        check_out: str | None = None,
        adults: int = 1,
        room_qty: int = 1,
        currency: str | None = None,
    ):
        """Recherche d'offres d'hôtels."""
        return await search_hotel_offers(
            city_code=city_code,
            latitude=latitude,
            longitude=longitude,
            check_in=check_in,
            check_out=check_out,
            adults=adults,
            room_qty=room_qty,
            currency=currency,
        )

    async def book_hotel(
        self,
        offer_id: str,
        hotel_id: str,
        guests: list[dict],
        payments: dict | None = None,
    ):
        """Réserve un hôtel."""
        return await book_hotel(
            offer_id=offer_id,
            hotel_id=hotel_id,
            guests=guests,
            payments=payments,
        )


# Instance globale du client
amadeus_client = AmadeusClient()

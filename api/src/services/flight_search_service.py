"""Service pour la gestion des recherches de vols."""

from datetime import date
from uuid import UUID

from sqlalchemy.orm import Session

from src.integrations.amadeus import amadeus_client
from src.integrations.amadeus.types import FlightOfferSearchQuery
from src.models.flight_offer import FlightOffer
from src.models.flight_search import FlightSearch
from src.services.trips_service import TripsService
from src.utils.errors import AppError


class FlightSearchService:
    """Service pour les recherches de vols avec persistance."""

    @staticmethod
    async def create_search(
        db: Session,
        trip_id: UUID,
        user_id: UUID,
        origin_iata: str,
        destination_iata: str,
        departure_date: date,
        return_date: date | None = None,
        adults: int = 1,
        children: int | None = None,
        infants: int | None = None,
        travel_class: str | None = None,
        non_stop: bool | None = None,
        currency: str | None = None,
    ) -> tuple[FlightSearch, list[FlightOffer]]:
        """
        Créer une recherche de vol et persister les résultats.
        Retourne la recherche et les offres créées.
        """
        # Vérifier que le trip existe et appartient à l'utilisateur
        trip = TripsService.get_trip_by_id(db, trip_id, user_id)
        if not trip:
            raise AppError("TRIP_NOT_FOUND", 404, "Trip not found")

        # Construire la requête Amadeus
        query = FlightOfferSearchQuery(
            originLocationCode=origin_iata,
            destinationLocationCode=destination_iata,
            departureDate=departure_date.isoformat(),
            returnDate=return_date.isoformat() if return_date else None,
            adults=adults,
            children=children,
            infants=infants,
            travelClass=travel_class,
            nonStop=non_stop,
            currencyCode=currency,
        )

        # Appeler Amadeus
        amadeus_response = await amadeus_client.search_flight_offers(query)

        # Créer la recherche en DB
        search = FlightSearch(
            trip_id=trip_id,
            origin_iata=origin_iata,
            destination_iata=destination_iata,
            departure_date=departure_date,
            return_date=return_date,
            adults=adults,
            children=children,
            infants=infants,
            travel_class=travel_class,
            non_stop=non_stop,
            currency=currency,
            amadeus_request=query.model_dump(),
            amadeus_response=amadeus_response.model_dump()
            if hasattr(amadeus_response, "model_dump")
            else amadeus_response,
        )
        db.add(search)
        db.flush()  # Pour obtenir l'ID

        # Persister les offres
        offers = []
        if hasattr(amadeus_response, "data") and amadeus_response.data:
            for offer_data in amadeus_response.data:
                # Extraire les informations de l'offre
                price_data = (
                    offer_data.get("price", {})
                    if isinstance(offer_data, dict)
                    else getattr(offer_data, "price", {})
                )
                grand_total = (
                    float(price_data.get("grandTotal", 0))
                    if isinstance(price_data, dict)
                    else float(getattr(price_data, "grandTotal", 0))
                )
                base_total = (
                    float(price_data.get("base", 0))
                    if isinstance(price_data, dict)
                    else float(getattr(price_data, "base", 0))
                )
                currency_code = (
                    price_data.get("currency", currency)
                    if isinstance(price_data, dict)
                    else getattr(price_data, "currency", currency)
                )

                offer = FlightOffer(
                    flight_search_id=search.id,
                    trip_id=trip_id,
                    amadeus_offer_id=offer_data.get("id")
                    if isinstance(offer_data, dict)
                    else getattr(offer_data, "id", None),
                    source=offer_data.get("source")
                    if isinstance(offer_data, dict)
                    else getattr(offer_data, "source", None),
                    validating_airline_codes=",".join(offer_data.get("validatingAirlineCodes", []))
                    if isinstance(offer_data, dict)
                    else ",".join(getattr(offer_data, "validatingAirlineCodes", [])),
                    last_ticketing_datetime=None,  # À extraire si disponible
                    currency=currency_code,
                    grand_total=grand_total,
                    base_total=base_total,
                    offer_json=offer_data
                    if isinstance(offer_data, dict)
                    else offer_data.model_dump()
                    if hasattr(offer_data, "model_dump")
                    else {},
                )
                db.add(offer)
                offers.append(offer)

        db.commit()
        db.refresh(search)
        for offer in offers:
            db.refresh(offer)

        return search, offers

    @staticmethod
    def get_search_by_id(
        db: Session, search_id: UUID, trip_id: UUID, user_id: UUID
    ) -> FlightSearch | None:
        """Récupérer une recherche par ID."""
        # Vérifier que le trip existe et appartient à l'utilisateur
        trip = TripsService.get_trip_by_id(db, trip_id, user_id)
        if not trip:
            raise AppError("TRIP_NOT_FOUND", 404, "Trip not found")

        return (
            db.query(FlightSearch)
            .filter(FlightSearch.id == search_id, FlightSearch.trip_id == trip_id)
            .first()
        )

    @staticmethod
    def get_offers_by_search(
        db: Session, search_id: UUID, trip_id: UUID, user_id: UUID
    ) -> list[FlightOffer]:
        """Récupérer les offres d'une recherche."""
        # Vérifier que la recherche existe
        search = FlightSearchService.get_search_by_id(db, search_id, trip_id, user_id)
        if not search:
            raise AppError("SEARCH_NOT_FOUND", 404, "Flight search not found")

        return db.query(FlightOffer).filter(FlightOffer.flight_search_id == search_id).all()

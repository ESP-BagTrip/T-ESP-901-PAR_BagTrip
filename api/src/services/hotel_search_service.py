"""Service pour la gestion des recherches d'hôtels."""

from datetime import date
from uuid import UUID

from sqlalchemy.orm import Session

from src.integrations.amadeus import amadeus_client
from src.models.hotel_offer import HotelOffer
from src.models.hotel_search import HotelSearch
from src.services.trips_service import TripsService
from src.utils.errors import AppError


class HotelSearchService:
    """Service pour les recherches d'hôtels avec persistance."""

    @staticmethod
    async def create_search(
        db: Session,
        trip_id: UUID,
        user_id: UUID,
        city_code: str | None = None,
        latitude: float | None = None,
        longitude: float | None = None,
        check_in: date | None = None,
        check_out: date | None = None,
        adults: int = 1,
        room_qty: int = 1,
        currency: str | None = None,
    ) -> tuple[HotelSearch, list[HotelOffer]]:
        """
        Créer une recherche d'hôtel et persister les résultats.
        Retourne la recherche et les offres créées.
        """
        # Vérifier que le trip existe et appartient à l'utilisateur
        trip = TripsService.get_trip_by_id(db, trip_id, user_id)
        if not trip:
            raise AppError("TRIP_NOT_FOUND", 404, "Trip not found")

        if not check_in or not check_out:
            raise AppError("INVALID_REQUEST", 400, "check_in and check_out are required")

        # Construire la requête Amadeus
        request_data = {
            "city_code": city_code,
            "latitude": float(latitude) if latitude else None,
            "longitude": float(longitude) if longitude else None,
            "check_in": check_in.isoformat(),
            "check_out": check_out.isoformat(),
            "adults": adults,
            "room_qty": room_qty,
            "currency": currency,
        }

        # Appeler Amadeus
        amadeus_response = await amadeus_client.search_hotel_offers(
            city_code=city_code,
            latitude=float(latitude) if latitude else None,
            longitude=float(longitude) if longitude else None,
            check_in=check_in.isoformat(),
            check_out=check_out.isoformat(),
            adults=adults,
            room_qty=room_qty,
            currency=currency,
        )

        # Créer la recherche en DB
        search = HotelSearch(
            trip_id=trip_id,
            city_code=city_code,
            latitude=float(latitude) if latitude else None,
            longitude=float(longitude) if longitude else None,
            check_in=check_in,
            check_out=check_out,
            adults=adults,
            room_qty=room_qty,
            currency=currency,
            amadeus_request=request_data,
            amadeus_response=amadeus_response,
        )
        db.add(search)
        db.flush()  # Pour obtenir l'ID

        # Persister les offres
        offers = []
        hotel_data = amadeus_response.get("data", []) if isinstance(amadeus_response, dict) else []
        for hotel_item in hotel_data:
            hotel_info = hotel_item.get("hotel", {})
            offers_data = hotel_item.get("offers", [])

            for offer_data in offers_data:
                price_data = offer_data.get("price", {})
                total_price = float(price_data.get("total", 0)) if price_data else 0
                currency_code = price_data.get("currency", currency) if price_data else currency

                offer = HotelOffer(
                    hotel_search_id=search.id,
                    trip_id=trip_id,
                    hotel_id=hotel_info.get("hotelId"),
                    offer_id=offer_data.get("id"),
                    chain_code=hotel_info.get("chainCode"),
                    room_type=offer_data.get("room", {}).get("type")
                    if isinstance(offer_data.get("room"), dict)
                    else None,
                    currency=currency_code,
                    total_price=total_price,
                    offer_json={
                        "hotel": hotel_info,
                        "offer": offer_data,
                    },
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
    ) -> HotelSearch | None:
        """Récupérer une recherche par ID."""
        # Vérifier que le trip existe et appartient à l'utilisateur
        trip = TripsService.get_trip_by_id(db, trip_id, user_id)
        if not trip:
            raise AppError("TRIP_NOT_FOUND", 404, "Trip not found")

        return (
            db.query(HotelSearch)
            .filter(HotelSearch.id == search_id, HotelSearch.trip_id == trip_id)
            .first()
        )

    @staticmethod
    def get_offers_by_search(
        db: Session, search_id: UUID, trip_id: UUID, user_id: UUID
    ) -> list[HotelOffer]:
        """Récupérer les offres d'une recherche."""
        # Vérifier que la recherche existe
        search = HotelSearchService.get_search_by_id(db, search_id, trip_id, user_id)
        if not search:
            raise AppError("SEARCH_NOT_FOUND", 404, "Hotel search not found")

        return db.query(HotelOffer).filter(HotelOffer.hotel_search_id == search_id).all()

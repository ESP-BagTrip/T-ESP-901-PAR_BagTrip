"""Service pour le pricing des offres de vols."""

from uuid import UUID

from sqlalchemy.orm import Session

from src.integrations.amadeus import amadeus_client
from src.integrations.amadeus.types import FlightOffer
from src.models.flight_offer import FlightOffer as FlightOfferModel
from src.services.trips_service import TripsService
from src.utils.errors import AppError


class FlightOfferPricingService:
    """Service pour le repricing des offres de vols."""

    @staticmethod
    async def price_offer(
        db: Session,
        offer_id: UUID,
        trip_id: UUID,
        user_id: UUID,
    ) -> FlightOfferModel:
        """
        Repricer une offre de vol et mettre à jour priced_offer_json.
        Recommandé avant le booking pour éviter les échecs.
        """
        # Vérifier que le trip existe et appartient à l'utilisateur
        trip = TripsService.get_trip_by_id(db, trip_id, user_id)
        if not trip:
            raise AppError("TRIP_NOT_FOUND", 404, "Trip not found")

        # Récupérer l'offre
        offer = (
            db.query(FlightOfferModel)
            .filter(
                FlightOfferModel.id == offer_id,
                FlightOfferModel.trip_id == trip_id,
            )
            .first()
        )

        if not offer:
            raise AppError("OFFER_NOT_FOUND", 404, "Flight offer not found")

        # Construire la requête de pricing
        # Utiliser l'offer_json pour reconstruire l'offre Amadeus
        flight_offer_data = offer.offer_json
        if isinstance(flight_offer_data, dict):
            # Convertir en objet FlightOffer si nécessaire
            flight_offer = FlightOffer(**flight_offer_data)
        else:
            flight_offer = flight_offer_data

        # Appeler Amadeus pour repricer
        priced_response = await amadeus_client.confirm_flight_price(flight_offer)

        # Mettre à jour l'offre avec le prix repricé
        if hasattr(priced_response, "data"):
            priced_data = priced_response.data
            if isinstance(priced_data, dict):
                price_data = priced_data.get("flightOffers", [{}])[0].get("price", {})
            else:
                price_data = getattr(priced_data, "price", {})

            if price_data:
                offer.grand_total = float(price_data.get("grandTotal", offer.grand_total or 0))
                offer.currency = price_data.get("currency", offer.currency)

            offer.priced_offer_json = (
                priced_response.model_dump()
                if hasattr(priced_response, "model_dump")
                else priced_response
            )

        db.commit()
        db.refresh(offer)

        return offer

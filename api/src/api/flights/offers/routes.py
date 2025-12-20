"""Routes pour les offres de vols."""

from uuid import UUID

from fastapi import APIRouter, Depends, Path
from sqlalchemy.orm import Session

from src.api.auth.middleware import get_current_user
from src.api.flights.offers.schemas import FlightOfferPriceResponse, FlightOfferResponse
from src.config.database import get_db
from src.models.flight_offer import FlightOffer
from src.models.user import User
from src.services.flight_offer_pricing_service import FlightOfferPricingService
from src.services.trips_service import TripsService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/trips", tags=["Flight Offers"])


@router.get(
    "/{tripId}/flights/offers/{offerDbId}",
    response_model=FlightOfferResponse,
    summary="Get flight offer",
    description="Get detailed information about a specific flight offer",
)
async def get_flight_offer(
    tripId: UUID = Path(..., description="Trip ID"),
    offerDbId: UUID = Path(..., description="Offer DB ID"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Récupérer une offre de vol selon PLAN.md."""
    try:
        # Vérifier que le trip existe et appartient à l'utilisateur
        trip = TripsService.get_trip_by_id(db, tripId, current_user.id)
        if not trip:
            raise AppError("TRIP_NOT_FOUND", 404, "Trip not found")

        offer = (
            db.query(FlightOffer)
            .filter(
                FlightOffer.id == offerDbId,
                FlightOffer.trip_id == tripId,
            )
            .first()
        )

        if not offer:
            raise AppError("OFFER_NOT_FOUND", 404, "Flight offer not found")

        return FlightOfferResponse(
            id=offer.id,
            offer=offer.offer_json if offer.offer_json else {},
        )
    except AppError as e:
        raise create_http_exception(e) from e


@router.post(
    "/{tripId}/flights/offers/{offerDbId}/price",
    response_model=FlightOfferPriceResponse,
    summary="Price flight offer",
    description="Confirm and update the price of a flight offer (recommended before booking)",
)
async def price_flight_offer(
    tripId: UUID = Path(..., description="Trip ID"),
    offerDbId: UUID = Path(..., description="Offer DB ID"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Repricer une offre de vol selon PLAN.md."""
    try:
        offer = await FlightOfferPricingService.price_offer(
            db=db,
            offer_id=offerDbId,
            trip_id=tripId,
            user_id=current_user.id,
        )

        return FlightOfferPriceResponse(
            offerId=offer.id,
            pricedOffer=offer.priced_offer_json if offer.priced_offer_json else {},
        )
    except AppError as e:
        raise create_http_exception(e) from e

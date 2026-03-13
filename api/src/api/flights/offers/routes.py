"""Routes pour les offres de vols."""

from uuid import UUID

from fastapi import APIRouter, Depends, Path
from sqlalchemy.orm import Session

from src.api.auth.trip_access import TripAccess, get_trip_access, get_trip_owner_access
from src.api.flights.offers.schemas import FlightOfferPriceResponse, FlightOfferResponse
from src.config.database import get_db
from src.models.flight_offer import FlightOffer
from src.services.flight_offer_pricing_service import FlightOfferPricingService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/trips", tags=["Flight Offers"])


@router.get(
    "/{tripId}/flights/offers/{offerDbId}",
    response_model=FlightOfferResponse,
    summary="Get flight offer",
    description="Get detailed information about a specific flight offer",
)
async def get_flight_offer(
    offerDbId: UUID = Path(..., description="Offer DB ID"),
    access: TripAccess = Depends(get_trip_access),
    db: Session = Depends(get_db),
):
    """Récupérer une offre de vol selon PLAN.md."""
    try:
        offer = (
            db.query(FlightOffer)
            .filter(
                FlightOffer.id == offerDbId,
                FlightOffer.trip_id == access.trip.id,
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
    offerDbId: UUID = Path(..., description="Offer DB ID"),
    access: TripAccess = Depends(get_trip_owner_access),
    db: Session = Depends(get_db),
):
    """Repricer une offre de vol selon PLAN.md."""
    try:
        offer = await FlightOfferPricingService.price_offer(
            db=db,
            offer_id=offerDbId,
            trip_id=access.trip.id,
        )

        return FlightOfferPriceResponse(
            offerId=offer.id,
            pricedOffer=offer.priced_offer_json if offer.priced_offer_json else {},
        )
    except AppError as e:
        raise create_http_exception(e) from e

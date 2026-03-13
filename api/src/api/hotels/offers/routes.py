"""Routes pour les offres d'hôtels."""

from uuid import UUID

from fastapi import APIRouter, Depends, Path
from sqlalchemy.orm import Session

from src.api.auth.trip_access import TripAccess, get_trip_access
from src.api.hotels.offers.schemas import HotelOfferResponse
from src.config.database import get_db
from src.models.hotel_offer import HotelOffer
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/trips", tags=["Hotel Offers"])


@router.get(
    "/{tripId}/hotels/offers/{offerDbId}",
    response_model=HotelOfferResponse,
    summary="Get hotel offer",
    description="Get detailed information about a specific hotel offer",
)
async def get_hotel_offer(
    offerDbId: UUID = Path(..., description="Offer DB ID"),
    access: TripAccess = Depends(get_trip_access),
    db: Session = Depends(get_db),
):
    """Récupérer une offre d'hôtel selon PLAN.md."""
    try:
        offer = (
            db.query(HotelOffer)
            .filter(
                HotelOffer.id == offerDbId,
                HotelOffer.trip_id == access.trip.id,
            )
            .first()
        )

        if not offer:
            raise AppError("OFFER_NOT_FOUND", 404, "Hotel offer not found")

        return HotelOfferResponse(
            id=offer.id,
            offer=offer.offer_json if offer.offer_json else {},
        )
    except AppError as e:
        raise create_http_exception(e) from e

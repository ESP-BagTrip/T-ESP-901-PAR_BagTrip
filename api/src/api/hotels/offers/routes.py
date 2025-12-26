"""Routes pour les offres d'hôtels."""

from uuid import UUID

from fastapi import APIRouter, Depends, Path
from sqlalchemy.orm import Session

from src.api.auth.middleware import get_current_user
from src.api.hotels.offers.schemas import HotelOfferResponse
from src.config.database import get_db
from src.models.hotel_offer import HotelOffer
from src.models.user import User
from src.services.trips_service import TripsService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/trips", tags=["Hotel Offers"])


@router.get(
    "/{tripId}/hotels/offers/{offerDbId}",
    response_model=HotelOfferResponse,
    summary="Get hotel offer",
    description="Get detailed information about a specific hotel offer",
)
async def get_hotel_offer(
    tripId: UUID = Path(..., description="Trip ID"),
    offerDbId: UUID = Path(..., description="Offer DB ID"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Récupérer une offre d'hôtel selon PLAN.md."""
    try:
        # Vérifier que le trip existe et appartient à l'utilisateur
        trip = TripsService.get_trip_by_id(db, tripId, current_user.id)
        if not trip:
            raise AppError("TRIP_NOT_FOUND", 404, "Trip not found")

        offer = (
            db.query(HotelOffer)
            .filter(
                HotelOffer.id == offerDbId,
                HotelOffer.trip_id == tripId,
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

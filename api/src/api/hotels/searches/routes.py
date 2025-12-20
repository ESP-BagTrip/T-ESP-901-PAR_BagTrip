"""Routes pour les recherches d'hôtels."""

from uuid import UUID

from fastapi import APIRouter, Depends, Path, status
from sqlalchemy.orm import Session

from src.api.auth.middleware import get_current_user
from src.api.hotels.searches.schemas import (
    HotelOfferDetail,
    HotelOfferSummary,
    HotelSearchCreateRequest,
    HotelSearchDetailResponse,
    HotelSearchResponse,
)
from src.config.database import get_db
from src.models.user import User
from src.services.hotel_search_service import HotelSearchService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/trips", tags=["Hotel Searches"])


@router.post(
    "/{tripId}/hotels/searches",
    response_model=HotelSearchResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create hotel search",
    description="Search for hotels and persist results",
)
async def create_hotel_search(
    request: HotelSearchCreateRequest,
    tripId: UUID = Path(..., description="Trip ID"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Créer une recherche d'hôtel selon PLAN.md."""
    try:
        search, offers = await HotelSearchService.create_search(
            db=db,
            trip_id=tripId,
            user_id=current_user.id,
            city_code=request.cityCode,
            latitude=request.latitude,
            longitude=request.longitude,
            check_in=request.checkIn,
            check_out=request.checkOut,
            adults=request.adults,
            room_qty=request.roomQty,
            currency=request.currency,
        )

        # Construire les résumés d'offres
        offer_summaries = [
            HotelOfferSummary(
                id=offer.id,
                hotelId=offer.hotel_id,
                offerId=offer.offer_id,
                totalPrice=float(offer.total_price) if offer.total_price else None,
                currency=offer.currency,
            )
            for offer in offers
        ]

        return HotelSearchResponse(searchId=search.id, offers=offer_summaries)
    except AppError as e:
        raise create_http_exception(e) from e


@router.get(
    "/{tripId}/hotels/searches/{searchId}",
    response_model=HotelSearchDetailResponse,
    summary="Get hotel search details",
    description="Get detailed information about a hotel search with offers",
)
async def get_hotel_search(
    tripId: UUID = Path(..., description="Trip ID"),
    searchId: UUID = Path(..., description="Search ID"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Récupérer une recherche d'hôtel selon PLAN.md."""
    try:
        search = HotelSearchService.get_search_by_id(db, searchId, tripId, current_user.id)
        if not search:
            raise AppError("SEARCH_NOT_FOUND", 404, "Hotel search not found")

        offers = HotelSearchService.get_offers_by_search(db, searchId, tripId, current_user.id)

        return HotelSearchDetailResponse(
            search={
                "id": str(search.id),
                "cityCode": search.city_code,
                "latitude": float(search.latitude) if search.latitude else None,
                "longitude": float(search.longitude) if search.longitude else None,
                "checkIn": search.check_in.isoformat() if search.check_in else None,
                "checkOut": search.check_out.isoformat() if search.check_out else None,
                "adults": search.adults,
                "roomQty": search.room_qty,
            },
            offers=[
                HotelOfferDetail(
                    id=offer.id,
                    hotelId=offer.hotel_id,
                    offerId=offer.offer_id,
                    chainCode=offer.chain_code,
                    roomType=offer.room_type,
                    currency=offer.currency,
                    totalPrice=float(offer.total_price) if offer.total_price else None,
                    offer=offer.offer_json if offer.offer_json else {},
                )
                for offer in offers
            ],
        )
    except AppError as e:
        raise create_http_exception(e) from e

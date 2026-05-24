"""Routes pour la recherche d'hôtels via Amadeus.

Search-only hotel discovery. No booking/reservation via Amadeus is supported.
Users book accommodations externally and record them via the
/v1/trips/{tripId}/accommodations CRUD endpoints.
"""

from typing import Annotated

from fastapi import APIRouter, Depends, Query

from src.api.auth.middleware import get_current_user
from src.api.hotels.schemas import (
    HotelListSearchResponse,
    HotelOffersSearchResponse,
)
from src.integrations.amadeus.types import (
    HotelListSearchQuery,
    HotelOffersSearchQuery,
)
from src.services.amadeus_service import AmadeusService

router = APIRouter(prefix="/v1/travel/hotels", tags=["Hotel Search"])


@router.get("/by-city", response_model=HotelListSearchResponse)
async def search_hotels_by_city(
    cityCode: Annotated[str, Query(..., description="IATA city code (e.g. PAR)")],
    _current_user: Annotated[object, Depends(get_current_user)],
    radius: Annotated[int | None, Query(description="Search radius")] = None,
    radiusUnit: Annotated[str | None, Query(description="KM or MILE")] = None,
    ratings: Annotated[str | None, Query(description="Comma-separated star ratings")] = None,
    hotelSource: Annotated[str | None, Query(description="ALL, BEDBANK, or DIRECTCHAIN")] = None,
):
    """Recherche d'hôtels par ville via Amadeus."""
    query = HotelListSearchQuery(
        cityCode=cityCode,
        radius=radius,
        radiusUnit=radiusUnit,
        ratings=ratings,
        hotelSource=hotelSource,
    )
    result = await AmadeusService.search_hotel_list(query)
    return HotelListSearchResponse(
        data=[h.model_dump() for h in result.data],
    )


@router.get("/offers", response_model=HotelOffersSearchResponse)
async def search_hotel_offers(
    hotelIds: Annotated[str, Query(..., description="Comma-separated hotel IDs (max 50)")],
    _current_user: Annotated[object, Depends(get_current_user)],
    checkInDate: Annotated[str | None, Query(description="YYYY-MM-DD")] = None,
    checkOutDate: Annotated[str | None, Query(description="YYYY-MM-DD")] = None,
    adults: Annotated[int | None, Query(description="Number of adults")] = 1,
    currency: Annotated[str | None, Query(description="Currency code")] = None,
):
    """Recherche d'offres d'hôtels avec prix via Amadeus."""
    query = HotelOffersSearchQuery(
        hotelIds=hotelIds,
        adults=adults,
        checkInDate=checkInDate,
        checkOutDate=checkOutDate,
        currency=currency,
    )
    result = await AmadeusService.search_hotel_offers(query)
    return HotelOffersSearchResponse(
        data=[r.model_dump() for r in result.data],
    )

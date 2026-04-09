"""Routes pour la recherche d'hôtels via Amadeus.

Search-only hotel discovery. No booking/reservation via Amadeus is supported.
Users book accommodations externally and record them via the
/v1/trips/{tripId}/accommodations CRUD endpoints.
"""

from fastapi import APIRouter, Depends, Query

from src.api.auth.middleware import get_current_user
from src.api.hotels.schemas import (
    HotelListSearchResponse,
    HotelOffersSearchResponse,
)
from src.integrations.amadeus.client import amadeus_client
from src.integrations.amadeus.types import (
    HotelListSearchQuery,
    HotelOffersSearchQuery,
)

router = APIRouter(prefix="/v1/travel/hotels", tags=["Hotel Search"])


@router.get("/by-city", response_model=HotelListSearchResponse)
async def search_hotels_by_city(
    cityCode: str = Query(..., description="IATA city code (e.g. PAR)"),
    radius: int | None = Query(None, description="Search radius"),
    radiusUnit: str | None = Query(None, description="KM or MILE"),
    ratings: str | None = Query(None, description="Comma-separated star ratings"),
    hotelSource: str | None = Query(None, description="ALL, BEDBANK, or DIRECTCHAIN"),
    _current_user=Depends(get_current_user),
):
    """Recherche d'hôtels par ville via Amadeus."""
    query = HotelListSearchQuery(
        cityCode=cityCode,
        radius=radius,
        radiusUnit=radiusUnit,
        ratings=ratings,
        hotelSource=hotelSource,
    )
    result = await amadeus_client.search_hotel_list(query)
    return HotelListSearchResponse(
        data=[h.model_dump() for h in result.data],
    )


@router.get("/offers", response_model=HotelOffersSearchResponse)
async def search_hotel_offers(
    hotelIds: str = Query(..., description="Comma-separated hotel IDs (max 50)"),
    checkInDate: str | None = Query(None, description="YYYY-MM-DD"),
    checkOutDate: str | None = Query(None, description="YYYY-MM-DD"),
    adults: int | None = Query(1, description="Number of adults"),
    currency: str | None = Query(None, description="Currency code"),
    _current_user=Depends(get_current_user),
):
    """Recherche d'offres d'hôtels avec prix via Amadeus."""
    query = HotelOffersSearchQuery(
        hotelIds=hotelIds,
        adults=adults,
        checkInDate=checkInDate,
        checkOutDate=checkOutDate,
        currency=currency,
    )
    result = await amadeus_client.search_hotel_offers(query)
    return HotelOffersSearchResponse(
        data=[r.model_dump() for r in result.data],
    )

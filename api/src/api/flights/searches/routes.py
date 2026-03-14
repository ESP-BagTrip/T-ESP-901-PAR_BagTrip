"""Routes pour les recherches de vols."""

from uuid import UUID

from fastapi import APIRouter, Depends, Path, status
from sqlalchemy.orm import Session

from src.api.auth.trip_access import TripAccess, TripRole, get_trip_access, get_trip_owner_access
from src.api.flights.searches.schemas import (
    FlightOfferDetail,
    FlightOfferSummary,
    FlightSearchCreateRequest,
    FlightSearchDetailResponse,
    FlightSearchResponse,
)
from src.config.database import get_db
from src.services.flight_search_service import FlightSearchService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/trips", tags=["Flight Searches"])


@router.post(
    "/{tripId}/flights/searches",
    response_model=FlightSearchResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create flight search",
    description="Search for flights and persist results",
)
async def create_flight_search(
    request: FlightSearchCreateRequest,
    access: TripAccess = Depends(get_trip_owner_access),
    db: Session = Depends(get_db),
):
    """Créer une recherche de vol selon PLAN.md."""
    try:
        search, offers = await FlightSearchService.create_search(
            db=db,
            trip_id=access.trip.id,
            origin_iata=request.originIata,
            destination_iata=request.destinationIata,
            departure_date=request.departureDate,
            return_date=request.returnDate,
            adults=request.adults,
            children=request.children,
            infants=request.infants,
            travel_class=request.travelClass,
            non_stop=request.nonStop,
            currency=request.currency,
        )

        # Construire les résumés d'offres
        offer_summaries = []
        for offer in offers:
            # Extraire les informations sur les stops depuis offer_json
            summary = {}
            if offer.offer_json and isinstance(offer.offer_json, dict):
                itineraries = offer.offer_json.get("itineraries", [])
                if itineraries:
                    # Compter les stops
                    segments = itineraries[0].get("segments", [])
                    stops = max(0, len(segments) - 1)
                    summary["stops"] = stops

            offer_summaries.append(
                FlightOfferSummary(
                    id=offer.id,
                    grandTotal=float(offer.grand_total) if offer.grand_total else None,
                    currency=offer.currency,
                    summary=summary if summary else None,
                )
            )

        return FlightSearchResponse(searchId=search.id, offers=offer_summaries)
    except AppError as e:
        raise create_http_exception(e) from e


@router.get(
    "/{tripId}/flights/searches/{searchId}",
    response_model=FlightSearchDetailResponse,
    summary="Get flight search details",
    description="Get detailed information about a flight search with offers",
)
async def get_flight_search(
    searchId: UUID = Path(..., description="Search ID"),
    access: TripAccess = Depends(get_trip_access),
    db: Session = Depends(get_db),
):
    """Récupérer une recherche de vol selon PLAN.md."""
    try:
        search = FlightSearchService.get_search_by_id(db, searchId, access.trip.id)
        if not search:
            raise AppError("SEARCH_NOT_FOUND", 404, "Flight search not found")

        offers = FlightSearchService.get_offers_by_search(db, searchId, access.trip.id)

        is_viewer = access.role == TripRole.VIEWER

        offer_details = [
            FlightOfferDetail(
                id=offer.id,
                amadeusOfferId=offer.amadeus_offer_id,
                grandTotal=None if is_viewer else (float(offer.grand_total) if offer.grand_total else None),
                baseTotal=None if is_viewer else (float(offer.base_total) if offer.base_total else None),
                currency=offer.currency,
                offer=offer.offer_json if offer.offer_json else {},
            )
            for offer in offers
        ]

        return FlightSearchDetailResponse(
            search={
                "id": str(search.id),
                "originIata": search.origin_iata,
                "destinationIata": search.destination_iata,
                "departureDate": search.departure_date.isoformat()
                if search.departure_date
                else None,
                "returnDate": search.return_date.isoformat() if search.return_date else None,
                "adults": search.adults,
            },
            offers=offer_details,
        )
    except AppError as e:
        raise create_http_exception(e) from e

"""Routes travel pour les recherches de locations (offline) et vols (Amadeus)."""

import hashlib
import json
from typing import Annotated

from cachetools import TTLCache
from fastapi import APIRouter, HTTPException, Path, Query, status

from src.api.travel.schemas import LocationSearchResult
from src.integrations.amadeus.types import (
    FlightCheapestDateSearchQuery,
    FlightInspirationSearchQuery,
    FlightOfferSearchQuery,
)
from src.integrations.aviation_data import aviation_data_service
from src.services.amadeus_service import AmadeusService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/travel", tags=["Travel"])

# Flight search cache — 15 min TTL, max 256 entries
_flight_search_cache: TTLCache = TTLCache(maxsize=256, ttl=900)


def _flight_cache_key(**params: object) -> str:
    """Build a deterministic cache key from search params (ignoring None values)."""
    filtered = {k: v for k, v in sorted(params.items()) if v is not None}
    normalized = json.dumps(filtered, sort_keys=True, default=str)
    return hashlib.sha256(normalized.encode()).hexdigest()


# ============================================================================
# LOCATION ENDPOINTS — Offline (aviation_data)
# ============================================================================


@router.get(
    "/locations",
    summary="Search for locations (cities, airports, etc.)",
    description="Search for locations by keyword and sub-type",
    responses={
        200: {
            "description": "List of matching locations",
        },
        400: {"description": "Bad request - Invalid query parameters"},
        500: {"description": "Internal server error"},
    },
)
async def search_locations_by_keyword(
    subType: Annotated[
        str,
        Query(
            ...,
            description="Comma-separated list of location sub-types (e.g., 'CITY,AIRPORT')",
            example="CITY,AIRPORT",
        ),
    ],
    keyword: Annotated[
        str, Query(..., description="Search keyword for location name", example="paris")
    ],
):
    """
    Recherche de locations par mot-clé (données offline).

    - **subType**: Types de locations à rechercher (ex: "CITY,AIRPORT")
    - **keyword**: Mot-clé de recherche (ex: "paris")
    """
    try:
        if not subType or not keyword:
            raise AppError("INVALID_QUERY", 400, "subType and keyword are required")

        locations = aviation_data_service.search_by_keyword(keyword, sub_type=subType)
        return LocationSearchResult(locations=locations, count=len(locations))
    except AppError as e:
        raise create_http_exception(e) from e
    except HTTPException:
        raise
    except Exception as e:
        raise create_http_exception(
            AppError("INTERNAL_ERROR", 500, "Failed to search locations")
        ) from e


@router.get(
    "/locations/nearest",
    summary="Search for locations nearest to a given latitude and longitude",
    description="Find airports and locations closest to a geographic coordinate",
    responses={
        200: {
            "description": "List of matching locations",
        },
        400: {"description": "Bad request - Invalid query parameters"},
        500: {"description": "Internal server error"},
    },
)
async def search_location_nearest(
    latitude: Annotated[float, Query(..., ge=-90, le=90, description="Latitude", example=49.0000)],
    longitude: Annotated[float, Query(..., ge=-180, le=180, description="Longitude", example=2.55)],
):
    """
    Recherche de locations les plus proches (données offline).

    - **latitude**: Latitude (-90 à 90)
    - **longitude**: Longitude (-180 à 180)
    """
    try:
        if latitude is None or longitude is None:
            raise AppError("INVALID_QUERY", 400, "latitude and longitude are required")

        if not (-90 <= latitude <= 90):
            raise AppError("INVALID_QUERY", 400, "Latitude must be between -90 and 90")

        if not (-180 <= longitude <= 180):
            raise AppError("INVALID_QUERY", 400, "Longitude must be between -180 and 180")

        locations = aviation_data_service.search_nearest(latitude, longitude)
        return LocationSearchResult(locations=locations, count=len(locations))
    except AppError as e:
        raise create_http_exception(e) from e
    except HTTPException:
        raise
    except Exception as e:
        raise create_http_exception(
            AppError("INTERNAL_ERROR", 500, "Failed to search nearest locations")
        ) from e


@router.get(
    "/locations/{id}",
    summary="Search for a location by id",
    description="Get detailed information about a specific location by its ID",
    responses={
        200: {
            "description": "Location details",
        },
        400: {"description": "Bad request - Invalid query parameters"},
        500: {"description": "Internal server error"},
    },
)
async def search_location_by_id(
    id: Annotated[str, Path(..., description="Location id", example="CMUC")],
):
    """
    Recherche de location par ID (données offline).

    - **id**: ID de la location (ex: "CDG")
    """
    try:
        if not id:
            raise AppError("INVALID_QUERY", 400, "id is required")

        location = aviation_data_service.get_by_id(id)
        if location is None:
            raise AppError("NOT_FOUND", 404, "Location not found")

        return location
    except AppError as e:
        raise create_http_exception(e) from e
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e),
        ) from e


# ============================================================================
# FLIGHT ENDPOINTS — Amadeus (with cache)
# ============================================================================


@router.get(
    "/flight/offers",
    summary="Search for flight offers",
    description="Search for available flight offers between two locations",
    responses={
        200: {
            "description": "List of flight offers",
        },
        400: {"description": "Bad request - Invalid parameters"},
        500: {"description": "Internal server error"},
    },
)
async def search_flight_offers(
    originLocationCode: Annotated[
        str, Query(..., description="IATA code of the departure city/airport", example="PAR")
    ],
    destinationLocationCode: Annotated[
        str, Query(..., description="IATA code of the arrival city/airport", example="FCO")
    ],
    departureDate: Annotated[
        str, Query(..., description="Departure date (YYYY-MM-DD)", example="2025-12-15")
    ],
    adults: Annotated[
        int, Query(..., ge=1, le=9, description="Number of adult travelers (1-9)", example=2)
    ],
    returnDate: Annotated[
        str | None,
        Query(description="Return date for round-trip (YYYY-MM-DD)", example="2025-12-22"),
    ] = None,
    children: Annotated[
        int | None,
        Query(ge=0, le=9, description="Number of child travelers (0-9)", example=None),
    ] = None,
    infants: Annotated[
        int | None,
        Query(
            ge=0,
            le=9,
            description="Number of infant travelers (0-9, cannot exceed adults)",
            example=None,
        ),
    ] = None,
    travelClass: Annotated[
        str | None, Query(description="Cabin class preference", example=None)
    ] = None,
    nonStop: Annotated[
        bool | None, Query(description="Search for non-stop flights only", example=None)
    ] = None,
    currencyCode: Annotated[
        str | None,
        Query(description="Currency code (ISO 4217, 3 letters)", example="USD"),
    ] = None,
    maxPrice: Annotated[
        int | None, Query(gt=0, description="Maximum price per traveler", example=None)
    ] = None,
    max: Annotated[
        int | None,
        Query(
            ge=1,
            le=250,
            description="Maximum number of flight offers to return (1-250)",
            example=10,
        ),
    ] = None,
    includedAirlineCodes: Annotated[
        str | None,
        Query(
            description="Comma-separated list of airline codes to include (e.g., 'AF,BA'). "
            "Note: Cannot be used together with excludedAirlineCodes.",
            example=None,
        ),
    ] = None,
    excludedAirlineCodes: Annotated[
        str | None,
        Query(
            description="Comma-separated list of airline codes to exclude. "
            "Note: Cannot be used together with includedAirlineCodes.",
            example=None,
        ),
    ] = None,
):
    """
    Recherche d'offres de vols.

    Recherche des offres de vols disponibles entre deux destinations avec de nombreux paramètres optionnels.
    Résultats mis en cache 15 minutes pour les recherches identiques.
    """
    try:
        if not originLocationCode or not destinationLocationCode or not departureDate:
            raise AppError(
                "INVALID_QUERY",
                400,
                "originLocationCode, destinationLocationCode, and departureDate are required",
            )

        if adults < 1 or adults > 9:
            raise AppError("INVALID_QUERY", 400, "adults must be between 1 and 9")

        if children is not None and (children < 0 or children > 9):
            raise AppError("INVALID_QUERY", 400, "children must be between 0 and 9")

        if infants is not None and (infants < 0 or infants > 9):
            raise AppError("INVALID_QUERY", 400, "infants must be between 0 and 9")

        if infants is not None and infants > adults:
            raise AppError("INVALID_QUERY", 400, "infants cannot exceed the number of adults")

        if maxPrice is not None and maxPrice <= 0:
            raise AppError("INVALID_QUERY", 400, "maxPrice must be a positive integer")

        if max is not None and (max < 1 or max > 250):
            raise AppError("INVALID_QUERY", 400, "max must be between 1 and 250")

        # Amadeus doesn't allow both includedAirlineCodes and excludedAirlineCodes together
        if includedAirlineCodes and excludedAirlineCodes:
            raise AppError(
                "INVALID_QUERY",
                400,
                "includedAirlineCodes and excludedAirlineCodes cannot be used together. "
                "Please use only one.",
            )

        # Check cache
        cache_key = _flight_cache_key(
            originLocationCode=originLocationCode,
            destinationLocationCode=destinationLocationCode,
            departureDate=departureDate,
            returnDate=returnDate,
            adults=adults,
            children=children,
            infants=infants,
            travelClass=travelClass,
            nonStop=nonStop,
            currencyCode=currencyCode,
            maxPrice=maxPrice,
            max=max,
            includedAirlineCodes=includedAirlineCodes,
            excludedAirlineCodes=excludedAirlineCodes,
        )

        cached = _flight_search_cache.get(cache_key)
        if cached is not None:
            return cached

        query = FlightOfferSearchQuery(
            originLocationCode=originLocationCode,
            destinationLocationCode=destinationLocationCode,
            departureDate=departureDate,
            adults=adults,
            returnDate=returnDate,
            children=children,
            infants=infants,
            travelClass=travelClass,
            nonStop=nonStop,
            currencyCode=currencyCode,
            maxPrice=maxPrice,
            max=max,
            includedAirlineCodes=includedAirlineCodes,
            excludedAirlineCodes=excludedAirlineCodes,
        )

        result = await AmadeusService.search_flight_offers(query)
        _flight_search_cache[cache_key] = result
        return result
    except AppError as e:
        raise create_http_exception(e) from e
    except HTTPException:
        raise
    except Exception as e:
        raise create_http_exception(
            AppError("INTERNAL_ERROR", 500, "Failed to search flight offers")
        ) from e


@router.get(
    "/flight/destinations",
    summary="Search for flight destinations (inspiration)",
    description="Find inspiring flight destinations from an origin, useful for 'Where can I go?' queries",
    responses={
        200: {
            "description": "List of flight destinations",
        },
        400: {"description": "Bad request - Invalid parameters"},
        500: {"description": "Internal server error"},
    },
)
async def search_flight_destinations(
    origin: Annotated[
        str, Query(..., description="IATA code of the departure city/airport", example="PAR")
    ],
    departureDate: Annotated[
        str | None,
        Query(
            description="Departure date or date range (YYYY-MM-DD or YYYY-MM-DD,YYYY-MM-DD)",
            example="2025-12-15",
        ),
    ] = None,
    oneWay: Annotated[
        bool | None, Query(description="Search for one-way trips only", example=False)
    ] = None,
    duration: Annotated[
        int | None, Query(gt=0, description="Trip duration in days", example=7)
    ] = None,
    nonStop: Annotated[
        bool | None, Query(description="Search for non-stop flights only", example=False)
    ] = None,
    maxPrice: Annotated[
        int | None, Query(gt=0, description="Maximum price per traveler", example=500)
    ] = None,
    viewBy: Annotated[
        str | None,
        Query(
            description="Group results by specific criteria (DURATION, COUNTRY, DATE, DESTINATION, WEEK)",
            example="DESTINATION",
        ),
    ] = None,
):
    """
    Recherche de destinations inspirantes.

    Trouve des destinations inspirantes à partir d'un aéroport d'origine.
    """
    try:
        if not origin:
            raise AppError("INVALID_QUERY", 400, "origin is required")

        if duration is not None and duration <= 0:
            raise AppError("INVALID_QUERY", 400, "duration must be a positive integer")

        if maxPrice is not None and maxPrice <= 0:
            raise AppError("INVALID_QUERY", 400, "maxPrice must be a positive integer")

        query = FlightInspirationSearchQuery(
            origin=origin,
            departureDate=departureDate,
            oneWay=oneWay,
            duration=duration,
            nonStop=nonStop,
            maxPrice=maxPrice,
            viewBy=viewBy,
        )

        result = await AmadeusService.search_flight_destinations(query)
        return result
    except AppError as e:
        raise create_http_exception(e) from e
    except HTTPException:
        raise
    except Exception as e:
        raise create_http_exception(
            AppError("INTERNAL_ERROR", 500, "Failed to search flight destinations")
        ) from e


@router.get(
    "/flight/cheapest-dates",
    summary="Search for cheapest flight dates",
    description="Find the cheapest dates to fly between two destinations",
    responses={
        200: {
            "description": "List of cheapest dates with prices",
        },
        400: {"description": "Bad request - Invalid parameters"},
        500: {"description": "Internal server error"},
    },
)
async def search_flight_cheapest_dates(
    origin: Annotated[
        str, Query(..., description="IATA code of the departure city/airport", example="PAR")
    ],
    destination: Annotated[
        str, Query(..., description="IATA code of the arrival city/airport", example="NYC")
    ],
    departureDate: Annotated[
        str | None,
        Query(
            description="Departure date or date range (YYYY-MM-DD or YYYY-MM-DD,YYYY-MM-DD)",
            example="2025-12-15",
        ),
    ] = None,
    oneWay: Annotated[
        bool | None, Query(description="Search for one-way trips only", example=False)
    ] = None,
    duration: Annotated[
        int | None, Query(gt=0, description="Trip duration in days", example=7)
    ] = None,
    nonStop: Annotated[
        bool | None, Query(description="Search for non-stop flights only", example=False)
    ] = None,
    maxPrice: Annotated[
        int | None, Query(gt=0, description="Maximum price per traveler", example=500)
    ] = None,
    viewBy: Annotated[
        str | None,
        Query(
            description="Group results by specific criteria (DATE, DURATION, WEEK)",
            example="DATE",
        ),
    ] = None,
):
    """
    Recherche des dates les moins chères.

    Trouve les dates les moins chères pour voler entre deux destinations.
    """
    try:
        if not origin:
            raise AppError("INVALID_QUERY", 400, "origin is required")

        if not destination:
            raise AppError("INVALID_QUERY", 400, "destination is required")

        if duration is not None and duration <= 0:
            raise AppError("INVALID_QUERY", 400, "duration must be a positive integer")

        if maxPrice is not None and maxPrice <= 0:
            raise AppError("INVALID_QUERY", 400, "maxPrice must be a positive integer")

        query = FlightCheapestDateSearchQuery(
            origin=origin,
            destination=destination,
            departureDate=departureDate,
            oneWay=oneWay,
            duration=duration,
            nonStop=nonStop,
            maxPrice=maxPrice,
            viewBy=viewBy,
        )

        result = await AmadeusService.search_flight_cheapest_dates(query)
        return result
    except AppError as e:
        raise create_http_exception(e) from e
    except HTTPException:
        raise
    except Exception as e:
        raise create_http_exception(
            AppError("INTERNAL_ERROR", 500, "Failed to search cheapest flight dates")
        ) from e

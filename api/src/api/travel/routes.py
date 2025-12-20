"""Routes travel pour les recherches Amadeus."""

from fastapi import APIRouter, HTTPException, Path, Query, status

from src.api.travel.schemas import LocationSearchResult
from src.integrations.amadeus import amadeus_client
from src.integrations.amadeus.types import (
    FlightCheapestDateSearchQuery,
    FlightInspirationSearchQuery,
    FlightOfferSearchQuery,
    LocationIdSearchQuery,
    LocationKeywordSearchQuery,
    LocationNearestSearchQuery,
)
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/travel", tags=["Travel"])


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
    subType: str = Query(
        ...,
        description="Comma-separated list of location sub-types (e.g., 'CITY,AIRPORT')",
        example="CITY,AIRPORT",
    ),
    keyword: str = Query(..., description="Search keyword for location name", example="paris"),
):
    """
    Recherche de locations par mot-clé.

    - **subType**: Types de locations à rechercher (ex: "CITY,AIRPORT")
    - **keyword**: Mot-clé de recherche (ex: "paris")
    """
    try:
        if not subType or not keyword:
            raise AppError("INVALID_QUERY", 400, "subType and keyword are required")

        query = LocationKeywordSearchQuery(subType=subType, keyword=keyword)
        locations = await amadeus_client.search_locations_by_keyword(query)

        return LocationSearchResult(locations=locations, count=len(locations))
    except AppError as e:
        raise create_http_exception(e) from e
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e),
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
async def search_location_by_id(id: str = Path(..., description="Location id", example="CMUC")):
    """
    Recherche de location par ID.

    - **id**: ID de la location (ex: "CMUC")
    """
    try:
        if not id:
            raise AppError("INVALID_QUERY", 400, "id is required")

        query = LocationIdSearchQuery(id=id)
        location = await amadeus_client.search_location_by_id(query)

        return location
    except AppError as e:
        raise create_http_exception(e) from e
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e),
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
    latitude: float = Query(..., ge=-90, le=90, description="Latitude", example=49.0000),
    longitude: float = Query(..., ge=-180, le=180, description="Longitude", example=2.55),
):
    """
    Recherche de locations les plus proches.

    - **latitude**: Latitude (-90 à 90)
    - **longitude**: Longitude (-180 à 180)
    """
    try:
        if latitude is None or longitude is None:
            raise AppError("INVALID_QUERY", 400, "latitude and longitude are required")

        query = LocationNearestSearchQuery(latitude=latitude, longitude=longitude)
        locations = await amadeus_client.search_location_nearest(query)

        return LocationSearchResult(locations=locations, count=len(locations))
    except AppError as e:
        raise create_http_exception(e) from e
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e),
        ) from e


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
    originLocationCode: str = Query(
        ..., description="IATA code of the departure city/airport", example="PAR"
    ),
    destinationLocationCode: str = Query(
        ..., description="IATA code of the arrival city/airport", example="FCO"
    ),
    departureDate: str = Query(
        ..., description="Departure date (YYYY-MM-DD)", example="2025-12-15"
    ),
    adults: int = Query(..., ge=1, le=9, description="Number of adult travelers (1-9)", example=2),
    returnDate: str | None = Query(
        None, description="Return date for round-trip (YYYY-MM-DD)", example="2025-12-22"
    ),
    children: int | None = Query(
        None, ge=0, le=9, description="Number of child travelers (0-9)", example=None
    ),
    infants: int | None = Query(
        None,
        ge=0,
        le=9,
        description="Number of infant travelers (0-9, cannot exceed adults)",
        example=None,
    ),
    travelClass: str | None = Query(None, description="Cabin class preference", example=None),
    nonStop: bool | None = Query(
        None, description="Search for non-stop flights only", example=None
    ),
    currencyCode: str | None = Query(
        None, description="Currency code (ISO 4217, 3 letters)", example="USD"
    ),
    maxPrice: int | None = Query(
        None, gt=0, description="Maximum price per traveler", example=None
    ),
    max: int | None = Query(
        None,
        ge=1,
        le=250,
        description="Maximum number of flight offers to return (1-250)",
        example=10,
    ),
    includedAirlineCodes: str | None = Query(
        None,
        description="Comma-separated list of airline codes to include (e.g., 'AF,BA'). "
        "Note: Cannot be used together with excludedAirlineCodes.",
        example=None,
    ),
    excludedAirlineCodes: str | None = Query(
        None,
        description="Comma-separated list of airline codes to exclude. "
        "Note: Cannot be used together with includedAirlineCodes.",
        example=None,
    ),
):
    """
    Recherche d'offres de vols.

    Recherche des offres de vols disponibles entre deux destinations avec de nombreux paramètres optionnels.
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

        result = await amadeus_client.search_flight_offers(query)
        return result
    except AppError as e:
        raise create_http_exception(e) from e
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e),
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
    origin: str = Query(..., description="IATA code of the departure city/airport", example="PAR"),
    departureDate: str | None = Query(
        None,
        description="Departure date or date range (YYYY-MM-DD or YYYY-MM-DD,YYYY-MM-DD)",
        example="2025-12-15",
    ),
    oneWay: bool | None = Query(None, description="Search for one-way trips only", example=False),
    duration: int | None = Query(None, gt=0, description="Trip duration in days", example=7),
    nonStop: bool | None = Query(
        None, description="Search for non-stop flights only", example=False
    ),
    maxPrice: int | None = Query(None, gt=0, description="Maximum price per traveler", example=500),
    viewBy: str | None = Query(
        None,
        description="Group results by specific criteria (DURATION, COUNTRY, DATE, DESTINATION, WEEK)",
        example="DESTINATION",
    ),
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

        result = await amadeus_client.search_flight_destinations(query)
        return result
    except AppError as e:
        raise create_http_exception(e) from e
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e),
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
    origin: str = Query(..., description="IATA code of the departure city/airport", example="PAR"),
    destination: str = Query(
        ..., description="IATA code of the arrival city/airport", example="NYC"
    ),
    departureDate: str | None = Query(
        None,
        description="Departure date or date range (YYYY-MM-DD or YYYY-MM-DD,YYYY-MM-DD)",
        example="2025-12-15",
    ),
    oneWay: bool | None = Query(None, description="Search for one-way trips only", example=False),
    duration: int | None = Query(None, gt=0, description="Trip duration in days", example=7),
    nonStop: bool | None = Query(
        None, description="Search for non-stop flights only", example=False
    ),
    maxPrice: int | None = Query(None, gt=0, description="Maximum price per traveler", example=500),
    viewBy: str | None = Query(
        None,
        description="Group results by specific criteria (DATE, DURATION, WEEK)",
        example="DATE",
    ),
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

        result = await amadeus_client.search_flight_cheapest_dates(query)
        return result
    except AppError as e:
        raise create_http_exception(e) from e
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e),
        ) from e

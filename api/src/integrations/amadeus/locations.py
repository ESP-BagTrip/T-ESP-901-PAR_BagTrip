"""Recherche de locations Amadeus."""

import httpx

from src.config.env import settings
from src.integrations.amadeus.errors import raise_amadeus_connection_error, raise_for_amadeus_status
from src.integrations.amadeus.retry import amadeus_retry
from src.integrations.http_client import get_http_client
from src.utils.errors import AppError
from src.utils.logger import logger

from .auth import fetch_token
from .types import (
    Location,
    LocationIdSearchQuery,
    LocationKeywordSearchQuery,
    LocationNearestSearchQuery,
)


@amadeus_retry
async def search_locations_by_keyword(query: LocationKeywordSearchQuery) -> list[Location]:
    """
    Appel Reference Data Locations: GET /v1/reference-data/locations
    Recherche de locations par mot-clé.
    """
    logger.debug("Starting location search by keyword", {"query": query.model_dump()})
    token = await fetch_token()

    url = f"{settings.AMADEUS_BASE_URL}/v1/reference-data/locations"
    params = query.model_dump()

    try:
        logger.info("Making Amadeus location search request", {"url": url, "params": params})

        client = get_http_client()
        response = await client.get(
            url,
            params=params,
            headers={"Authorization": f"Bearer {token}"},
            timeout=settings.REQUEST_TIMEOUT_MS / 1000,
        )

        logger.debug(
            "Amadeus location search response",
            {
                "status": response.status_code,
                "statusText": response.reason_phrase,
                "dataCount": len(response.json().get("data", []))
                if response.status_code == 200
                else 0,
            },
        )

        if response.status_code != 200:
            logger.error(
                "Amadeus location search failed",
                {"status": response.status_code, "data": response.text},
            )
            raise_for_amadeus_status(response, "location keyword search")

        data = response.json()
        locations_data = data.get("data", [])

        locations = [Location(**loc) for loc in locations_data]

        logger.info("Location search completed successfully", {"locationsCount": len(locations)})
        return locations

    except httpx.HTTPError as error:
        logger.error("Amadeus location search failed", {"message": str(error)})
        raise_amadeus_connection_error(error, "location keyword search")


@amadeus_retry
async def search_location_by_id(query: LocationIdSearchQuery) -> Location:
    """
    Recherche une location par son ID.
    Appel Reference Data Locations: GET /v1/reference-data/locations/{id}
    """
    logger.debug("Starting location search by id", {"query": query.model_dump()})
    token = await fetch_token()

    url = f"{settings.AMADEUS_BASE_URL}/v1/reference-data/locations/{query.id}"

    try:
        logger.info("Making Amadeus location search request", {"url": url})

        client = get_http_client()
        response = await client.get(
            url,
            headers={"Authorization": f"Bearer {token}"},
            timeout=settings.REQUEST_TIMEOUT_MS / 1000,
        )

        logger.debug(
            "Amadeus location search response",
            {
                "status": response.status_code,
                "statusText": response.reason_phrase,
                "data": response.json() if response.status_code == 200 else None,
            },
        )

        if response.status_code != 200:
            logger.error(
                "Amadeus location search failed",
                {"status": response.status_code, "data": response.text},
            )
            raise_for_amadeus_status(response, "location ID search")

        data = response.json()
        location_data = data.get("data")

        if not location_data:
            raise AppError("NOT_FOUND", 404, "Location not found")

        location = Location(**location_data)
        logger.info("Location search completed successfully", {"location": location.id})
        return location

    except httpx.HTTPError as error:
        logger.error("Amadeus location search failed", {"message": str(error)})
        raise_amadeus_connection_error(error, "location ID search")


@amadeus_retry
async def search_location_nearest(query: LocationNearestSearchQuery) -> list[Location]:
    """
    Recherche les aéroports les plus proches d'une position géographique.
    Appel Reference Data Locations: GET /v1/reference-data/locations/airports
    """
    logger.debug("Starting location nearest search", {"query": query.model_dump()})
    token = await fetch_token()

    url = f"{settings.AMADEUS_BASE_URL}/v1/reference-data/locations/airports"
    params = query.model_dump()

    try:
        logger.info(
            "Making Amadeus location nearest search request", {"url": url, "params": params}
        )

        client = get_http_client()
        response = await client.get(
            url,
            params=params,
            headers={"Authorization": f"Bearer {token}"},
            timeout=settings.REQUEST_TIMEOUT_MS / 1000,
        )

        logger.debug(
            "Amadeus location nearest search response",
            {
                "status": response.status_code,
                "statusText": response.reason_phrase,
                "data": response.json() if response.status_code == 200 else None,
            },
        )

        if response.status_code != 200:
            logger.error(
                "Amadeus location nearest search failed",
                {"status": response.status_code, "data": response.text},
            )
            raise_for_amadeus_status(response, "location nearest search")

        data = response.json()
        locations_data = data.get("data", [])

        locations = [Location(**loc) for loc in locations_data]

        logger.info(
            "Location nearest search completed successfully", {"locationsCount": len(locations)}
        )
        return locations

    except httpx.HTTPError as error:
        logger.error("Amadeus location nearest search failed", {"message": str(error)})
        raise_amadeus_connection_error(error, "location nearest search")

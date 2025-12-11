"""Recherche de locations Amadeus."""

import httpx

from src.config.env import settings
from src.utils.logger import logger

from .auth import fetch_token
from .types import (
    Location,
    LocationIdSearchQuery,
    LocationKeywordSearchQuery,
    LocationNearestSearchQuery,
)


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

        async with httpx.AsyncClient(timeout=settings.REQUEST_TIMEOUT_MS / 1000) as client:
            response = await client.get(
                url,
                params=params,
                headers={"Authorization": f"Bearer {token}"},
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
            raise Exception(f"Amadeus location search failed: {response.status_code}")

        data = response.json()
        locations_data = data.get("data", [])

        locations = [Location(**loc) for loc in locations_data]

        logger.info("Location search completed successfully", {"locationsCount": len(locations)})
        return locations

    except httpx.HTTPError as error:
        logger.error("Amadeus location search failed", {"message": str(error)})
        raise Exception(f"Amadeus location search failed: {str(error)}") from error


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

        async with httpx.AsyncClient(timeout=settings.REQUEST_TIMEOUT_MS / 1000) as client:
            response = await client.get(
                url,
                headers={"Authorization": f"Bearer {token}"},
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
            raise Exception(f"Amadeus location search failed: {response.status_code}")

        data = response.json()
        location_data = data.get("data")

        if not location_data:
            raise Exception("Location not found")

        location = Location(**location_data)
        logger.info("Location search completed successfully", {"location": location.id})
        return location

    except httpx.HTTPError as error:
        logger.error("Amadeus location search failed", {"message": str(error)})
        raise Exception(f"Amadeus location search failed: {str(error)}") from error


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

        async with httpx.AsyncClient(timeout=settings.REQUEST_TIMEOUT_MS / 1000) as client:
            response = await client.get(
                url,
                params=params,
                headers={"Authorization": f"Bearer {token}"},
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
            raise Exception(f"Amadeus location nearest search failed: {response.status_code}")

        data = response.json()
        locations_data = data.get("data", [])

        locations = [Location(**loc) for loc in locations_data]

        logger.info(
            "Location nearest search completed successfully", {"locationsCount": len(locations)}
        )
        return locations

    except httpx.HTTPError as error:
        logger.error("Amadeus location nearest search failed", {"message": str(error)})
        raise Exception(f"Amadeus location nearest search failed: {str(error)}") from error

"""Recherche et réservation d'hôtels Amadeus."""

import httpx

from src.config.env import settings
from src.utils.logger import logger

from .auth import fetch_token


async def search_hotel_list_by_city(city_code: str) -> dict:
    """
    Recherche d'hôtels par code ville: GET /v1/reference-data/locations/hotels/by-city
    Retourne la liste des hôtels pour une ville donnée.
    """
    token = await fetch_token()
    url = f"{settings.AMADEUS_BASE_URL}/v1/reference-data/locations/hotels/by-city"

    params = {"cityCode": city_code}

    try:
        logger.info("Making Amadeus hotel list by city request", {"url": url, "params": params})

        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(
                url,
                headers={"Authorization": f"Bearer {token}"},
                params=params,
            )

        if response.status_code != 200:
            logger.error(
                "Amadeus hotel list by city failed",
                {
                    "status": response.status_code,
                    "response": response.text,
                },
            )
            raise Exception(f"Amadeus hotel list by city failed: {response.status_code}")

        return response.json()

    except httpx.HTTPError as error:
        logger.error(
            "Amadeus hotel list by city HTTP error",
            {"error": str(error)},
            exc_info=True,
        )
        raise Exception(f"Amadeus hotel list by city failed: {str(error)}") from error


async def search_hotel_offers(
    city_code: str | None = None,
    latitude: float | None = None,
    longitude: float | None = None,
    check_in: str | None = None,
    check_out: str | None = None,
    adults: int = 1,
    room_qty: int = 1,
    currency: str | None = None,
) -> dict:
    """
    Appel Hotel Offers: GET /v3/shopping/hotel-offers
    Recherche d'offres d'hôtels.
    Si city_code est fourni, recherche d'abord les hôtels de la ville, puis leurs offres.
    """
    logger.debug(
        "Starting hotel offers search",
        {
            "city_code": city_code,
            "latitude": latitude,
            "longitude": longitude,
            "check_in": check_in,
            "check_out": check_out,
        },
    )
    token = await fetch_token()

    # Si city_code est fourni, on doit d'abord obtenir les hotelIds
    hotel_ids = None
    if city_code:
        try:
            hotel_list_response = await search_hotel_list_by_city(city_code)
            hotel_data = hotel_list_response.get("data", [])
            # Extraire les IDs des hôtels (limiter à 20 pour éviter des requêtes trop longues)
            hotel_ids = [hotel.get("hotelId") for hotel in hotel_data[:20] if hotel.get("hotelId")]
            if not hotel_ids:
                logger.warning(
                    f"No hotels found for city code: {city_code}. "
                    "Hotel list search returned empty or no hotelId fields."
                )
                # If we have lat/long as fallback, use that instead
                if latitude is not None and longitude is not None:
                    logger.info("Falling back to latitude/longitude search")
                    hotel_ids = None
                else:
                    # Return empty result instead of raising error
                    logger.warning("No fallback available, returning empty results")
                    return {"data": []}
        except Exception as e:
            logger.error(f"Failed to get hotel list for city {city_code}: {e}")
            # If we have lat/long as fallback, use that instead
            if latitude is not None and longitude is not None:
                logger.info("Falling back to latitude/longitude search after error")
                hotel_ids = None
            else:
                raise ValueError(
                    f"Failed to get hotel list for city {city_code} and no latitude/longitude provided: {e}"
                ) from e

    url = f"{settings.AMADEUS_BASE_URL}/v3/shopping/hotel-offers"

    # Construire les paramètres
    params = {
        "adults": adults,
        "roomQuantity": room_qty,
    }

    if hotel_ids and len(hotel_ids) > 0:
        # Utiliser hotelIds si disponibles
        params["hotelIds"] = ",".join(hotel_ids)
    elif latitude is not None and longitude is not None:
        params["latitude"] = latitude
        params["longitude"] = longitude
    else:
        raise ValueError(
            "Either city_code (to get hotelIds) or latitude/longitude must be provided. "
            f"city_code={city_code}, latitude={latitude}, longitude={longitude}"
        )

    if check_in:
        params["checkInDate"] = check_in
    if check_out:
        params["checkOutDate"] = check_out
    if currency:
        params["currency"] = currency

    try:
        logger.info("Making Amadeus hotel offers search request", {"url": url, "params": params})

        async with httpx.AsyncClient(timeout=20.0) as client:
            response = await client.get(
                url,
                headers={"Authorization": f"Bearer {token}"},
                params=params,
            )

        logger.debug(
            "Amadeus hotel offers search response",
            {
                "status": response.status_code,
                "statusText": response.reason_phrase,
            },
        )

        if response.status_code != 200:
            logger.error(
                "Amadeus hotel offers search failed",
                {
                    "status": response.status_code,
                    "response": response.text,
                },
            )
            raise Exception(f"Amadeus hotel offers search failed: {response.status_code}")

        data = response.json()
        logger.info(
            "Hotel offers search completed successfully",
            {"offers_count": len(data.get("data", []))},
        )

        return data

    except httpx.HTTPError as error:
        logger.error(
            "Amadeus hotel offers search HTTP error",
            {"error": str(error)},
            exc_info=True,
        )
        raise Exception(f"Amadeus hotel offers search failed: {str(error)}") from error


async def book_hotel(
    offer_id: str,
    hotel_id: str,
    guests: list[dict],
    payments: list[dict] | None = None,
) -> dict:
    """
    Appel Hotel Booking: POST /v1/booking/hotel-bookings
    Réserve un hôtel selon la structure Amadeus.
    """
    logger.debug(
        "Starting hotel booking",
        {
            "offer_id": offer_id,
            "hotel_id": hotel_id,
            "guests_count": len(guests),
        },
    )
    token = await fetch_token()

    url = f"{settings.AMADEUS_BASE_URL}/v1/booking/hotel-bookings"

    # Transform guests to include id field and ensure proper structure
    transformed_guests = []
    for idx, guest in enumerate(guests, start=1):
        guest_data = guest.copy()
        # Ensure guest has an id field
        if "id" not in guest_data:
            guest_data["id"] = idx

        # Ensure name structure is correct
        if "name" in guest_data and isinstance(guest_data["name"], dict):
            name_data = guest_data["name"]
            # Add title if missing
            if "title" not in name_data:
                name_data["title"] = "MR"  # Default title
        else:
            # Create name structure if missing
            guest_data["name"] = {"title": "MR", "firstName": "", "lastName": ""}

        # Ensure contact structure has phone if missing
        if "contact" in guest_data and isinstance(guest_data["contact"], dict):
            contact_data = guest_data["contact"]
            # Add phone if missing (Amadeus requires it)
            if "phone" not in contact_data:
                contact_data["phone"] = "+33600000000"  # Default phone
        else:
            # Create contact structure if missing
            guest_data["contact"] = {"phone": "+33600000000", "email": ""}

        transformed_guests.append(guest_data)

    # Build rooms array - associate each guest with a payment
    # Each room should reference guest IDs and optionally a payment ID
    rooms = []
    if payments and len(payments) > 0:
        # If payments provided, associate each guest with payment
        payment_id = 1
        for guest in transformed_guests:
            room = {
                "guestIds": [guest.get("id")],
                "paymentId": payment_id,
            }
            rooms.append(room)
            # Increment payment_id if multiple payments (one per guest typically)
            if len(payments) > 1:
                payment_id += 1
    else:
        # No payments - just associate guests with rooms
        for guest in transformed_guests:
            room = {
                "guestIds": [guest.get("id")],
            }
            rooms.append(room)

    body = {
        "data": {
            "offerId": offer_id,
            "guests": transformed_guests,
            "rooms": rooms,
        }
    }

    if payments:
        body["data"]["payments"] = payments

    # Retry logic for 401 errors (token expiration)
    max_retries = 2
    last_error = None

    for attempt in range(max_retries):
        try:
            # Refresh token if this is a retry after 401
            if attempt > 0:
                logger.info("Retrying hotel booking with fresh token", {"attempt": attempt + 1})
                # Clear token cache to force refresh
                import src.integrations.amadeus.auth as auth_module

                auth_module._token_cache = None
                token = await fetch_token()

            logger.info(
                "Making Amadeus hotel booking request",
                {
                    "url": url,
                    "offer_id": offer_id,
                    "hotel_id": hotel_id,
                    "guests_count": len(guests),
                    "attempt": attempt + 1,
                },
            )
            logger.debug("Hotel booking request body", {"body": body})

            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.post(
                    url,
                    headers={
                        "Authorization": f"Bearer {token}",
                        "Content-Type": "application/json",
                    },
                    json=body,
                )

            logger.debug(
                "Amadeus hotel booking response",
                {
                    "status": response.status_code,
                    "statusText": response.reason_phrase,
                },
            )

            # If 401 and we have retries left, refresh token and retry
            if response.status_code == 401 and attempt < max_retries - 1:
                logger.warn(
                    "Received 401 error, will refresh token and retry",
                    {
                        "attempt": attempt + 1,
                        "max_retries": max_retries,
                    },
                )
                continue

            # Success - break out of retry loop
            if response.status_code in [200, 201]:
                data = response.json()
                logger.info("Hotel booking completed successfully")
                return data

            # Error handling for non-401 errors
            error_text = response.text
            logger.error(
                "Amadeus hotel booking failed",
                {
                    "status": response.status_code,
                    "response": error_text,
                    "offer_id": offer_id,
                    "hotel_id": hotel_id,
                    "request_body": body,
                    "attempt": attempt + 1,
                },
            )
            try:
                error_data = response.json()
                errors = error_data.get("errors", [])
                logger.error("Amadeus error details", {"errors": errors})
                # Extract error message for better debugging
                if errors and isinstance(errors, list) and len(errors) > 0:
                    first_error = errors[0]
                    error_detail = (
                        first_error.get("detail", "")
                        if isinstance(first_error, dict)
                        else str(first_error)
                    )
                    error_code = (
                        first_error.get("code", "") if isinstance(first_error, dict) else ""
                    )
                    error_title = (
                        first_error.get("title", "") if isinstance(first_error, dict) else ""
                    )

                    # Special handling for 404 errors
                    if response.status_code == 404 and (
                        error_code == 38196 or "doesn't exist" in error_detail.lower()
                    ):
                        logger.warn(
                            "Hotel offer not found in Amadeus - may be test environment limitation or offer structure issue",
                            {
                                "offer_id": offer_id,
                                "hotel_id": hotel_id,
                                "error_code": error_code,
                                "error_detail": error_detail,
                            },
                        )

                    # Create a more descriptive error message
                    error_message = f"Amadeus hotel booking failed: {response.status_code}"
                    if error_title:
                        error_message += f" - {error_title}"
                    if error_detail:
                        error_message += f": {error_detail}"
                    if error_code:
                        error_message += f" (code: {error_code})"
                    last_error = Exception(error_message)
                else:
                    last_error = Exception(
                        f"Amadeus hotel booking failed: {response.status_code} - {error_text[:200]}"
                    )
            except Exception as parse_error:
                if isinstance(parse_error, Exception) and "Amadeus hotel booking failed" in str(
                    parse_error
                ):
                    last_error = parse_error
                else:
                    # If parsing failed, raise with original error text
                    last_error = Exception(
                        f"Amadeus hotel booking failed: {response.status_code} - {error_text[:200]}"
                    )

            # If this is the last attempt, raise the error
            if attempt == max_retries - 1:
                raise (
                    last_error
                    if last_error
                    else Exception(f"Amadeus hotel booking failed: {response.status_code}")
                )

        except httpx.HTTPError as error:
            logger.error(
                "Amadeus hotel booking HTTP error",
                {"error": str(error), "attempt": attempt + 1},
                exc_info=True,
            )
            if attempt == max_retries - 1:
                raise Exception(f"Amadeus hotel booking failed: {str(error)}") from error
            # Retry on HTTP errors too
            continue

    # If we get here, all retries failed
    if last_error:
        raise last_error
    raise Exception("Amadeus hotel booking failed after all retries")

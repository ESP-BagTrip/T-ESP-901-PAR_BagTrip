"""Service to resolve weather for a trip destination.

Centralises the destination → coordinates → weather pipeline so both the
per-trip ``GET /{tripId}/weather`` endpoint and the aggregated home endpoint
(``GET /v1/home``) share one implementation instead of duplicating the
inline resolution that used to live in the route.
"""

from datetime import date, timedelta

from src.models.trip import Trip


class WeatherService:
    """Resolve current weather for a trip destination."""

    @staticmethod
    async def get_trip_weather(trip: Trip) -> dict | None:
        """Resolve weather for a trip's destination.

        Returns a dict with the weather summary fields, or ``None`` when the
        trip has no destination or the coordinates cannot be resolved (the
        caller treats a missing weather block as a soft, non-fatal state).
        """
        from src.agent.tools import get_weather, resolve_iata_code

        destination = trip.destination_name
        if not destination:
            return None

        location_data = await resolve_iata_code(destination)
        if "error" in location_data or "lat" not in location_data:
            return None

        lat = location_data["lat"]
        lon = location_data["lon"]

        today = date.today()
        start = max(trip.start_date, today) if trip.start_date else today
        end = (
            min(trip.end_date, today + timedelta(days=7))
            if trip.end_date
            else today + timedelta(days=7)
        )
        if end < start:
            end = start

        weather = await get_weather(lat, lon, start.isoformat(), end.isoformat())

        avg = float(weather.get("avg_temp_c", 20))
        return {
            "avg_temp_c": avg,
            "min_temp_c": float(weather.get("min_temp_c", avg)),
            "max_temp_c": float(weather.get("max_temp_c", avg)),
            "description": weather.get("description", "Unknown"),
            "rain_probability": weather.get("rain_probability", 0),
            "source": weather.get("source", "unknown"),
        }

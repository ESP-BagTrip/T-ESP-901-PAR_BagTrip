"""Open-Meteo integration — free, no API key, multilingual.

Two endpoints used:

- ``/v1/search`` (geocoding): resolves a city name in any language to
  coordinates, country, admin region. Critical for our IATA resolver
  cascade because ``airportsdata`` and Amadeus only index city names in
  English, so a French/Japanese/Arabic input would otherwise miss.

- ``/v1/forecast`` (weather): used by ``agent/tools/weather.py`` directly,
  not exposed here for backwards compatibility.
"""

from __future__ import annotations

from .geocoding import GeocodedPlace, search_places

__all__ = ["GeocodedPlace", "search_places"]

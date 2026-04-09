"""Offline aviation data service using airportsdata.

Replaces Amadeus /v1/reference-data/locations endpoints with local data.
"""

from __future__ import annotations

import math
from datetime import datetime

import airportsdata

from src.integrations.amadeus.types import (
    Location,
    LocationAddress,
    LocationGeoCode,
    LocationSelf,
)

# Continent ISO alpha-2 → region code mapping
_COUNTRY_TO_CONTINENT: dict[str, str] = {}
_CONTINENT_CODES = {
    "AF": "AF",  # Africa
    "AN": "AN",  # Antarctica
    "AS": "AS",  # Asia
    "EU": "EU",  # Europe
    "NA": "NA",  # North America
    "OC": "OC",  # Oceania
    "SA": "SA",  # South America
}

# Common country → full name mapping (top ~60 countries by air traffic)
_COUNTRY_NAMES: dict[str, str] = {
    "AF": "Afghanistan",
    "AL": "Albania",
    "DZ": "Algeria",
    "AR": "Argentina",
    "AU": "Australia",
    "AT": "Austria",
    "BE": "Belgium",
    "BR": "Brazil",
    "BG": "Bulgaria",
    "CA": "Canada",
    "CL": "Chile",
    "CN": "China",
    "CO": "Colombia",
    "HR": "Croatia",
    "CZ": "Czechia",
    "DK": "Denmark",
    "EG": "Egypt",
    "FI": "Finland",
    "FR": "France",
    "DE": "Germany",
    "GR": "Greece",
    "HK": "Hong Kong",
    "HU": "Hungary",
    "IN": "India",
    "ID": "Indonesia",
    "IE": "Ireland",
    "IL": "Israel",
    "IT": "Italy",
    "JP": "Japan",
    "KE": "Kenya",
    "KR": "South Korea",
    "MY": "Malaysia",
    "MX": "Mexico",
    "MA": "Morocco",
    "NL": "Netherlands",
    "NZ": "New Zealand",
    "NG": "Nigeria",
    "NO": "Norway",
    "PK": "Pakistan",
    "PE": "Peru",
    "PH": "Philippines",
    "PL": "Poland",
    "PT": "Portugal",
    "QA": "Qatar",
    "RO": "Romania",
    "RU": "Russia",
    "SA": "Saudi Arabia",
    "SG": "Singapore",
    "ZA": "South Africa",
    "ES": "Spain",
    "SE": "Sweden",
    "CH": "Switzerland",
    "TW": "Taiwan",
    "TH": "Thailand",
    "TR": "Turkey",
    "AE": "United Arab Emirates",
    "GB": "United Kingdom",
    "US": "United States",
    "VN": "Vietnam",
    "UA": "Ukraine",
    "RS": "Serbia",
    "CY": "Cyprus",
    "LU": "Luxembourg",
    "IS": "Iceland",
    "MT": "Malta",
    "EE": "Estonia",
    "LV": "Latvia",
    "LT": "Lithuania",
    "SK": "Slovakia",
    "SI": "Slovenia",
}

# Country code → continent code (built from airportsdata at init)
_COUNTRY_CONTINENT_MAP: dict[str, str] = {
    # Europe
    "AL": "EU",
    "AD": "EU",
    "AT": "EU",
    "BY": "EU",
    "BE": "EU",
    "BA": "EU",
    "BG": "EU",
    "HR": "EU",
    "CY": "EU",
    "CZ": "EU",
    "DK": "EU",
    "EE": "EU",
    "FI": "EU",
    "FR": "EU",
    "DE": "EU",
    "GR": "EU",
    "HU": "EU",
    "IS": "EU",
    "IE": "EU",
    "IT": "EU",
    "XK": "EU",
    "LV": "EU",
    "LI": "EU",
    "LT": "EU",
    "LU": "EU",
    "MT": "EU",
    "MD": "EU",
    "MC": "EU",
    "ME": "EU",
    "NL": "EU",
    "MK": "EU",
    "NO": "EU",
    "PL": "EU",
    "PT": "EU",
    "RO": "EU",
    "RU": "EU",
    "SM": "EU",
    "RS": "EU",
    "SK": "EU",
    "SI": "EU",
    "ES": "EU",
    "SE": "EU",
    "CH": "EU",
    "UA": "EU",
    "GB": "EU",
    "VA": "EU",
    # North America
    "AG": "NA",
    "BS": "NA",
    "BB": "NA",
    "BZ": "NA",
    "CA": "NA",
    "CR": "NA",
    "CU": "NA",
    "DM": "NA",
    "DO": "NA",
    "SV": "NA",
    "GD": "NA",
    "GT": "NA",
    "HT": "NA",
    "HN": "NA",
    "JM": "NA",
    "MX": "NA",
    "NI": "NA",
    "PA": "NA",
    "KN": "NA",
    "LC": "NA",
    "VC": "NA",
    "TT": "NA",
    "US": "NA",
    "PR": "NA",
    # South America
    "AR": "SA",
    "BO": "SA",
    "BR": "SA",
    "CL": "SA",
    "CO": "SA",
    "EC": "SA",
    "GY": "SA",
    "PY": "SA",
    "PE": "SA",
    "SR": "SA",
    "UY": "SA",
    "VE": "SA",
    # Asia
    "AE": "AS",
    "AM": "AS",
    "AZ": "AS",
    "BH": "AS",
    "BD": "AS",
    "BT": "AS",
    "BN": "AS",
    "KH": "AS",
    "CN": "AS",
    "GE": "AS",
    "HK": "AS",
    "IN": "AS",
    "ID": "AS",
    "IR": "AS",
    "IQ": "AS",
    "IL": "AS",
    "JP": "AS",
    "JO": "AS",
    "KZ": "AS",
    "KW": "AS",
    "KG": "AS",
    "LA": "AS",
    "LB": "AS",
    "MO": "AS",
    "MY": "AS",
    "MV": "AS",
    "MN": "AS",
    "MM": "AS",
    "NP": "AS",
    "KP": "AS",
    "KR": "AS",
    "OM": "AS",
    "PK": "AS",
    "PS": "AS",
    "PH": "AS",
    "QA": "AS",
    "SA": "AS",
    "SG": "AS",
    "LK": "AS",
    "SY": "AS",
    "TW": "AS",
    "TJ": "AS",
    "TH": "AS",
    "TL": "AS",
    "TR": "AS",
    "TM": "AS",
    "UZ": "AS",
    "VN": "AS",
    "YE": "AS",
    # Africa
    "DZ": "AF",
    "AO": "AF",
    "BJ": "AF",
    "BW": "AF",
    "BF": "AF",
    "BI": "AF",
    "CV": "AF",
    "CM": "AF",
    "CF": "AF",
    "TD": "AF",
    "KM": "AF",
    "CD": "AF",
    "CG": "AF",
    "CI": "AF",
    "DJ": "AF",
    "EG": "AF",
    "GQ": "AF",
    "ER": "AF",
    "SZ": "AF",
    "ET": "AF",
    "GA": "AF",
    "GM": "AF",
    "GH": "AF",
    "GN": "AF",
    "GW": "AF",
    "KE": "AF",
    "LS": "AF",
    "LR": "AF",
    "LY": "AF",
    "MG": "AF",
    "MW": "AF",
    "ML": "AF",
    "MR": "AF",
    "MU": "AF",
    "MA": "AF",
    "MZ": "AF",
    "NA": "AF",
    "NE": "AF",
    "NG": "AF",
    "RW": "AF",
    "ST": "AF",
    "SN": "AF",
    "SC": "AF",
    "SL": "AF",
    "SO": "AF",
    "ZA": "AF",
    "SS": "AF",
    "SD": "AF",
    "TZ": "AF",
    "TG": "AF",
    "TN": "AF",
    "UG": "AF",
    "ZM": "AF",
    "ZW": "AF",
    # Oceania
    "AU": "OC",
    "FJ": "OC",
    "KI": "OC",
    "MH": "OC",
    "FM": "OC",
    "NR": "OC",
    "NZ": "OC",
    "PW": "OC",
    "PG": "OC",
    "WS": "OC",
    "SB": "OC",
    "TO": "OC",
    "TV": "OC",
    "VU": "OC",
    "NC": "OC",
    "PF": "OC",
}

_EARTH_RADIUS_KM = 6371.0


def _haversine(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate the great-circle distance in km between two points."""
    lat1_r, lon1_r = math.radians(lat1), math.radians(lon1)
    lat2_r, lon2_r = math.radians(lat2), math.radians(lon2)
    dlat = lat2_r - lat1_r
    dlon = lon2_r - lon1_r
    a = math.sin(dlat / 2) ** 2 + math.cos(lat1_r) * math.cos(lat2_r) * math.sin(dlon / 2) ** 2
    return _EARTH_RADIUS_KM * 2 * math.asin(math.sqrt(a))


def _get_utc_offset(tz_name: str) -> str:
    """Get the current UTC offset string (e.g. '+02:00') for a timezone name."""
    try:
        from zoneinfo import ZoneInfo

        tz = ZoneInfo(tz_name)
        offset = datetime.now(tz=tz).utcoffset()
        if offset is None:
            return "+00:00"
        total_seconds = int(offset.total_seconds())
        sign = "+" if total_seconds >= 0 else "-"
        total_seconds = abs(total_seconds)
        hours, remainder = divmod(total_seconds, 3600)
        minutes = remainder // 60
        return f"{sign}{hours:02d}:{minutes:02d}"
    except Exception:
        return "+00:00"


class AviationDataService:
    """Offline airport/location lookup backed by airportsdata."""

    def __init__(self) -> None:
        self._airports: dict[str, dict] = airportsdata.load("IATA")

    def search_by_keyword(
        self, keyword: str, sub_type: str = "CITY,AIRPORT", limit: int = 10
    ) -> list[Location]:
        """Search airports by keyword (name, city, IATA code).

        Ranking (best first):
          0 — exact IATA match
          1 — exact city name match + "International" in name
          2 — exact city name match
          3 — IATA starts with keyword
          4 — city starts with keyword + "International"
          5 — city starts with keyword
          6 — name starts with keyword
          7 — keyword found in city or name
        """
        if not keyword or not keyword.strip():
            return []

        kw = keyword.strip().lower()
        sub_types = {s.strip().upper() for s in sub_type.split(",")}

        scored: list[tuple[int, str, dict]] = []

        for iata, data in self._airports.items():
            iata_lower = iata.lower()
            name_lower = data["name"].lower()
            city_lower = data["city"].lower()
            is_intl = "international" in name_lower

            if iata_lower == kw:
                scored.append((0, iata, data))
            elif city_lower == kw and is_intl:
                scored.append((1, iata, data))
            elif city_lower == kw:
                scored.append((2, iata, data))
            elif iata_lower.startswith(kw):
                scored.append((3, iata, data))
            elif city_lower.startswith(kw) and is_intl:
                scored.append((4, iata, data))
            elif city_lower.startswith(kw):
                scored.append((5, iata, data))
            elif name_lower.startswith(kw):
                scored.append((6, iata, data))
            elif kw in city_lower or kw in name_lower:
                scored.append((7, iata, data))

        scored.sort(key=lambda x: (x[0], x[1]))

        locations = []
        for _, iata, data in scored:
            if len(locations) >= limit:
                break
            loc = self._to_location(iata, data)
            if "AIRPORT" in sub_types or (
                "CITY" in sub_types and loc.address.cityName.lower().startswith(kw)
            ):
                locations.append(loc)

        return locations

    def get_by_id(self, iata_code: str) -> Location | None:
        """Lookup a single airport by IATA code. O(1)."""
        code = iata_code.strip().upper()
        data = self._airports.get(code)
        if data is None:
            return None
        return self._to_location(code, data)

    def search_nearest(self, latitude: float, longitude: float, limit: int = 10) -> list[Location]:
        """Find the nearest airports to a given coordinate (haversine)."""
        distances: list[tuple[float, str, dict]] = []

        for iata, data in self._airports.items():
            dist = _haversine(latitude, longitude, data["lat"], data["lon"])
            distances.append((dist, iata, data))

        distances.sort(key=lambda x: x[0])

        return [self._to_location(iata, data) for _, iata, data in distances[:limit]]

    def _to_location(self, iata_code: str, data: dict) -> Location:
        """Convert an airportsdata entry to the Amadeus-compatible Location model."""
        country_code = data.get("country", "")
        country_name = _COUNTRY_NAMES.get(country_code, country_code)
        region_code = _COUNTRY_CONTINENT_MAP.get(country_code, "")
        city = data.get("city", "")
        name = data.get("name", "")

        return Location(
            type="location",
            subType="AIRPORT",
            name=name,
            detailedName=f"{name}, {city}" if city else name,
            id=iata_code,
            self_=LocationSelf(
                href=f"/v1/travel/locations/{iata_code}",
                methods=["GET"],
            ),
            timeZoneOffset=_get_utc_offset(data.get("tz", "")),
            iataCode=iata_code,
            geoCode=LocationGeoCode(
                latitude=data.get("lat", 0.0),
                longitude=data.get("lon", 0.0),
            ),
            address=LocationAddress(
                cityName=city,
                cityCode=iata_code,
                countryName=country_name,
                countryCode=country_code,
                regionCode=region_code,
            ),
            analytics=None,
        )


aviation_data_service = AviationDataService()

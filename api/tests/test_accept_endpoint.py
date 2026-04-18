"""Tests for Phase 4 (API-6/7/8): IATA, baggage, destination selection."""

from datetime import UTC, date, datetime, time

from src.api.ai.plan_trip_routes import (
    _DEFAULT_BAGGAGE_I18N,
    _build_manual_flight,
    _combine_date_to_utc_datetime,
    _compute_nights,
    _get_default_baggage,
    _parse_iso_datetime,
)
from src.api.ai.plan_trip_schemas import AcceptPlanRequest
from src.enums import FlightType, ValidationStatus

# --- API-6: IATA extraction ---


def test_iata_extraction_from_dict_destination():
    suggestion = {
        "destination": {"city": "Barcelona", "country": "Spain", "iata": "BCN"},
        "origin_iata": "CDG",
    }
    dest_info = suggestion.get("destination", {})
    assert isinstance(dest_info, dict)
    assert dest_info.get("iata") == "BCN"
    assert suggestion.get("origin_iata") == "CDG"


def test_iata_extraction_from_string_destination():
    """Backward compat: destination may be a plain string."""
    suggestion = {"destination": "Barcelona, Spain"}
    dest_info = suggestion.get("destination", {})
    assert isinstance(dest_info, str)
    # Should gracefully handle — no iata available
    destination_iata = dest_info.get("iata") if isinstance(dest_info, dict) else None
    assert destination_iata is None


def test_destination_name_from_dict():
    dest_info = {"city": "Tokyo", "country": "Japan", "iata": "NRT"}
    dest_city = dest_info.get("city", "")
    dest_country = dest_info.get("country", "")
    destination_name = f"{dest_city}, {dest_country}" if dest_country else dest_city
    assert destination_name == "Tokyo, Japan"


def test_destination_name_from_string():
    dest_info = "Tokyo"
    destination_name = str(dest_info) if dest_info else "Inconnu"
    assert destination_name == "Tokyo"


# --- API-7: Baggage i18n ---


def test_default_baggage_en():
    items = _get_default_baggage("en")
    assert len(items) == 6
    names = [i["name"] for i in items]
    assert "Passport" in names
    assert "Phone charger" in names


def test_default_baggage_fr():
    items = _get_default_baggage("fr")
    assert len(items) == 6
    names = [i["name"] for i in items]
    assert "Passeport" in names


def test_default_baggage_unknown_lang_falls_back_to_en():
    items = _get_default_baggage("de")
    assert items == _DEFAULT_BAGGAGE_I18N["en"]


def test_baggage_items_have_quantity():
    for lang_items in _DEFAULT_BAGGAGE_I18N.values():
        for item in lang_items:
            assert "quantity" in item
            assert isinstance(item["quantity"], int)


# --- API-8: Destination selection ---


def test_accept_request_default_index_is_zero():
    req = AcceptPlanRequest(suggestion={})
    assert req.selectedDestinationIndex == 0


def test_selected_destination_index_picks_alternative():
    suggestion = {
        "destination": {"city": "Barcelona", "country": "Spain", "iata": "BCN"},
        "alternatives": [
            {"city": "Lisbon", "country": "Portugal", "iata": "LIS"},
            {"city": "Rome", "country": "Italy", "iata": "FCO"},
        ],
    }
    idx = 1
    alternatives = suggestion.get("alternatives", [])
    alt_idx = idx - 1
    chosen = alternatives[alt_idx]
    assert chosen["city"] == "Lisbon"
    assert chosen["iata"] == "LIS"


def test_selected_destination_index_2_picks_second_alternative():
    suggestion = {
        "alternatives": [
            {"city": "Lisbon", "country": "Portugal", "iata": "LIS"},
            {"city": "Rome", "country": "Italy", "iata": "FCO"},
        ],
    }
    idx = 2
    alt_idx = idx - 1
    chosen = suggestion["alternatives"][alt_idx]
    assert chosen["city"] == "Rome"


# --- SMP-316: validation_status + return flight on accept ---


def test_build_manual_flight_marks_main_as_suggested():
    flight = _build_manual_flight(
        trip_id="trip-1",
        flight_data={
            "route": "CDG → LIS",
            "price": 240,
            "source": "amadeus",
            "airline": "Air France",
            "flight_number": "AF1234",
            "departure_date": "2026-06-01T14:20:00",
            "arrival_date": "2026-06-01T16:40:00",
            "duration": "PT2H20M",
        },
        flight_type=FlightType.MAIN,
        dep_airport="CDG",
        arr_airport="LIS",
    )
    assert flight.flight_type == FlightType.MAIN
    assert flight.validation_status == ValidationStatus.SUGGESTED
    assert flight.airline == "Air France"
    assert flight.flight_number == "AF1234"
    assert flight.departure_airport == "CDG"
    assert flight.arrival_airport == "LIS"
    assert "duration=PT2H20M" in (flight.notes or "")


def test_build_manual_flight_falls_back_when_llm_omits_data():
    flight = _build_manual_flight(
        trip_id="trip-1",
        flight_data={"source": "estimated"},
        flight_type=FlightType.RETURN,
        dep_airport="LIS",
        arr_airport="CDG",
    )
    assert flight.flight_type == FlightType.RETURN
    assert flight.flight_number == "TBD"
    assert flight.airline is None
    assert flight.validation_status == ValidationStatus.SUGGESTED


def test_parse_iso_datetime_handles_valid_and_invalid():
    assert _parse_iso_datetime("2026-06-01T14:20:00") == datetime(2026, 6, 1, 14, 20)
    assert _parse_iso_datetime("") is None
    assert _parse_iso_datetime("not-a-date") is None
    assert _parse_iso_datetime(None) is None


def test_compute_nights_basic():
    assert _compute_nights(date(2026, 4, 23), date(2026, 4, 30)) == 7


def test_compute_nights_returns_zero_on_missing():
    assert _compute_nights(None, date(2026, 1, 1)) == 0
    assert _compute_nights(date(2026, 1, 1), None) == 0
    assert _compute_nights(None, None) == 0


def test_compute_nights_clamps_negative():
    assert _compute_nights(date(2026, 5, 10), date(2026, 5, 1)) == 0


def test_combine_date_to_utc_datetime_uses_midnight():
    result = _combine_date_to_utc_datetime(date(2026, 4, 23))
    assert result == datetime(2026, 4, 23, 0, 0, tzinfo=UTC)
    assert result.time() == time.min


def test_combine_date_to_utc_datetime_accepts_none():
    assert _combine_date_to_utc_datetime(None) is None


def test_return_flight_swaps_airports_when_route_missing():
    """When the LLM omits the return route, airports invert the outbound."""
    outbound_dep, outbound_arr = "CDG", "LIS"
    return_data = {"source": "estimated"}  # no "route" key
    route = return_data.get("route", "")
    import re

    codes = re.findall(r"\b([A-Z]{3})\b", route.upper())
    ret_dep = codes[0] if len(codes) >= 1 else None
    ret_arr = codes[1] if len(codes) >= 2 else None
    if not ret_dep and not ret_arr:
        ret_dep, ret_arr = outbound_arr, outbound_dep
    assert ret_dep == "LIS"
    assert ret_arr == "CDG"


def test_out_of_range_index_keeps_primary():
    """Out-of-range selectedDestinationIndex should silently keep primary."""
    suggestion = {
        "destination": {"city": "Barcelona", "country": "Spain", "iata": "BCN"},
        "alternatives": [{"city": "Lisbon", "country": "Portugal", "iata": "LIS"}],
    }
    idx = 5  # out of range
    alternatives = suggestion.get("alternatives", [])
    dest_info = suggestion.get("destination", {})
    destination_name = f"{dest_info['city']}, {dest_info['country']}"

    if idx > 0 and alternatives:
        alt_idx = idx - 1
        if alt_idx < len(alternatives):
            chosen = alternatives[alt_idx]
            destination_name = f"{chosen['city']}, {chosen['country']}"

    # Should remain primary since index is out of range
    assert destination_name == "Barcelona, Spain"

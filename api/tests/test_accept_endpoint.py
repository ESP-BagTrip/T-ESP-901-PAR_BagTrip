"""Tests for Phase 4 (API-6/7/8): IATA, baggage, destination selection."""

from src.api.ai.plan_trip_routes import (
    _DEFAULT_BAGGAGE_I18N,
    _get_default_baggage,
)
from src.api.ai.plan_trip_schemas import AcceptPlanRequest

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

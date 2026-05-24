"""Unit tests for the i18n notification catalogue."""

from __future__ import annotations

from src.services.notification_messages import (
    _MESSAGES,
    _SUPPORTED,
    activity_location_suffix,
    baggage_status,
    flight_gate_suffix,
    flight_ticket_suffix,
    normalize_locale,
    render_notification,
    untitled_trip,
)


class TestCatalogueCoverage:
    """Every notification key must be translated in every supported locale —
    a missing FR entry silently falls back to EN in front of the user."""

    def test_all_keys_cover_all_supported_locales(self):
        for key, translations in _MESSAGES.items():
            for locale in _SUPPORTED:
                assert translations.get(locale), f"{key} missing non-empty '{locale}'"


class TestNormalizeLocale:
    def test_passthrough_supported(self):
        assert normalize_locale("fr") == "fr"
        assert normalize_locale("en") == "en"

    def test_strips_region(self):
        assert normalize_locale("fr-FR") == "fr"
        assert normalize_locale("en_US") == "en"
        assert normalize_locale("FR") == "fr"

    def test_unknown_falls_back_to_en(self):
        assert normalize_locale("de") == "en"
        assert normalize_locale("") == "en"
        assert normalize_locale(None) == "en"

    def test_non_string_falls_back_to_en(self):
        assert normalize_locale(object()) == "en"  # type: ignore[arg-type]


class TestRenderNotification:
    def test_french_render(self):
        title, body = render_notification("TRIP_STARTED", "fr", trip_title="Rome")
        assert title == "Bon voyage !"
        assert "Rome" in body
        assert "commence" in body

    def test_english_render(self):
        title, body = render_notification("TRIP_STARTED", "en", trip_title="Rome")
        assert title == "Have a great trip!"
        assert "Rome" in body

    def test_unknown_locale_falls_back_to_english(self):
        title, _ = render_notification("TRIP_ENDED", "de", trip_title="Rome")
        assert title == "Trip complete!"

    def test_unknown_key_returns_key_as_text(self):
        title, body = render_notification("DOES_NOT_EXIST", "fr")
        assert title == "DOES_NOT_EXIST.title"
        assert body == "DOES_NOT_EXIST.body"

    def test_missing_context_key_returns_raw_template(self):
        # No KeyError must escape — render is called from background jobs.
        title, body = render_notification("TRIP_STARTED", "fr")
        assert title == "Bon voyage !"
        assert "{trip_title}" in body

    def test_budget_alert_variants_differ(self):
        warn_title, _ = render_notification(
            "BUDGET_ALERT_WARNING", "fr", pct="80", trip_title="Rome"
        )
        exceeded_title, exceeded_body = render_notification(
            "BUDGET_ALERT_EXCEEDED", "fr", pct="120", trip_title="Rome"
        )
        assert warn_title == "Alerte budget"
        assert exceeded_title == "Budget dépassé !"
        assert "120%" in exceeded_body


class TestFragments:
    def test_untitled_trip(self):
        assert untitled_trip("fr") == "sans titre"
        assert untitled_trip("en") == "untitled"

    def test_baggage_status_with_items(self):
        assert baggage_status("fr", packed=2, total=5) == "Bagages : 2/5 préparés."
        assert baggage_status("en", packed=2, total=5) == "Bags: 2/5 packed."

    def test_baggage_status_empty(self):
        assert baggage_status("fr", packed=0, total=0) == "Pensez à préparer vos bagages !"
        assert baggage_status("en", packed=0, total=0) == "Time to pack your bags!"

    def test_flight_ticket_suffix(self):
        assert flight_ticket_suffix("fr", "http://x") == " Billet : http://x"
        assert flight_ticket_suffix("en", "http://x") == " Ticket: http://x"

    def test_flight_gate_suffix(self):
        assert flight_gate_suffix("fr", "Terminal 2") == " (Terminal 2)"

    def test_activity_location_suffix(self):
        assert activity_location_suffix("fr", "Louvre") == " à Louvre"
        assert activity_location_suffix("en", "Louvre") == " at Louvre"

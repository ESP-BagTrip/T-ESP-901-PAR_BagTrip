"""Unit tests for the Jinja2 prompt registry.

Covers:
- Every EN template loads and renders a non-empty string
- FR locale renders through the `{% include "en/..." %}` scaffolding
- Unknown locale falls back to EN
- Unknown template name raises `ValueError`
- Legacy module-level constants are non-empty after import
"""

from __future__ import annotations

import pytest

from src.agent.prompts import (
    ACCOMMODATION_PROMPT,
    ACCOMMODATION_SUGGEST_PROMPT,
    ACTIVITY_PLANNER_PROMPT,
    BAGGAGE_PROMPT,
    BUDGET_PROMPT,
    DESTINATION_RESEARCH_PROMPT,
    render,
)

_ALL_TEMPLATE_NAMES = [
    "destination_research",
    "activity_planner",
    "accommodation",
    "accommodation_suggest",
    "baggage",
    "budget",
]


class TestRenderEnglish:
    @pytest.mark.parametrize("name", _ALL_TEMPLATE_NAMES)
    def test_each_template_renders_non_empty(self, name):
        out = render(name, locale="en")
        assert isinstance(out, str)
        assert len(out) > 50
        # Must contain JSON example — the prompts all describe a JSON schema.
        assert "{" in out and "}" in out

    def test_destination_research_mentions_iata(self):
        assert "IATA" in render("destination_research")

    def test_activity_planner_mentions_time_of_day(self):
        assert "time_of_day" in render("activity_planner")

    def test_budget_mentions_flights(self):
        assert "flights" in render("budget").lower()


class TestRenderFrench:
    @pytest.mark.parametrize("name", _ALL_TEMPLATE_NAMES)
    def test_fr_template_is_not_empty(self, name):
        # FR stubs include EN via Jinja `{% include %}`. They render non-empty
        # and the body matches the EN prompt.
        fr = render(name, locale="fr")
        en = render(name, locale="en")
        assert len(fr) >= len(en) - 5  # may differ by a few bytes of whitespace
        # Core markers from the EN prompt must survive the include
        assert "{" in fr and "}" in fr


class TestFallback:
    def test_unknown_locale_falls_back_to_en(self):
        fallback = render("destination_research", locale="xx")
        en = render("destination_research", locale="en")
        assert fallback == en

    def test_unknown_template_raises(self):
        with pytest.raises(ValueError, match="No prompt template found"):
            render("does_not_exist", locale="en")


class TestLegacyConstants:
    @pytest.mark.parametrize(
        "constant",
        [
            DESTINATION_RESEARCH_PROMPT,
            ACTIVITY_PLANNER_PROMPT,
            ACCOMMODATION_PROMPT,
            ACCOMMODATION_SUGGEST_PROMPT,
            BAGGAGE_PROMPT,
            BUDGET_PROMPT,
        ],
    )
    def test_legacy_constant_is_populated(self, constant):
        """Backward-compat: the module-level constants still resolve to a string."""
        assert isinstance(constant, str)
        assert len(constant) > 50

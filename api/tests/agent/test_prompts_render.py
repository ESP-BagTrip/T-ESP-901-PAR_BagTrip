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

from src.agent.prompts import render

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
    def test_fr_template_renders_non_empty(self, name):
        fr = render(name, locale="fr")
        assert isinstance(fr, str)
        assert len(fr) > 50
        # Must contain JSON schema example
        assert "{" in fr and "}" in fr

    @pytest.mark.parametrize("name", _ALL_TEMPLATE_NAMES)
    def test_fr_template_is_in_french(self, name):
        fr = render(name, locale="fr")
        # All FR templates must contain French text, not just redirect to EN
        french_markers = ["français", "doit", "réponse", "objet JSON", "utilise"]
        assert any(marker in fr.lower() for marker in french_markers), (
            f"FR template {name!r} does not appear to be in French"
        )

    @pytest.mark.parametrize("name", _ALL_TEMPLATE_NAMES)
    def test_fr_template_differs_from_en(self, name):
        fr = render(name, locale="fr")
        en = render(name, locale="en")
        assert fr != en, f"FR template {name!r} is identical to EN — needs translation"


class TestFallback:
    def test_unknown_locale_falls_back_to_en(self):
        fallback = render("destination_research", locale="xx")
        en = render("destination_research", locale="en")
        assert fallback == en

    def test_unknown_template_raises(self):
        with pytest.raises(ValueError, match="No prompt template found"):
            render("does_not_exist", locale="en")


class TestLegacyConstantsRemoved:
    """Sprint 4 removed the pre-rendered module-level constants.

    All callers migrated to `render(name, locale=...)`. This test pins the
    deprecation so no one accidentally re-adds them.
    """

    @pytest.mark.parametrize(
        "name",
        [
            "DESTINATION_RESEARCH_PROMPT",
            "ACTIVITY_PLANNER_PROMPT",
            "ACCOMMODATION_PROMPT",
            "ACCOMMODATION_SUGGEST_PROMPT",
            "BAGGAGE_PROMPT",
            "BUDGET_PROMPT",
        ],
    )
    def test_legacy_constant_is_gone(self, name):
        import src.agent.prompts as prompts_module

        assert not hasattr(prompts_module, name), (
            f"{name} is a legacy constant that Sprint 4 removed. "
            "Use `render(name, locale=...)` instead."
        )

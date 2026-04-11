"""Jinja2-backed prompt registry with EN/FR localization scaffolding.

Before Sprint 3, `src/agent/prompts.py` held 6 plain Python string constants,
all in English, all with no placeholders — even though other parts of the
backend (baggage fallback in `plan_trip_routes`) already localized strings
via `{"en": [...], "fr": [...]}`. This package puts the agent prompts on the
same track:

- Templates live under `templates/{locale}/{name}.j2`.
- `render(name, locale, **ctx)` looks up the template in the requested locale
  with an automatic fallback to English so missing translations never crash
  the graph — they just keep using the English baseline.
- `StrictUndefined` is enabled, so any missing template variable raises at
  render time instead of silently emitting a broken prompt.

Backward compatibility
----------------------
Callers that used to `from src.agent.prompts import DESTINATION_RESEARCH_PROMPT`
still work: the module exports the six legacy constants pre-rendered at
import time in the default locale (English). Nodes that want per-request
localization should call `render("destination_research", state.get("locale"))`.

Adding a new language
---------------------
1. Copy every file under `templates/en/` into `templates/fr/` (or any new
   locale code).
2. Translate freely — the render loader will pick the matching file.
3. Until a file is translated, the fallback resolver serves the English
   version so the agent keeps working.
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

from jinja2 import Environment, FileSystemLoader, StrictUndefined, TemplateNotFound

from src.utils.logger import logger

_TEMPLATE_ROOT = Path(__file__).parent / "templates"
_DEFAULT_LOCALE = "en"

# Bandit B701: autoescape=False is a deliberate choice here — the templates
# produce LLM prompts that contain raw JSON schema blocks (`{"a": 1}`). HTML
# escaping would turn `{` into `&#123;` and break the LLM's ability to parse
# the schema. There is no XSS surface: the rendered output is piped directly
# into `LLMService.acall_llm_messages`, never served to a browser.
_env = Environment(  # nosec B701
    loader=FileSystemLoader(_TEMPLATE_ROOT),
    autoescape=False,
    undefined=StrictUndefined,
    keep_trailing_newline=True,
)


def render(name: str, locale: str = _DEFAULT_LOCALE, **ctx: Any) -> str:
    """Render `templates/{locale}/{name}.j2` with `ctx`, falling back to English.

    Args:
        name: Template stem (no extension, no locale prefix). Examples:
            ``"destination_research"``, ``"activity_planner"``, ``"budget"``.
        locale: Locale code (``"en"``, ``"fr"``, ...). If the locale doesn't
            have a matching template, the English version is used.
        **ctx: Variables forwarded to Jinja. `StrictUndefined` means any
            missing variable raises at render time — this is a deliberate
            trade-off: a crash is louder than a silently-broken prompt.

    Returns:
        The rendered prompt string.

    Raises:
        ValueError: If neither the requested locale nor the English fallback
            has a template with that name (= typo in the caller).
    """
    candidates = [f"{locale}/{name}.j2"]
    if locale != _DEFAULT_LOCALE:
        candidates.append(f"{_DEFAULT_LOCALE}/{name}.j2")

    last_error: TemplateNotFound | None = None
    for candidate in candidates:
        try:
            template = _env.get_template(candidate)
            return template.render(**ctx)
        except TemplateNotFound as exc:
            last_error = exc
            continue

    if last_error is not None:
        logger.error(
            "agent.prompts: no template found",
            {"name": name, "locale": locale, "searched": candidates},
        )
    raise ValueError(
        f"No prompt template found for name={name!r} locale={locale!r} (searched: {candidates})",
    )


# ---------------------------------------------------------------------------
# Backward-compat: the legacy constants some nodes still import by name.
# These are frozen at import time in the default locale. Nodes that want to
# honour a per-request locale should migrate to `render(name, locale, ...)`.
# ---------------------------------------------------------------------------

DESTINATION_RESEARCH_PROMPT = render("destination_research")
ACTIVITY_PLANNER_PROMPT = render("activity_planner")
ACCOMMODATION_PROMPT = render("accommodation")
ACCOMMODATION_SUGGEST_PROMPT = render("accommodation_suggest")
BAGGAGE_PROMPT = render("baggage")
BUDGET_PROMPT = render("budget")


__all__ = [
    "ACCOMMODATION_PROMPT",
    "ACCOMMODATION_SUGGEST_PROMPT",
    "ACTIVITY_PLANNER_PROMPT",
    "BAGGAGE_PROMPT",
    "BUDGET_PROMPT",
    "DESTINATION_RESEARCH_PROMPT",
    "render",
]

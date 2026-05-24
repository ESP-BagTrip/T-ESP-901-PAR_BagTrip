"""Locale helpers used by routes and services.

The frontend passes the user's UI language either as a `locale` field in the
JSON body (SSE plan-trip) or as an `Accept-Language` header (REST routes).
Both shapes need to be coerced to a 2-letter code that `agent/prompts.render`
can use to pick a Jinja template under `templates/{locale}/`.
"""

from __future__ import annotations

SUPPORTED_LOCALES: frozenset[str] = frozenset({"en", "fr"})
DEFAULT_LOCALE = "en"


def normalize_locale(value: str | None, *, default: str = DEFAULT_LOCALE) -> str:
    """Coerce a header / state value to a supported 2-letter locale.

    Accepts ``"fr"``, ``"fr-FR"``, ``"fr_FR"``, ``"fr-FR,en;q=0.8"`` (full
    Accept-Language), or ``None``. Returns the requested code when supported,
    otherwise `default`.
    """
    if not value:
        return default
    primary = value.split(",", 1)[0].strip().replace("_", "-").lower()
    code = primary.split("-", 1)[0]
    return code if code in SUPPORTED_LOCALES else default

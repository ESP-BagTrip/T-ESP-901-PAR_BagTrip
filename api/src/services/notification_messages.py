"""Catalogue i18n des notifications push.

Source unique des libellés de notifications. Les jobs et services ne
construisent plus de strings : ils appellent ``render_notification`` (ou un
helper de fragment) avec une ``locale`` résolue depuis le device token du
destinataire. Fallback automatique vers l'anglais si la locale est inconnue
ou si une traduction manque.
"""

from __future__ import annotations

_SUPPORTED = ("fr", "en")
_DEFAULT = "en"

# Chaque clé suit la forme ``<KEY>.title`` / ``<KEY>.body`` pour les
# notifications, ``fragment.<name>`` pour les bouts de phrase optionnels.
_MESSAGES: dict[str, dict[str, str]] = {
    # ── Departure reminder (J-1) ────────────────────────────────────
    "DEPARTURE_REMINDER.title": {
        "fr": "Départ demain !",
        "en": "Departure tomorrow!",
    },
    "DEPARTURE_REMINDER.body": {
        "fr": "Votre voyage « {trip_title} » commence demain. {baggage_status}",
        "en": 'Your trip "{trip_title}" starts tomorrow. {baggage_status}',
    },
    # ── Flight alerts ───────────────────────────────────────────────
    "FLIGHT_H4.title": {"fr": "Vol dans ~4h", "en": "Flight in ~4h"},
    "FLIGHT_H4.body": {
        "fr": "Votre vol pour « {trip_title} » décolle bientôt !{ticket_suffix}",
        "en": 'Your flight for "{trip_title}" takes off soon!{ticket_suffix}',
    },
    "FLIGHT_H1.title": {"fr": "Vol dans ~1h", "en": "Flight in ~1h"},
    "FLIGHT_H1.body": {
        "fr": "Votre vol pour « {trip_title} » décolle bientôt !{gate_suffix}",
        "en": 'Your flight for "{trip_title}" takes off soon!{gate_suffix}',
    },
    # ── Morning summary ─────────────────────────────────────────────
    "MORNING_SUMMARY.title": {
        "fr": "Programme du jour — {trip_title}",
        "en": "Today's plan — {trip_title}",
    },
    "MORNING_SUMMARY.body": {
        "fr": "{count} activité(s) prévue(s) : {activity_names}",
        "en": "{count} activity/ies planned: {activity_names}",
    },
    # ── Activity reminder (~1h) ─────────────────────────────────────
    "ACTIVITY_H1.title": {"fr": "Activité dans ~1h", "en": "Activity in ~1h"},
    "ACTIVITY_H1.body": {
        "fr": "« {activity_title} » commence bientôt !{location_suffix}",
        "en": '"{activity_title}" starts soon!{location_suffix}',
    },
    # ── Budget alerts ───────────────────────────────────────────────
    "BUDGET_ALERT_WARNING.title": {"fr": "Alerte budget", "en": "Budget alert"},
    "BUDGET_ALERT_WARNING.body": {
        "fr": "Vous avez utilisé {pct}% du budget pour « {trip_title} ».",
        "en": 'You\'ve used {pct}% of the budget for "{trip_title}".',
    },
    "BUDGET_ALERT_EXCEEDED.title": {"fr": "Budget dépassé !", "en": "Budget exceeded!"},
    "BUDGET_ALERT_EXCEEDED.body": {
        "fr": "Vous avez utilisé {pct}% du budget pour « {trip_title} ».",
        "en": 'You\'ve used {pct}% of the budget for "{trip_title}".',
    },
    # ── Trip lifecycle ──────────────────────────────────────────────
    "TRIP_STARTED.title": {"fr": "Bon voyage !", "en": "Have a great trip!"},
    "TRIP_STARTED.body": {
        "fr": "Votre voyage « {trip_title} » commence aujourd'hui !",
        "en": 'Your trip "{trip_title}" starts today!',
    },
    "TRIP_ENDED.title": {"fr": "Voyage terminé !", "en": "Trip complete!"},
    "TRIP_ENDED.body": {
        "fr": "Votre voyage « {trip_title} » est terminé. Partagez votre avis !",
        "en": 'Your trip "{trip_title}" is over. Share your feedback!',
    },
    # ── Trip shared ─────────────────────────────────────────────────
    "TRIP_SHARED.title": {
        "fr": "Nouveau voyage partagé !",
        "en": "A trip was shared with you!",
    },
    "TRIP_SHARED.body": {
        "fr": "{inviter} vous a invité à « {trip_title} »",
        "en": '{inviter} invited you to "{trip_title}"',
    },
    "TRIP_SHARED_WITH_MESSAGE.title": {
        "fr": "Nouveau voyage partagé !",
        "en": "A trip was shared with you!",
    },
    "TRIP_SHARED_WITH_MESSAGE.body": {
        "fr": "{inviter} vous a invité : {message}",
        "en": "{inviter} invited you: {message}",
    },
    # ── Fragments (bouts de phrase composables) ─────────────────────
    "fragment.untitled_trip": {"fr": "sans titre", "en": "untitled"},
    "fragment.baggage_count": {
        "fr": "Bagages : {packed}/{total} préparés.",
        "en": "Bags: {packed}/{total} packed.",
    },
    "fragment.baggage_empty": {
        "fr": "Pensez à préparer vos bagages !",
        "en": "Time to pack your bags!",
    },
    "fragment.flight_ticket": {
        "fr": " Billet : {url}",
        "en": " Ticket: {url}",
    },
    "fragment.flight_gate": {"fr": " ({gate})", "en": " ({gate})"},
    "fragment.activity_location": {
        "fr": " à {location}",
        "en": " at {location}",
    },
}


def normalize_locale(locale: str | None) -> str:
    """Réduit une locale arbitraire (``fr-FR``, ``en_US``…) à ``fr``/``en``."""
    if not locale or not isinstance(locale, str):
        return _DEFAULT
    lang = locale.replace("-", "_").split("_")[0].strip().lower()
    return lang if lang in _SUPPORTED else _DEFAULT


def _text(key: str, locale: str | None, **ctx: object) -> str:
    """Rend une clé du catalogue ; fallback EN puis clé brute."""
    table = _MESSAGES.get(key)
    if not table:
        return key
    lang = normalize_locale(locale)
    template = table.get(lang) or table.get(_DEFAULT) or key
    if not ctx:
        return template
    try:
        return template.format(**ctx)
    except (KeyError, IndexError, ValueError):
        return template


def render_notification(key: str, locale: str | None, **ctx: object) -> tuple[str, str]:
    """Retourne ``(title, body)`` localisés pour une notification."""
    return _text(f"{key}.title", locale, **ctx), _text(f"{key}.body", locale, **ctx)


# ── Helpers de fragments ───────────────────────────────────────────


def untitled_trip(locale: str | None) -> str:
    """Libellé de repli pour un voyage sans titre."""
    return _text("fragment.untitled_trip", locale)


def baggage_status(locale: str | None, packed: int, total: int) -> str:
    """Phrase d'état des bagages pour le rappel de départ."""
    if total > 0:
        return _text("fragment.baggage_count", locale, packed=packed, total=total)
    return _text("fragment.baggage_empty", locale)


def flight_ticket_suffix(locale: str | None, url: str) -> str:
    """Suffixe optionnel « Billet : … » du rappel de vol H-4."""
    return _text("fragment.flight_ticket", locale, url=url)


def flight_gate_suffix(locale: str | None, gate: str) -> str:
    """Suffixe optionnel « (Terminal …) » du rappel de vol H-1."""
    return _text("fragment.flight_gate", locale, gate=gate)


def activity_location_suffix(locale: str | None, location: str) -> str:
    """Suffixe optionnel « à <lieu> » du rappel d'activité."""
    return _text("fragment.activity_location", locale, location=location)

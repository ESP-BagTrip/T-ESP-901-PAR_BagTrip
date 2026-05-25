"""Shared HTTP knobs for Wikimedia/OSM providers (SMP-330).

Wikimedia's API etiquette mandates a descriptive User-Agent with a contact
URL (https://meta.wikimedia.org/wiki/User-Agent_policy). Anonymous requests
get throttled or blocked at the edge. OpenStreetMap tile servers have an
even stricter policy. Centralising the header here means every cover-image
provider stays compliant without each call site reinventing the string.
"""

from __future__ import annotations

USER_AGENT = "BagTrip/1.0 (https://bagtrip.fr; contact@bagtrip.fr)"

WIKIMEDIA_HEADERS: dict[str, str] = {
    "User-Agent": USER_AGENT,
    "Accept": "application/json",
    "Api-User-Agent": USER_AGENT,
}

OSM_HEADERS: dict[str, str] = {"User-Agent": USER_AGENT}

# Generous-but-bounded: Wikipedia/Commons p95 is < 500ms but transient
# 5xx can stretch to a few seconds. Anything over 8s and we'd rather
# move on to the next provider than block the trip creation flow.
DEFAULT_TIMEOUT_S = 8.0

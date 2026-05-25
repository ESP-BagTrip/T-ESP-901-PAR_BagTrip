"""LLM-based cover-image ranker (SMP-330).

When the orchestrator collects multiple candidates (Wikipedia lead +
Wikidata P18 + N Commons photos), their natural order is "highest signal
provider first" — fine, but it ignores semantic fit. A user planning a
beach trip to Bali deserves the beach photo, not the temple shot
Wikipedia happens to lead with.

We give the LLM the destination name and the candidate captions/titles
and ask it for an ordering. The LLM never sees pixels — picking by
caption alone works because Commons file names are descriptive
("Shibuya crossing at night.jpg") and Wikipedia titles too. If the LLM
call fails for any reason we fall back to the input order — never block
trip creation on a ranker that's a nice-to-have.
"""

from __future__ import annotations

import json
from typing import Any

from src.integrations.cover_image.types import CoverCandidate
from src.services.llm_router import LLMRouter
from src.utils.logger import logger

_SYSTEM_PROMPT = (
    "You rank candidate cover images for a travel app. You receive a "
    "destination name and a numbered list of image captions. Pick the "
    "best ordering for a destination hero — favour iconic, landscape "
    "framing, daylight, recognisably tied to the place. Reply ONLY with "
    'JSON of the shape {"ranking": [<int>, ...]} where the integers are '
    "the 0-based caption indices in your preferred order. Every input "
    "index must appear exactly once."
)


def _build_user_message(destination: str, candidates: list[CoverCandidate]) -> str:
    lines = [f"Destination: {destination}", "", "Candidates:"]
    for i, c in enumerate(candidates):
        caption = c.title or c.url
        lines.append(f"{i}. [{c.source}] {caption}")
    return "\n".join(lines)


def _parse_ranking(payload: dict[str, Any], n: int) -> list[int] | None:
    """Validate the LLM response and return a valid permutation of [0..n-1]."""
    choices = payload.get("choices") or []
    if not choices:
        return None
    content = (choices[0].get("message") or {}).get("content")
    if not isinstance(content, str):
        return None
    try:
        parsed = json.loads(content)
    except json.JSONDecodeError:
        return None
    ranking = parsed.get("ranking")
    if not isinstance(ranking, list) or len(ranking) != n:
        return None
    seen: set[int] = set()
    out: list[int] = []
    for idx in ranking:
        if not isinstance(idx, int) or idx < 0 or idx >= n or idx in seen:
            return None
        seen.add(idx)
        out.append(idx)
    return out


async def rank_candidates(
    destination: str,
    candidates: list[CoverCandidate],
) -> list[CoverCandidate]:
    """Return ``candidates`` reordered by the LLM, or unchanged on failure."""
    if len(candidates) < 2:
        return candidates
    try:
        router = LLMRouter.get()
        response = await router.chat_completion(
            messages=[
                {"role": "system", "content": _SYSTEM_PROMPT},
                {"role": "user", "content": _build_user_message(destination, candidates)},
            ],
            response_format={"type": "json_object"},
            temperature=0.2,
            max_tokens=120,
        )
    except Exception as exc:
        # Ranker is a nice-to-have; never propagate.
        logger.warn(f"Cover scorer LLM call failed for '{destination}': {exc}")
        return candidates

    ordering = _parse_ranking(response, len(candidates))
    if ordering is None:
        logger.warn(f"Cover scorer produced an invalid ranking for '{destination}'")
        return candidates
    return [candidates[i] for i in ordering]

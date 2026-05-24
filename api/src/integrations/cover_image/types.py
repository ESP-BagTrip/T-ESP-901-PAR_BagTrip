"""Shared cover-image data types (SMP-330)."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Literal

CoverSource = Literal[
    "wikipedia",
    "wikidata",
    "commons_geo",
    "user_selected",
    "unsplash_legacy",
]


@dataclass(frozen=True)
class CoverCandidate:
    """One image suggestion produced by a no-key provider.

    ``url`` is always the publicly fetchable image URL. ``title`` carries
    whatever caption the provider supplies (Commons file name, Wikipedia
    article summary, etc.) so the LLM scorer can rank candidates by
    semantic fit even without seeing the pixels. ``attribution`` is the
    short string we surface in the UI to comply with CC-BY licensing on
    Wikimedia assets — never display a Commons image without it.
    """

    url: str
    source: CoverSource
    title: str | None = None
    attribution: str | None = None
    width: int | None = None
    height: int | None = None
    extra: dict[str, str] = field(default_factory=dict)

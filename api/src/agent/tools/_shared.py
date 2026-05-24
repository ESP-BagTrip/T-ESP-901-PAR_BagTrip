"""Shared primitives for agent tool modules."""

from __future__ import annotations

import asyncio

# Semaphore to limit concurrent Amadeus API calls (rate-limit protection).
_amadeus_semaphore = asyncio.Semaphore(3)

"""Thin service facade over `airlabs_client`.

Routes go through this module instead of importing the integration client
directly. Same layering rule as `AmadeusService` / `StripeGatewayService`.
"""

from __future__ import annotations

from src.integrations.airlabs.client import airlabs_client


class AirLabsService:
    """Facade for AirLabs flight lookups used by route handlers."""

    @staticmethod
    def lookup_flight(flight_iata: str) -> dict | None:
        """Return real-time info for the given IATA flight code, or None."""
        return airlabs_client.lookup_flight(flight_iata)

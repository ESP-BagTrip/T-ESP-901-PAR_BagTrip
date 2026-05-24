"""Thin service facade over `StripeClient`.

Same rationale as `AmadeusService`: routes and high-level services should not
import `StripeClient` directly. This module is the single point of contact for
Stripe operations in the application layer — everything else goes through it.

The `UserCreationService` keeps its direct `StripeClient.create_customer`
dependency for now because the user-creation flow is a self-contained unit
that pre-dates this refactor; migrating it is a Sprint 3 item.
"""

from __future__ import annotations

from src.integrations.stripe.client import StripeClient


class StripeGatewayService:
    """Facade for Stripe operations used by routes (non-payment flows)."""

    @staticmethod
    def delete_customer(customer_id: str) -> None:
        """Delete a Stripe customer — used by the RGPD account-deletion flow."""
        StripeClient.delete_customer(customer_id)

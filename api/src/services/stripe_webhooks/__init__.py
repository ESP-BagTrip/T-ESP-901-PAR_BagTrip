"""Stripe webhook processing — entry point for routes/tests.

Routes import `StripeWebhooksService.process_event(...)` from here. The
implementation is split by domain in `handlers/` for readability — the
service itself stays a thin dispatcher that handles persistence + idempotency.
"""

from src.services.stripe_webhooks.service import StripeWebhooksService

__all__ = ["StripeWebhooksService"]

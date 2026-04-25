"""Backward-compat shim — the implementation lives in `src.services.stripe_webhooks`.

Existing imports (`from src.services.stripe_webhooks_service import StripeWebhooksService`)
keep working. New code should import from the package directly.
"""

from src.services.stripe_webhooks import StripeWebhooksService

__all__ = ["StripeWebhooksService"]

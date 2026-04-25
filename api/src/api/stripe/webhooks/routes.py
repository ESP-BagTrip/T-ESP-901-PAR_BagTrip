"""Routes pour les webhooks Stripe."""

import json
from typing import Annotated

import stripe
from fastapi import APIRouter, Depends, Header, Request, status
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session

from src.config.database import get_db
from src.config.env import settings
from src.services.stripe_webhooks_service import StripeWebhooksService
from src.utils.logger import logger

router = APIRouter(prefix="/v1/stripe", tags=["Stripe Webhooks"])

# WARN once per process when the dev escape hatch is taken — that way the log
# isn't spammed but we'd notice immediately if it happened in a production-
# adjacent environment by mistake.
_warned_dev_escape_hatch = False


@router.post(
    "/webhooks",
    summary="Handle Stripe webhooks",
    description="Receive and process Stripe webhook events",
)
async def handle_stripe_webhook(
    request: Request,
    stripe_signature: Annotated[str, Header(..., alias="stripe-signature")],
    db: Annotated[Session, Depends(get_db)],
):
    """Receive a Stripe webhook event and dispatch it.

    Production / staging path: STRIPE_WEBHOOK_SECRET is set, signature is
    verified.

    Dev escape hatch: if NODE_ENV != "production" and STRIPE_WEBHOOK_SECRET
    is missing, accept unsigned events (Stripe CLI without `listen --secret`,
    handcrafted curl). `env.py` raises at boot if the secret is missing in
    production, so this branch is unreachable there.
    """
    body = await request.body()

    try:
        webhook_secret = settings.STRIPE_WEBHOOK_SECRET
        if webhook_secret:
            event = stripe.Webhook.construct_event(body, stripe_signature, webhook_secret)
        elif settings.NODE_ENV != "production":
            global _warned_dev_escape_hatch
            if not _warned_dev_escape_hatch:
                logger.warn(
                    "Stripe webhook signature verification DISABLED — "
                    "STRIPE_WEBHOOK_SECRET is unset and NODE_ENV is not 'production'. "
                    "Anyone able to reach the webhook URL can inject events. "
                    "Set STRIPE_WEBHOOK_SECRET in your .env to silence this warning."
                )
                _warned_dev_escape_hatch = True
            event = stripe.Event.construct_from(json.loads(body), None)
        else:
            # Should be unreachable — `env.py` raises at boot if the secret
            # is missing in production. Keep the guard as a final safety net.
            logger.error(
                "Webhook received in production without STRIPE_WEBHOOK_SECRET — "
                "rejecting. This indicates a misconfigured deployment."
            )
            return JSONResponse(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                content={"error": "Stripe webhook secret not configured"},
            )

        stripe_event = StripeWebhooksService.process_event(db, event)

        return JSONResponse(
            status_code=status.HTTP_200_OK,
            content={"received": True, "event_id": stripe_event.stripe_event_id},
        )

    except ValueError:
        # Invalid JSON — Stripe will retry, but it can't fix this. Log loudly
        # so the dev who sent the bad request notices.
        logger.warn("Stripe webhook received with invalid JSON payload")
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={"error": "Invalid payload"},
        )
    except stripe.error.SignatureVerificationError as exc:
        # Either a misconfigured secret on our side or a forged request. Both
        # warrant a WARN — Stripe will retry on its own if it was a transient
        # issue, but if our secret is wrong this will spam.
        logger.warn(f"Stripe webhook signature verification failed: {exc}")
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={"error": "Invalid signature"},
        )
    except Exception as exc:
        # Anything else is a programming bug. Log with full traceback so
        # we can fix it; respond 500 so Stripe retries.
        logger.error(f"Stripe webhook unhandled error: {exc}", exc_info=True)
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={"error": str(exc)},
        )

"""Routes pour les webhooks Stripe."""

import json

import stripe
from fastapi import APIRouter, Depends, Header, Request, status
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session

from src.config.database import get_db
from src.config.env import settings
from src.services.stripe_webhooks_service import StripeWebhooksService

router = APIRouter(prefix="/v1/stripe", tags=["Stripe Webhooks"])


@router.post(
    "/webhooks",
    summary="Handle Stripe webhooks",
    description="Receive and process Stripe webhook events",
)
async def handle_stripe_webhook(
    request: Request,
    stripe_signature: str = Header(..., alias="stripe-signature"),
    db: Session = Depends(get_db),
):
    """Traiter un webhook Stripe selon PLAN.md."""
    body = await request.body()

    try:
        # Vérifier la signature du webhook
        if settings.STRIPE_WEBHOOK_SECRET:
            event = stripe.Webhook.construct_event(
                body, stripe_signature, settings.STRIPE_WEBHOOK_SECRET
            )
        else:
            # En développement, parser sans vérification de signature
            event = stripe.Event.construct_from(json.loads(body), None)

        # Traiter l'événement
        stripe_event = StripeWebhooksService.process_event(db, event)

        return JSONResponse(
            status_code=status.HTTP_200_OK,
            content={"received": True, "event_id": stripe_event.stripe_event_id},
        )

    except ValueError:
        # JSON invalide
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={"error": "Invalid payload"},
        )
    except stripe.error.SignatureVerificationError:
        # Signature invalide
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={"error": "Invalid signature"},
        )
    except Exception as e:
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={"error": str(e)},
        )

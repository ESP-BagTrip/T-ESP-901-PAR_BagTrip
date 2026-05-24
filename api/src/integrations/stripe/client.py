"""Client Stripe wrapper.

Every mutating call accepts an optional `idempotency_key`. Stripe deduplicates
requests with the same key for 24h, so a network retry on the same business
operation can never create a duplicate PaymentIntent / refund / customer.
Callers are responsible for generating stable keys per operation
(e.g. `f"bi-{booking_intent_id}-authorize-v1"`).
"""

from __future__ import annotations

from typing import Any

import stripe
from src.config.env import settings

# Pin Stripe API version explicitly so a rolling Stripe update can't silently
# change webhook payload schemas under us. Bump deliberately, after re-running
# the integration tests against the new version.
STRIPE_API_VERSION = "2024-10-28.acacia"

if settings.STRIPE_SECRET_KEY:
    stripe.api_key = settings.STRIPE_SECRET_KEY
    stripe.api_version = STRIPE_API_VERSION


def _idem_kwargs(idempotency_key: str | None) -> dict[str, Any]:
    return {"idempotency_key": idempotency_key} if idempotency_key else {}


class StripeClient:
    """Wrapper Stripe — every mutating call supports idempotency keys."""

    # ------------------------------------------------------------------
    # Customer
    # ------------------------------------------------------------------

    @staticmethod
    def create_customer(
        email: str,
        name: str | None = None,
        idempotency_key: str | None = None,
    ) -> stripe.Customer:
        """Créer un client Stripe."""
        customer_data: dict[str, Any] = {"email": email}
        if name:
            customer_data["name"] = name
        return stripe.Customer.create(**customer_data, **_idem_kwargs(idempotency_key))

    @staticmethod
    def retrieve_customer(customer_id: str) -> stripe.Customer:
        """Récupérer un customer — utile pour vérifier qu'il existe encore.

        Raises `stripe.InvalidRequestError` with `code == 'resource_missing'`
        when the customer was deleted (manually in the dashboard, or because
        the secret key was switched to a different account).
        """
        return stripe.Customer.retrieve(customer_id)

    @staticmethod
    def delete_customer(customer_id: str) -> None:
        """Delete a Stripe customer."""
        stripe.Customer.delete(customer_id)

    # ------------------------------------------------------------------
    # PaymentIntent
    # ------------------------------------------------------------------

    @staticmethod
    def create_payment_intent(
        amount: int,
        currency: str,
        metadata: dict | None = None,
        capture_method: str = "manual",
        customer: str | None = None,
        description: str | None = None,
        idempotency_key: str | None = None,
    ) -> stripe.PaymentIntent:
        """Créer un PaymentIntent avec capture manuelle."""
        payment_intent_data: dict[str, Any] = {
            "amount": amount,
            "currency": currency.lower(),
            "capture_method": capture_method,
            "metadata": metadata or {},
        }
        if customer:
            payment_intent_data["customer"] = customer
        if description:
            payment_intent_data["description"] = description
        return stripe.PaymentIntent.create(**payment_intent_data, **_idem_kwargs(idempotency_key))

    @staticmethod
    def capture_payment_intent(
        payment_intent_id: str,
        idempotency_key: str | None = None,
    ) -> stripe.PaymentIntent:
        """Capturer un PaymentIntent."""
        return stripe.PaymentIntent.capture(payment_intent_id, **_idem_kwargs(idempotency_key))

    @staticmethod
    def cancel_payment_intent(
        payment_intent_id: str,
        idempotency_key: str | None = None,
    ) -> stripe.PaymentIntent:
        """Annuler un PaymentIntent."""
        return stripe.PaymentIntent.cancel(payment_intent_id, **_idem_kwargs(idempotency_key))

    @staticmethod
    def retrieve_payment_intent(payment_intent_id: str) -> stripe.PaymentIntent:
        """Récupérer un PaymentIntent."""
        return stripe.PaymentIntent.retrieve(payment_intent_id)

    # ------------------------------------------------------------------
    # Charge / Refund
    # ------------------------------------------------------------------

    @staticmethod
    def retrieve_charge(charge_id: str) -> stripe.Charge:
        """Récupérer un Charge — utile pour valider les montants refundables."""
        return stripe.Charge.retrieve(charge_id)

    @staticmethod
    def create_refund(
        charge_id: str,
        amount: int | None = None,
        reason: str | None = None,
        idempotency_key: str | None = None,
    ) -> stripe.Refund:
        """Créer un remboursement Stripe."""
        params: dict[str, Any] = {"charge": charge_id}
        if amount is not None:
            params["amount"] = amount
        if reason is not None:
            params["reason"] = reason
        return stripe.Refund.create(**params, **_idem_kwargs(idempotency_key))

    # ------------------------------------------------------------------
    # Subscription
    # ------------------------------------------------------------------

    @staticmethod
    def create_subscription(
        customer: str,
        price: str,
        idempotency_key: str | None = None,
        **fields: Any,
    ) -> stripe.Subscription:
        """Crée une subscription en `default_incomplete` pour PaymentSheet natif.

        Le mode `default_incomplete` retourne immédiatement une `Invoice`
        avec un `PaymentIntent` non-confirmé, dont le `client_secret` est
        passé au Flutter `PaymentSheet`. L'utilisateur paie dans l'app —
        pas de Checkout URL, pas de browser externe.
        """
        return stripe.Subscription.create(
            customer=customer,
            items=[{"price": price}],
            payment_behavior="default_incomplete",
            payment_settings={"save_default_payment_method": "on_subscription"},
            expand=["latest_invoice.payment_intent"],
            **fields,
            **_idem_kwargs(idempotency_key),
        )

    @staticmethod
    def retrieve_subscription(
        subscription_id: str,
        expand: list[str] | None = None,
    ) -> stripe.Subscription:
        """Récupérer une subscription."""
        if expand:
            return stripe.Subscription.retrieve(subscription_id, expand=expand)
        return stripe.Subscription.retrieve(subscription_id)

    @staticmethod
    def list_subscriptions(
        customer: str,
        status: str | None = None,
        limit: int = 10,
    ) -> stripe.ListObject:
        """Lister les subscriptions d'un customer (filtrable par statut)."""
        params: dict[str, Any] = {"customer": customer, "limit": limit}
        if status:
            params["status"] = status
        return stripe.Subscription.list(**params)

    @staticmethod
    def cancel_subscription(subscription_id: str) -> stripe.Subscription:
        """Annule immédiatement une subscription (pas en fin de période)."""
        return stripe.Subscription.cancel(subscription_id)

    @staticmethod
    def update_subscription(
        subscription_id: str,
        idempotency_key: str | None = None,
        **fields: Any,
    ) -> stripe.Subscription:
        """Modifier une subscription (cancel_at_period_end, items, etc.)."""
        return stripe.Subscription.modify(
            subscription_id, **fields, **_idem_kwargs(idempotency_key)
        )

    # ------------------------------------------------------------------
    # Invoice
    # ------------------------------------------------------------------

    @staticmethod
    def list_invoices(customer_id: str, limit: int = 12) -> stripe.ListObject:
        """Lister les invoices d'un customer (les plus récentes en premier)."""
        return stripe.Invoice.list(customer=customer_id, limit=limit)

    # ------------------------------------------------------------------
    # PaymentMethod / SetupIntent / EphemeralKey (mobile-native flows)
    # ------------------------------------------------------------------

    @staticmethod
    def retrieve_payment_method(payment_method_id: str) -> stripe.PaymentMethod:
        """Récupérer un PaymentMethod (last4, brand, exp_year, etc.)."""
        return stripe.PaymentMethod.retrieve(payment_method_id)

    @staticmethod
    def attach_payment_method(
        payment_method_id: str,
        customer_id: str,
        idempotency_key: str | None = None,
    ) -> stripe.PaymentMethod:
        """Attache un PaymentMethod à un Customer.

        En deferred IntentConfiguration, le PaymentMethod retourné par
        le `confirmHandler` côté SDK n'est *pas* encore attaché au
        customer — Stripe ne le fait qu'au moment où le client_secret
        confirme. Si on passe ce PM comme `default_payment_method` sur
        une Subscription avant l'attach, Stripe rejette avec
        `The payment method must be attached to the customer.`.
        On l'attache donc explicitement dans `/subscription/confirm`
        juste avant de créer la subscription.
        """
        return stripe.PaymentMethod.attach(
            payment_method_id,
            customer=customer_id,
            **_idem_kwargs(idempotency_key),
        )

    @staticmethod
    def create_setup_intent(
        customer: str,
        usage: str = "off_session",
        idempotency_key: str | None = None,
    ) -> stripe.SetupIntent:
        """Crée un `SetupIntent` pour ajouter / changer la CB en in-app.

        Utilisé par le PaymentSheet Flutter en mode setup — l'utilisateur
        attache une nouvelle carte sans quitter l'app, puis on l'attache
        comme `default_payment_method` du subscription.
        """
        return stripe.SetupIntent.create(
            customer=customer,
            usage=usage,
            **_idem_kwargs(idempotency_key),
        )

    @staticmethod
    def create_ephemeral_key(customer_id: str) -> stripe.EphemeralKey:
        """Clé éphémère restreinte pour le SDK mobile.

        Sans ça, le PaymentSheet Flutter ne peut pas lister les
        PaymentMethods sauvegardés du customer. La clé expire au bout
        d'une heure et n'est valide que pour ce customer — c'est l'API
        officielle Stripe pour les SDK iOS/Android/Flutter.
        """
        return stripe.EphemeralKey.create(
            customer=customer_id,
            stripe_version=STRIPE_API_VERSION,
        )

    # ------------------------------------------------------------------
    # Billing Portal
    # ------------------------------------------------------------------

    @staticmethod
    def create_billing_portal_session(
        customer_id: str,
        return_url: str,
        idempotency_key: str | None = None,
    ) -> stripe.billing_portal.Session:
        """Crée une session du Customer Portal Stripe."""
        return stripe.billing_portal.Session.create(
            customer=customer_id,
            return_url=return_url,
            **_idem_kwargs(idempotency_key),
        )

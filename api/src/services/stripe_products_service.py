"""Service pour la gestion des produits Stripe."""

import stripe

from src.config.env import settings
from src.utils.logger import logger

# Cache des product IDs (initialisé au démarrage)
STRIPE_PRODUCT_IDS: dict[str, str] = {}


class StripeProductsService:
    """Service pour la gestion des produits Stripe."""

    @staticmethod
    def initialize_products() -> dict[str, str]:
        """
        Initialise les produits Stripe (flight et hotel) si ils n'existent pas.
        Retourne un dictionnaire avec les product IDs.
        """
        if not settings.STRIPE_SECRET_KEY:
            logger.warn("STRIPE_SECRET_KEY not set, skipping product initialization")
            return {}

        try:
            # Rechercher ou créer le produit Flight
            flight_product_id = StripeProductsService._get_or_create_product(
                name="Flight Booking",
                description="Flight booking service",
                metadata={"type": "flight"},
            )

            # Rechercher ou créer le produit Hotel
            hotel_product_id = StripeProductsService._get_or_create_product(
                name="Hotel Booking",
                description="Hotel booking service",
                metadata={"type": "hotel"},
            )

            product_ids = {
                "flight": flight_product_id,
                "hotel": hotel_product_id,
            }

            # Mettre à jour le cache global
            global STRIPE_PRODUCT_IDS
            STRIPE_PRODUCT_IDS = product_ids

            logger.info(f"Stripe products initialized: {product_ids}")
            return product_ids

        except Exception as e:
            logger.error(f"Failed to initialize Stripe products: {e}", exc_info=True)
            return {}

    @staticmethod
    def _get_or_create_product(name: str, description: str, metadata: dict) -> str:
        """
        Recherche un produit par metadata ou le crée s'il n'existe pas.
        """
        # Rechercher les produits existants avec le même type dans metadata
        product_type = metadata.get("type")
        if product_type:
            products = stripe.Product.list(limit=100, active=True)
            for product in products:
                if product.metadata.get("type") == product_type:
                    logger.info(f"Found existing Stripe product: {product.name} ({product.id})")
                    return product.id

        # Créer le produit s'il n'existe pas
        product = stripe.Product.create(
            name=name,
            description=description,
            metadata=metadata,
        )
        logger.info(f"Created new Stripe product: {product.name} ({product.id})")
        return product.id

    @staticmethod
    def get_product_id(product_type: str) -> str | None:
        """
        Récupère le product ID depuis le cache.
        """
        return STRIPE_PRODUCT_IDS.get(product_type)

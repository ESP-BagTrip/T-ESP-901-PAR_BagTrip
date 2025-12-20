"""Migration script to add booking_intent_id to flight_orders and hotel_bookings tables."""

from sqlalchemy import text
from sqlalchemy.engine import Engine

from src.config.database import engine
from src.utils.logger import logger


def migrate_booking_tables(engine: Engine) -> None:
    """
    Migrate booking tables to add booking_intent_id column:
    - Add booking_intent_id to flight_orders
    - Add booking_intent_id to hotel_bookings
    """
    with engine.connect() as conn:
        # Start transaction
        trans = conn.begin()

        try:
            # Check if booking_intent_id column exists in flight_orders
            result = conn.execute(
                text(
                    """
                    SELECT column_name
                    FROM information_schema.columns
                    WHERE table_name = 'flight_orders' AND column_name = 'booking_intent_id'
                    """
                )
            )
            has_booking_intent_id_flight = result.fetchone() is not None

            # Add booking_intent_id to flight_orders if it doesn't exist
            if not has_booking_intent_id_flight:
                logger.info("Adding booking_intent_id column to flight_orders")
                conn.execute(
                    text(
                        """
                        ALTER TABLE flight_orders
                        ADD COLUMN booking_intent_id UUID REFERENCES booking_intents(id)
                        """
                    )
                )
                logger.info("Successfully added booking_intent_id to flight_orders")

            # Check if booking_intent_id column exists in hotel_bookings
            result = conn.execute(
                text(
                    """
                    SELECT column_name
                    FROM information_schema.columns
                    WHERE table_name = 'hotel_bookings' AND column_name = 'booking_intent_id'
                    """
                )
            )
            has_booking_intent_id_hotel = result.fetchone() is not None

            # Add booking_intent_id to hotel_bookings if it doesn't exist
            if not has_booking_intent_id_hotel:
                logger.info("Adding booking_intent_id column to hotel_bookings")
                conn.execute(
                    text(
                        """
                        ALTER TABLE hotel_bookings
                        ADD COLUMN booking_intent_id UUID REFERENCES booking_intents(id)
                        """
                    )
                )
                logger.info("Successfully added booking_intent_id to hotel_bookings")

            # Commit transaction
            trans.commit()
            logger.info("Booking tables migration completed successfully")

        except Exception as e:
            trans.rollback()
            logger.error(f"Migration failed: {e}", exc_info=True)
            raise


if __name__ == "__main__":
    migrate_booking_tables(engine)

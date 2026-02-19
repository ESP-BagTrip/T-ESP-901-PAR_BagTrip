"""Migration script to create the traveler_profiles table."""

from sqlalchemy import text
from sqlalchemy.engine import Engine

from src.config.database import engine
from src.utils.logger import logger


def migrate_traveler_profiles(engine: Engine) -> None:
    """Create the traveler_profiles table if it doesn't exist. Idempotent."""
    with engine.connect() as conn:
        trans = conn.begin()
        try:
            result = conn.execute(
                text(
                    """
                    SELECT EXISTS (
                        SELECT FROM information_schema.tables
                        WHERE table_name = 'traveler_profiles'
                    )
                    """
                )
            )
            table_exists = result.fetchone()[0]

            if not table_exists:
                logger.info("Creating traveler_profiles table")
                conn.execute(
                    text(
                        """
                        CREATE TABLE traveler_profiles (
                            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                            user_id UUID NOT NULL REFERENCES users(id),
                            travel_types JSONB,
                            travel_style VARCHAR,
                            budget VARCHAR,
                            companions VARCHAR,
                            is_completed BOOLEAN NOT NULL DEFAULT FALSE,
                            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                            updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
                        )
                        """
                    )
                )
                conn.execute(
                    text("CREATE UNIQUE INDEX ix_traveler_profiles_user_id ON traveler_profiles (user_id)")
                )
                logger.info("traveler_profiles table created successfully")
            else:
                logger.info("traveler_profiles table already exists, skipping")

            trans.commit()
        except Exception as e:
            trans.rollback()
            logger.error(f"Traveler profiles migration failed: {e}", exc_info=True)
            raise


if __name__ == "__main__":
    migrate_traveler_profiles(engine)

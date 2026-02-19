"""Migration script to create the refresh_tokens table."""

from sqlalchemy import text
from sqlalchemy.engine import Engine

from src.config.database import engine
from src.utils.logger import logger


def migrate_refresh_tokens(engine: Engine) -> None:
    """Create the refresh_tokens table if it doesn't exist. Idempotent."""
    with engine.connect() as conn:
        trans = conn.begin()
        try:
            result = conn.execute(
                text(
                    """
                    SELECT EXISTS (
                        SELECT FROM information_schema.tables
                        WHERE table_name = 'refresh_tokens'
                    )
                    """
                )
            )
            table_exists = result.fetchone()[0]

            if not table_exists:
                logger.info("Creating refresh_tokens table")
                conn.execute(
                    text(
                        """
                        CREATE TABLE refresh_tokens (
                            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                            user_id UUID NOT NULL REFERENCES users(id),
                            token VARCHAR NOT NULL,
                            expires_at TIMESTAMPTZ NOT NULL,
                            revoked BOOLEAN NOT NULL DEFAULT FALSE,
                            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
                        )
                        """
                    )
                )
                conn.execute(
                    text("CREATE INDEX ix_refresh_tokens_user_id ON refresh_tokens (user_id)")
                )
                conn.execute(
                    text("CREATE UNIQUE INDEX ix_refresh_tokens_token ON refresh_tokens (token)")
                )
                logger.info("refresh_tokens table created successfully")
            else:
                logger.info("refresh_tokens table already exists, skipping")

            trans.commit()
        except Exception as e:
            trans.rollback()
            logger.error(f"Refresh tokens migration failed: {e}", exc_info=True)
            raise


if __name__ == "__main__":
    migrate_refresh_tokens(engine)

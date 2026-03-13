"""Migration script to add new columns to the trips table."""

from sqlalchemy import text
from sqlalchemy.engine import Engine

from src.config.database import engine
from src.utils.logger import logger


def migrate_trips_table(engine: Engine) -> None:
    """Add new columns to the trips table if they don't exist. Idempotent."""
    with engine.connect() as conn:
        trans = conn.begin()
        try:
            columns_to_add = [
                ("description", "TEXT"),
                ("cover_image_url", "VARCHAR"),
                ("destination_name", "VARCHAR"),
                ("nb_travelers", "INTEGER DEFAULT 1"),
                ("archived_at", "TIMESTAMPTZ"),
            ]

            for column_name, column_type in columns_to_add:
                result = conn.execute(
                    text(
                        """
                        SELECT EXISTS (
                            SELECT FROM information_schema.columns
                            WHERE table_name = 'trips' AND column_name = :col_name
                        )
                        """
                    ),
                    {"col_name": column_name},
                )
                column_exists = result.fetchone()[0]

                if not column_exists:
                    logger.info(f"Adding column {column_name} to trips table")
                    conn.execute(
                        text(f"ALTER TABLE trips ADD COLUMN {column_name} {column_type}")
                    )
                    logger.info(f"Column {column_name} added successfully")
                else:
                    logger.info(f"Column {column_name} already exists in trips table, skipping")

            # Update existing status values: planned -> planning
            conn.execute(
                text("UPDATE trips SET status = 'planning' WHERE status = 'planned'")
            )
            logger.info("Updated existing 'planned' status values to 'planning'")

            trans.commit()
        except Exception as e:
            trans.rollback()
            logger.error(f"Trips table migration failed: {e}", exc_info=True)
            raise


if __name__ == "__main__":
    migrate_trips_table(engine)

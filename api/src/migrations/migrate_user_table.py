"""Migration script to update users table schema."""

from sqlalchemy import text
from sqlalchemy.engine import Engine

from src.config.database import engine
from src.utils.logger import logger


def migrate_user_table(engine: Engine) -> None:
    """
    Migrate users table to match new schema:
    - Rename password to password_hash
    - Add full_name column
    - Add phone column
    - Add stripe_customer_id column
    """
    with engine.connect() as conn:
        # Start transaction
        trans = conn.begin()

        try:
            # Check if users table exists
            result = conn.execute(
                text(
                    """
                    SELECT table_name
                    FROM information_schema.tables
                    WHERE table_schema = 'public' AND table_name = 'users'
                    """
                )
            )
            table_exists = result.fetchone() is not None

            if not table_exists:
                logger.info(
                    "Users table does not exist yet, skipping migration (will be created by SQLAlchemy)"
                )
                trans.commit()
                return

            # Check if password_hash column exists
            result = conn.execute(
                text(
                    """
                    SELECT column_name
                    FROM information_schema.columns
                    WHERE table_name = 'users' AND column_name = 'password_hash'
                    """
                )
            )
            has_password_hash = result.fetchone() is not None

            # Check if password column exists
            result = conn.execute(
                text(
                    """
                    SELECT column_name
                    FROM information_schema.columns
                    WHERE table_name = 'users' AND column_name = 'password'
                    """
                )
            )
            has_password = result.fetchone() is not None

            # Rename password to password_hash if needed
            if has_password and not has_password_hash:
                logger.info("Renaming password column to password_hash")
                conn.execute(text("ALTER TABLE users RENAME COLUMN password TO password_hash"))
                logger.info("Successfully renamed password to password_hash")

            # Rename createdAt to created_at if needed
            result = conn.execute(
                text(
                    """
                    SELECT column_name
                    FROM information_schema.columns
                    WHERE table_name = 'users' AND column_name = 'createdAt'
                    """
                )
            )
            has_created_at_camel = result.fetchone() is not None

            result = conn.execute(
                text(
                    """
                    SELECT column_name
                    FROM information_schema.columns
                    WHERE table_name = 'users' AND column_name = 'created_at'
                    """
                )
            )
            has_created_at_snake = result.fetchone() is not None

            if has_created_at_camel and not has_created_at_snake:
                logger.info("Renaming createdAt column to created_at")
                conn.execute(text('ALTER TABLE users RENAME COLUMN "createdAt" TO created_at'))
                logger.info("Successfully renamed createdAt to created_at")

            # Rename updatedAt to updated_at if needed
            result = conn.execute(
                text(
                    """
                    SELECT column_name
                    FROM information_schema.columns
                    WHERE table_name = 'users' AND column_name = 'updatedAt'
                    """
                )
            )
            has_updated_at_camel = result.fetchone() is not None

            result = conn.execute(
                text(
                    """
                    SELECT column_name
                    FROM information_schema.columns
                    WHERE table_name = 'users' AND column_name = 'updated_at'
                    """
                )
            )
            has_updated_at_snake = result.fetchone() is not None

            if has_updated_at_camel and not has_updated_at_snake:
                logger.info("Renaming updatedAt column to updated_at")
                conn.execute(text('ALTER TABLE users RENAME COLUMN "updatedAt" TO updated_at'))
                logger.info("Successfully renamed updatedAt to updated_at")

            # Add full_name column if it doesn't exist
            result = conn.execute(
                text(
                    """
                    SELECT column_name
                    FROM information_schema.columns
                    WHERE table_name = 'users' AND column_name = 'full_name'
                    """
                )
            )
            if result.fetchone() is None:
                logger.info("Adding full_name column")
                conn.execute(text("ALTER TABLE users ADD COLUMN full_name VARCHAR"))
                logger.info("Successfully added full_name column")

            # Add phone column if it doesn't exist
            result = conn.execute(
                text(
                    """
                    SELECT column_name
                    FROM information_schema.columns
                    WHERE table_name = 'users' AND column_name = 'phone'
                    """
                )
            )
            if result.fetchone() is None:
                logger.info("Adding phone column")
                conn.execute(text("ALTER TABLE users ADD COLUMN phone VARCHAR"))
                logger.info("Successfully added phone column")

            # Add stripe_customer_id column if it doesn't exist
            result = conn.execute(
                text(
                    """
                    SELECT column_name
                    FROM information_schema.columns
                    WHERE table_name = 'users' AND column_name = 'stripe_customer_id'
                    """
                )
            )
            if result.fetchone() is None:
                logger.info("Adding stripe_customer_id column")
                conn.execute(text("ALTER TABLE users ADD COLUMN stripe_customer_id VARCHAR"))
                conn.execute(
                    text(
                        "CREATE INDEX IF NOT EXISTS idx_users_stripe_customer_id ON users(stripe_customer_id)"
                    )
                )
                logger.info("Successfully added stripe_customer_id column")

            # Commit transaction
            trans.commit()
            logger.info("User table migration completed successfully")

        except Exception as e:
            trans.rollback()
            logger.error(f"Migration failed: {e}", exc_info=True)
            raise


if __name__ == "__main__":
    migrate_user_table(engine)

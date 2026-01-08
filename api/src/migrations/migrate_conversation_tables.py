"""Migration script to create conversation-related tables."""

from sqlalchemy import text
from sqlalchemy.engine import Engine

from src.config.database import engine
from src.utils.logger import logger


def migrate_conversation_tables(engine: Engine) -> None:
    """
    Migrate conversation-related tables:
    - Create conversations table
    - Create messages table
    - Create contexts table
    """
    with engine.connect() as conn:
        # Start transaction
        trans = conn.begin()

        try:
            # Check if conversations table exists
            result = conn.execute(
                text(
                    """
                    SELECT EXISTS (
                        SELECT FROM information_schema.tables
                        WHERE table_schema = 'public' AND table_name = 'conversations'
                    )
                    """
                )
            )
            conversations_table_exists = result.fetchone()[0]

            # Create conversations table if it doesn't exist
            if not conversations_table_exists:
                logger.info("Creating conversations table")
                conn.execute(
                    text(
                        """
                        CREATE TABLE conversations (
                            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                            trip_id UUID NOT NULL
                                REFERENCES trips(id) ON DELETE CASCADE,
                            user_id UUID NOT NULL
                                REFERENCES users(id) ON DELETE CASCADE,
                            title VARCHAR,
                            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
                            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
                        )
                        """
                    )
                )
                # Create indexes
                conn.execute(
                    text("CREATE INDEX idx_conversations_trip_id ON conversations(trip_id)")
                )
                conn.execute(
                    text("CREATE INDEX idx_conversations_user_id ON conversations(user_id)")
                )
                logger.info("Successfully created conversations table")
            else:
                logger.info("conversations table already exists, skipping creation")

            # Check if messages table exists
            result = conn.execute(
                text(
                    """
                    SELECT EXISTS (
                        SELECT FROM information_schema.tables
                        WHERE table_schema = 'public' AND table_name = 'messages'
                    )
                    """
                )
            )
            messages_table_exists = result.fetchone()[0]

            # Create messages table if it doesn't exist
            if not messages_table_exists:
                logger.info("Creating messages table")
                conn.execute(
                    text(
                        """
                        CREATE TABLE messages (
                            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                            conversation_id UUID NOT NULL
                                REFERENCES conversations(id) ON DELETE CASCADE,
                            role VARCHAR NOT NULL
                                CHECK (role IN ('user', 'assistant', 'tool')),
                            content TEXT NOT NULL,
                            message_metadata JSONB,
                            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
                        )
                        """
                    )
                )
                # Create indexes
                conn.execute(
                    text(
                        "CREATE INDEX idx_messages_conversation_id "
                        "ON messages(conversation_id)"
                    )
                )
                conn.execute(
                    text(
                        "CREATE INDEX idx_messages_created_at "
                        "ON messages(conversation_id, created_at)"
                    )
                )
                logger.info("Successfully created messages table")
            else:
                logger.info("messages table already exists, skipping creation")

            # Check if contexts table exists
            result = conn.execute(
                text(
                    """
                    SELECT EXISTS (
                        SELECT FROM information_schema.tables
                        WHERE table_schema = 'public' AND table_name = 'contexts'
                    )
                    """
                )
            )
            contexts_table_exists = result.fetchone()[0]

            # Create contexts table if it doesn't exist
            if not contexts_table_exists:
                logger.info("Creating contexts table")
                conn.execute(
                    text(
                        """
                        CREATE TABLE contexts (
                            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                            user_id UUID NOT NULL
                                REFERENCES users(id) ON DELETE CASCADE,
                            trip_id UUID NOT NULL
                                REFERENCES trips(id) ON DELETE CASCADE,
                            conversation_id UUID NOT NULL
                                REFERENCES conversations(id) ON DELETE CASCADE,
                            version INTEGER NOT NULL DEFAULT 1,
                            state JSONB NOT NULL,
                            ui JSONB NOT NULL,
                            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
                        )
                        """
                    )
                )
                # Create indexes
                conn.execute(
                    text(
                        "CREATE INDEX idx_contexts_user_trip_conv "
                        "ON contexts(user_id, trip_id, conversation_id)"
                    )
                )
                conn.execute(
                    text(
                        "CREATE INDEX idx_contexts_conversation_version "
                        "ON contexts(conversation_id, version DESC)"
                    )
                )
                logger.info("Successfully created contexts table")
            else:
                logger.info("contexts table already exists, skipping creation")

            # Commit transaction
            trans.commit()
            logger.info("Conversation tables migration completed successfully")

        except Exception as e:
            trans.rollback()
            logger.error(f"Migration failed: {e}", exc_info=True)
            raise


if __name__ == "__main__":
    migrate_conversation_tables(engine)

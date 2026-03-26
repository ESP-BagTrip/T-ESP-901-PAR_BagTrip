"""Add TRIP_STARTED to NotificationType.

Revision ID: 0018
Revises: 0017
Create Date: 2026-03-19

Note: notifications.type is a plain String column, so no ALTER TYPE
is needed. This migration exists for audit trail and to update any
rows that might reference the old naming convention.
"""

revision = "0018"
down_revision = "0017"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # No schema change needed — notifications.type is a String column.
    # TRIP_STARTED is now a valid value in the Python NotificationType enum.
    pass


def downgrade() -> None:
    # Remove any TRIP_STARTED notifications that may have been created
    from alembic import op

    op.execute("DELETE FROM notifications WHERE type = 'TRIP_STARTED'")

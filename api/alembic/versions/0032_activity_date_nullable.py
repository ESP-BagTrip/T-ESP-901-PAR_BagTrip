"""Make activities.date nullable for undated MEAL/TRANSPORT recommendations.

Revision ID: 0032
Revises: 0031
Create Date: 2026-05-03

SMP-324 (cohérence budget IA ↔ trip detail) — the AI activity_planner now
emits short lists of recommendations alongside the dated itinerary:
restaurants worth trying ("a essayer") and transports useful for the
destination (JR Pass, transfer aéroport, ...). Those recommendations are
intentionally not pinned to a calendar slot — they live in dedicated
sections of the review screen and the trip detail.

Modelling them as ``Activity`` rows keeps a single source of truth for
the budget aggregation (one item, one BudgetItem, one number on both
the review breakdown and the trip detail), but it requires
``activities.date`` to accept NULL for the undated case. The dated
itinerary keeps using the column as before.
"""

import sqlalchemy as sa

from alembic import op

revision = "0032"
down_revision = "0031"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Existing rows are all dated — no data migration needed.
    op.alter_column(
        "activities",
        "date",
        existing_type=sa.Date(),
        nullable=True,
    )


def downgrade() -> None:
    # Backfill any NULL dates with the related trip's start_date before
    # restoring the NOT NULL constraint, so a downgrade does not fail
    # on rows produced by SMP-324.
    op.execute(
        """
        UPDATE activities
        SET date = trips.start_date
        FROM trips
        WHERE activities.trip_id = trips.id
          AND activities.date IS NULL
          AND trips.start_date IS NOT NULL
        """
    )
    op.alter_column(
        "activities",
        "date",
        existing_type=sa.Date(),
        nullable=False,
    )

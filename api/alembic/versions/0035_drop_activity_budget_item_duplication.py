"""Remove the BudgetItem rows that mirror Activity costs.

Revision ID: 0035
Revises: 0034
Create Date: 2026-05-08

Phase B1 (SMP-325) makes ``Activity`` the single source of truth for
activity costs. Up until this migration, ``PlanDraftService`` mirrored
each activity into a ``BudgetItem`` row with ``source_type='activity'``
and ``category='ACTIVITY'``. The mirror was both a UX bug (every
suggestion appeared twice in the trip detail — once in the Itinerary
tab, once in the Budget tab) and a correctness bug (the budget summary
summed activity costs from both tables, inflating ``total_spent`` by
roughly x2 for AI-planned trips).

This migration:

1. recomputes ``trips.budget_estimated`` for every trip that has at
   least one mirrored ``BudgetItem``, summing only the rows we are
   about to keep (everything except ``source_type='activity'``);
2. deletes every ``BudgetItem`` with ``source_type='activity'``.

It is intentionally not data-preserving for the deleted rows: their
content was a stale copy of ``activities.estimated_cost``, and the
budget summary now reads from the live activities table.
"""

import sqlalchemy as sa

from alembic import op

revision = "0035"
down_revision = "0034"
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    # Recompute trip.budget_estimated for trips that had mirrored rows,
    # using only the BudgetItem rows we are about to keep.
    bind.execute(
        sa.text(
            """
            UPDATE trips t
            SET budget_estimated = COALESCE(sub.kept_total, 0)
            FROM (
                SELECT trip_id,
                       SUM(amount) FILTER (
                           WHERE source_type IS DISTINCT FROM 'activity'
                       ) AS kept_total
                FROM budget_items
                WHERE trip_id IN (
                    SELECT DISTINCT trip_id
                    FROM budget_items
                    WHERE source_type = 'activity'
                )
                GROUP BY trip_id
            ) AS sub
            WHERE t.id = sub.trip_id
            """
        )
    )
    bind.execute(sa.text("DELETE FROM budget_items WHERE source_type = 'activity'"))


def downgrade() -> None:
    # The mirrored rows are derivable from activities.estimated_cost, so
    # the downgrade rebuilds them from the live activity data instead of
    # storing them in the migration. ``trip.budget_estimated`` is not
    # rolled back: it would require knowing the previous (inflated)
    # value, which we have purposely overwritten.
    bind = op.get_bind()
    bind.execute(
        sa.text(
            """
            INSERT INTO budget_items (
                id, trip_id, label, amount, currency, category, date,
                is_planned, source_type, source_id,
                created_at, updated_at
            )
            SELECT
                gen_random_uuid(),
                a.trip_id,
                a.title,
                a.estimated_cost,
                COALESCE(t.currency, 'EUR'),
                'ACTIVITY',
                a.date,
                TRUE,
                'activity',
                a.id,
                NOW(),
                NOW()
            FROM activities a
            JOIN trips t ON t.id = a.trip_id
            WHERE a.estimated_cost IS NOT NULL AND a.estimated_cost > 0
            """
        )
    )

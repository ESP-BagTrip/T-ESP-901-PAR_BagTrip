"""Backfill ``BudgetItem.source_type`` for legacy rows.

Revision ID: 0031
Revises: 0030
Create Date: 2026-05-02

Topic 07 (SMP-322). Pre-migration-0009 BudgetItems were created without
a ``source_type`` (the column was added later). Today's services
(``PlanAcceptanceService._persist_activities`` /
``_persist_accommodations`` / ``_maybe_add_flight_budget``) tag every
new row, but the historical rows still surface as
``source_type IS NULL`` — which the topic-06 redaction logic and the
forecast / confirmed split treat differently from explicitly-tagged
rows.

This migration is data-only. It tags everything still NULL as
``'manual'`` (the safest default — the user typed it). Rows that
already carry a tag (``activity``, ``accommodation``, ``flight``,
``synthetic_flight``…) are left untouched.

The ``§6`` query in the backfill report cited FK columns that don't
exist on ``budget_items`` (``related_activity_id`` / ``related_*``);
the canonical column pair is ``source_type`` / ``source_id``. Use this
migration as the documented reference.

Downgrade is a no-op: the original NULLs cannot be safely identified
once we've collapsed them with already-manual rows. Documenting the
asymmetry rather than guessing.
"""

import sqlalchemy as sa

from alembic import op

revision = "0031"
down_revision = "0030"
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    before = bind.execute(
        sa.text("SELECT COUNT(*) FROM budget_items WHERE source_type IS NULL")
    ).scalar_one()
    op.execute(
        "UPDATE budget_items SET source_type = 'manual' WHERE source_type IS NULL"
    )
    after = bind.execute(
        sa.text("SELECT COUNT(*) FROM budget_items WHERE source_type IS NULL")
    ).scalar_one()
    print(  # noqa: T201 — Alembic stdout is the canonical migration log
        f"[0031] Backfilled source_type='manual' on {before - after} budget_items "
        f"({before} were NULL pre-migration, {after} remain NULL post-migration)."
    )


def downgrade() -> None:
    # Conservative — see module docstring. We can't tell the manually-typed
    # 'manual' rows from the legacy NULLs we just relabelled.
    pass

"""Split Trip.budget_total into budget_target / budget_estimated / budget_actual.

Revision ID: 0029
Revises: 0028
Create Date: 2026-05-02

Topic 02 (SMP-322). The legacy ``budget_total`` column on ``trips`` mixed
three user-facing semantics:

1. The target the user typed at the wizard.
2. The AI estimation (which currently overwrites the target on accept).
3. The realised actual (sum of confirmed BudgetItems).

This migration carves out the first two as explicit columns. The third
stays runtime-only — computed from BudgetItems via
``BudgetItemService.get_budget_summary()``. We add ``budget_actual``
anyway as a reserved nullable slot so future materialisation does not
require another schema move (cf. EXECUTION-PLAN §3 D4).

Backfill: existing trips have their ``budget_total`` value moved to
``budget_target`` (the target was the user's intent — that is the
field they must keep). ``budget_estimated`` and ``budget_actual``
start NULL.

Downgrade reverses the move with COALESCE(estimated, target). Note:
the downgrade is only safe before any client started writing
``budget_estimated`` separately — once the application code splits
the writes, the downgrade *will* lose the estimation. Use it for
staging rollback only (cf. EXECUTION-PLAN §4.2).
"""

import sqlalchemy as sa

from alembic import op

revision = "0029"
down_revision = "0028"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "trips", sa.Column("budget_target", sa.Numeric(12, 2), nullable=True)
    )
    op.add_column(
        "trips", sa.Column("budget_estimated", sa.Numeric(12, 2), nullable=True)
    )
    op.add_column(
        "trips", sa.Column("budget_actual", sa.Numeric(12, 2), nullable=True)
    )

    op.execute(
        "UPDATE trips SET budget_target = budget_total WHERE budget_total IS NOT NULL"
    )

    op.drop_column("trips", "budget_total")


def downgrade() -> None:
    op.add_column("trips", sa.Column("budget_total", sa.Numeric(12, 2), nullable=True))

    op.execute(
        "UPDATE trips "
        "SET budget_total = COALESCE(budget_estimated, budget_target) "
        "WHERE budget_estimated IS NOT NULL OR budget_target IS NOT NULL"
    )

    op.drop_column("trips", "budget_actual")
    op.drop_column("trips", "budget_estimated")
    op.drop_column("trips", "budget_target")

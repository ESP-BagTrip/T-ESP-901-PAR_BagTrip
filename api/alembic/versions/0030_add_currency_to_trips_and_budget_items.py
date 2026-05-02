"""Add currency NOT NULL DEFAULT 'EUR' to trips and budget_items.

Revision ID: 0030
Revises: 0029
Create Date: 2026-05-02

Topic 04b (SMP-322), phase 1. The legacy schema treated EUR as implicit
everywhere and relied on `accommodations.currency` alone (already
nullable). To support multi-currency trips end-to-end (B8/B11) we need
the *trip* itself to carry an explicit currency (the canonical one all
the BudgetItems are converted to before aggregation) and each BudgetItem
to remember in which currency it was entered.

ECB conversion logic is delivered as a service stub in this phase:
schemas + persistence are now multi-currency-ready, the actual rate
fetcher is a follow-up (cf. EXECUTION-PLAN §3 D2). With the fallback
``rate=1.0``, behaviour is bit-for-bit identical to pre-migration
(everyone EUR) so the migration is safe to deploy ahead of the
service wire-up.
"""

import sqlalchemy as sa

from alembic import op

revision = "0030"
down_revision = "0029"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "trips",
        sa.Column(
            "currency",
            sa.String(length=3),
            nullable=False,
            server_default="EUR",
        ),
    )
    op.add_column(
        "budget_items",
        sa.Column(
            "currency",
            sa.String(length=3),
            nullable=False,
            server_default="EUR",
        ),
    )


def downgrade() -> None:
    op.drop_column("budget_items", "currency")
    op.drop_column("trips", "currency")

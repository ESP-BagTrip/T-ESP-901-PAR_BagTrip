"""Add validation_status to budget_items.

Revision ID: 0033
Revises: 0032
Create Date: 2026-05-07

Aligns ``BudgetItem`` on the same ``validation_status`` semantics as
``Activity`` / ``ManualFlight`` / ``Accommodation``. Pre-existing rows
keep ``MANUAL`` since the SUGGESTED state did not exist before this
revision — they were created by the user (or by sub-systems that have
no AI provenance to claim).

``PlanDraftService`` now stamps every budget line it emits at draft
persistence time with ``SUGGESTED`` so the user can validate them
through the same one-gesture flow as the rest of the trip surface.
"""

import sqlalchemy as sa

from alembic import op

revision = "0033"
down_revision = "0032"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "budget_items",
        sa.Column(
            "validation_status",
            sa.String(),
            nullable=False,
            server_default="MANUAL",
        ),
    )


def downgrade() -> None:
    op.drop_column("budget_items", "validation_status")

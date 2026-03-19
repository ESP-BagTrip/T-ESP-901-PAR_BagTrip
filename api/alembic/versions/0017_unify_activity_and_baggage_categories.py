"""Unify ActivityCategory and BaggageCategory enums.

Revision ID: 0017
Revises: 0016
Create Date: 2026-03-19
"""

from alembic import op

revision = "0017"
down_revision = "0016"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ActivityCategory: VISIT→CULTURE, RESTAURANT→FOOD, LEISURE→RELAXATION, TRANSPORT→OTHER
    op.execute("UPDATE activities SET category = 'CULTURE' WHERE category = 'VISIT'")
    op.execute("UPDATE activities SET category = 'FOOD' WHERE category = 'RESTAURANT'")
    op.execute("UPDATE activities SET category = 'RELAXATION' WHERE category = 'LEISURE'")
    op.execute("UPDATE activities SET category = 'OTHER' WHERE category = 'TRANSPORT'")

    # BaggageCategory: CLOTHES→CLOTHING, HYGIENE→TOILETRIES + fix French labels from Flutter bug
    op.execute("UPDATE baggage_items SET category = 'CLOTHING' WHERE category IN ('CLOTHES', 'Vetements')")
    op.execute("UPDATE baggage_items SET category = 'TOILETRIES' WHERE category IN ('HYGIENE', 'Toilette')")
    op.execute("UPDATE baggage_items SET category = 'ELECTRONICS' WHERE category = 'Electronique'")
    op.execute("UPDATE baggage_items SET category = 'HEALTH' WHERE category = 'Sante'")
    op.execute("UPDATE baggage_items SET category = 'ACCESSORIES' WHERE category = 'Accessoires'")
    op.execute("UPDATE baggage_items SET category = 'DOCUMENTS' WHERE category = 'Documents'")
    op.execute("UPDATE baggage_items SET category = 'OTHER' WHERE category = 'Autre'")


def downgrade() -> None:
    # ActivityCategory: reverse mapping
    op.execute("UPDATE activities SET category = 'VISIT' WHERE category = 'CULTURE'")
    op.execute("UPDATE activities SET category = 'RESTAURANT' WHERE category = 'FOOD'")
    op.execute("UPDATE activities SET category = 'LEISURE' WHERE category = 'RELAXATION'")

    # BaggageCategory: reverse mapping
    op.execute("UPDATE baggage_items SET category = 'CLOTHES' WHERE category = 'CLOTHING'")
    op.execute("UPDATE baggage_items SET category = 'HYGIENE' WHERE category = 'TOILETRIES'")

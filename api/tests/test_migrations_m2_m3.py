"""Tests for migration chain integrity (M1-M3)."""

import importlib.util
from pathlib import Path

VERSIONS_DIR = Path(__file__).resolve().parent.parent / "alembic" / "versions"


def _load_migration(filename: str):
    """Load a migration module by filename."""
    path = VERSIONS_DIR / filename
    spec = importlib.util.spec_from_file_location(filename.removesuffix(".py"), path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def test_migration_0017_exists():
    """M1: migration 0017 (enum unification) exists and has correct revision chain."""
    mod = _load_migration("0017_unify_activity_and_baggage_categories.py")
    assert mod.revision == "0017"
    assert mod.down_revision == "0016"


def test_migration_0018_exists():
    """M2: migration 0018 (TRIP_STARTED) exists and chains from 0017."""
    mod = _load_migration("0018_add_notification_type_trip_started.py")
    assert mod.revision == "0018"
    assert mod.down_revision == "0017"


def test_migration_0019_exists():
    """M3: migration 0019 (date_mode) exists and chains from 0018."""
    mod = _load_migration("0019_add_trip_date_mode.py")
    assert mod.revision == "0019"
    assert mod.down_revision == "0018"


def test_migration_chain_is_linear():
    """The migration chain 0016 → 0017 → 0018 → 0019 is unbroken."""
    m17 = _load_migration("0017_unify_activity_and_baggage_categories.py")
    m18 = _load_migration("0018_add_notification_type_trip_started.py")
    m19 = _load_migration("0019_add_trip_date_mode.py")

    assert m18.down_revision == m17.revision
    assert m19.down_revision == m18.revision

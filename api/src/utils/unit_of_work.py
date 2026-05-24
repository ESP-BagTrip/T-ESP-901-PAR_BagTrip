"""Transactional context manager — `with unit_of_work(db): ...`.

Most services today scatter `db.commit()` calls across their bodies. That
pattern is fine for single-statement operations, but breaks down as soon as an
operation touches multiple rows or models:

- partial state lingers when the second commit fails (the first commit is
  already durable, rollback won't unwind it);
- error paths duplicate `try/except + db.rollback()` boilerplate;
- intent is implicit — nothing in the code tells the reader "these two
  mutations must succeed or fail together".

`unit_of_work` wraps an existing `Session` in a single `try/commit/except
rollback` frame and lets the caller focus on the mutations. The idiom is:

```python
with unit_of_work(db):
    booking.status = "CONFIRMED"
    db.add(BudgetItem(...))
    db.add(FlightOrder(...))
# → one commit at the end, one rollback on any error
```

This is **not** a nested-transaction helper (SQLAlchemy has `begin_nested` for
that). Nested `unit_of_work` calls are allowed but only the outermost commits —
the inner ones become no-ops so services can be composed safely.
"""

from __future__ import annotations

from collections.abc import Iterator
from contextlib import contextmanager

from sqlalchemy.orm import Session

from src.utils.logger import logger


@contextmanager
def unit_of_work(db: Session) -> Iterator[Session]:
    """Commit on success, rollback on any exception.

    Args:
        db: The active SQLAlchemy session. This function does not open a new
            one — it wraps commit/rollback around the caller's existing session
            so the same request-scoped session can flow through several service
            calls.

    Yields:
        The same session, so callers can write `with unit_of_work(db) as s:`
        when they want the explicit name.

    Raises:
        Anything the wrapped block raises, after rolling back.
    """
    # Track whether we are the outermost frame — if the session is already
    # dirty and another unit_of_work is higher in the stack, we should not
    # double-commit. SQLAlchemy's Session.in_transaction() tells us this.
    owns_transaction = not db.in_nested_transaction()

    try:
        yield db
    except Exception as exc:
        logger.warn(
            "unit_of_work rollback",
            {"error_type": type(exc).__name__, "error": str(exc)},
        )
        db.rollback()
        raise
    else:
        if owns_transaction:
            db.commit()

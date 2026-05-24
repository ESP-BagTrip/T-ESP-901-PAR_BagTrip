"""Shared pytest fixtures for the BagTrip backend.

This module is the **single source** of test infrastructure. Previously every
test file rolled its own `mock_db_session`, its own `TestClient`, its own
user/trip builders — leading to drift and a ~60% boilerplate tax on new tests.

Design notes
------------
The codebase uses PostgreSQL-specific SQLAlchemy types (`dialects.postgresql.UUID`
in all 23 models, `dialects.postgresql.JSON` in two). That rules out a
SQLite in-memory session without a brittle type-shim, so we keep the
existing **mock-session** pattern that the 83 pre-existing tests use, but
make it reusable via `mock_db_session`. A real Postgres-backed fixture is
deferred to Sprint 4 (would need docker-compose up in CI, non-trivial).

What this file provides
-----------------------
- **`mock_db_session`** — `MagicMock` with the usual `query().filter().first()`
  chain pre-wired. Override return values per-test.
- **`override_get_db`** — yields `mock_db_session` so FastAPI routes pick it up
  via the `get_db` dependency override.
- **`fastapi_app`** — isolated FastAPI app with only the routers under test
  (subclass this fixture in a per-suite conftest if you need a specific set).
- **`test_client`** — sync `TestClient` for route tests.
- **`async_client`** — `httpx.AsyncClient(transport=ASGITransport)` for async
  route tests and SSE.
- **User / Trip / Activity / Notification factories** — return detached SQLAlchemy
  instances with sane defaults. Override kwargs per-test.
- **`fake_redis`** — dict-backed Redis stand-in for rate limiter, idempotency
  cache and distributed lock tests. Supports `set(NX, EX)`, `get`, `delete`,
  `incr`, `ttl`, `expire`, `pipeline`, `eval` (minimal Lua CAS).
- **`frozen_now`** — returns a helper to monkeypatch `datetime.now(UTC)` and
  `time.monotonic()` deterministically. No new deps (no `freezegun`).
- **`stub_amadeus_service`**, **`stub_llm_service`** — async-capable stubs.
- **`mock_stripe_customer`** — pre-built Stripe customer mock.

Usage
-----
Any test under `api/tests/` can pull these fixtures by name without imports.
Per-directory conftests (e.g. `tests/services/admin/conftest.py`) can layer
domain-specific fixtures on top.
"""

from __future__ import annotations

import importlib.util
import os
import sys
import time
import uuid
from collections.abc import AsyncIterator, Callable, Generator
from datetime import UTC, datetime
from typing import Any
from unittest.mock import AsyncMock, MagicMock

# ---------------------------------------------------------------------------
# Environment bootstrap — MUST run before any `src.*` import.
# ---------------------------------------------------------------------------

# Mock stripe if not installed
if importlib.util.find_spec("stripe") is None:
    sys.modules["stripe"] = MagicMock()

# Dummy env vars to satisfy pydantic-settings validation at import time.
os.environ.setdefault("AMADEUS_CLIENT_ID", "dummy_client_id")
os.environ.setdefault("AMADEUS_CLIENT_SECRET", "dummy_client_secret")
os.environ.setdefault("LLM_API_KEY", "dummy_llm_key")

# ---------------------------------------------------------------------------
# pytest plugins + configuration
# ---------------------------------------------------------------------------

import pytest  # noqa: E402  — must come after env bootstrap
from fastapi import FastAPI  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402
from httpx import ASGITransport, AsyncClient  # noqa: E402

from src.config.database import get_db  # noqa: E402
from src.models.activity import Activity  # noqa: E402
from src.models.notification import Notification  # noqa: E402
from src.models.trip import Trip  # noqa: E402
from src.models.user import User  # noqa: E402

# ---------------------------------------------------------------------------
# Database session mocks
# ---------------------------------------------------------------------------


def _make_query_mock() -> MagicMock:
    """Build a `.query().filter().first()` chain-friendly mock.

    Tests override the terminal methods (`first`, `all`, `count`, `one`) as
    needed — everything in between simply returns the mock itself.
    """
    query = MagicMock(name="Query")
    query.filter.return_value = query
    query.filter_by.return_value = query
    query.join.return_value = query
    query.outerjoin.return_value = query
    query.order_by.return_value = query
    query.group_by.return_value = query
    query.offset.return_value = query
    query.limit.return_value = query
    query.options.return_value = query
    query.distinct.return_value = query
    query.with_entities.return_value = query
    # Defaults — override per test
    query.first.return_value = None
    query.all.return_value = []
    query.count.return_value = 0
    query.scalar.return_value = None
    return query


@pytest.fixture
def mock_db_session() -> MagicMock:
    """Reusable SQLAlchemy `Session` mock with a chain-friendly query API.

    Example:
        def test_foo(mock_db_session):
            user = make_user()
            mock_db_session.query.return_value.filter.return_value.first.return_value = user
            # ... exercise code that calls db.query(User).filter(...).first()
    """
    session = MagicMock(name="Session")
    session.query.return_value = _make_query_mock()
    session.in_nested_transaction.return_value = False
    session.commit = MagicMock(name="commit")
    session.rollback = MagicMock(name="rollback")
    session.flush = MagicMock(name="flush")
    session.refresh = MagicMock(name="refresh")
    session.add = MagicMock(name="add")
    session.delete = MagicMock(name="delete")
    return session


@pytest.fixture
def override_get_db(
    mock_db_session: MagicMock,
) -> Callable[[], Generator[MagicMock]]:
    """Dependency override function to wire `mock_db_session` into FastAPI.

    Usage:
        def test_route(test_client, override_get_db, mock_db_session):
            fastapi_app.dependency_overrides[get_db] = override_get_db
            # ... exercise the route
    """

    def _get_db():
        yield mock_db_session

    return _get_db


# ---------------------------------------------------------------------------
# FastAPI test clients
# ---------------------------------------------------------------------------


@pytest.fixture
def fastapi_app() -> FastAPI:
    """Minimal FastAPI app for standalone route tests.

    Route tests that need a specific router can include it directly:

        def test_foo(fastapi_app):
            fastapi_app.include_router(my_router)
            client = TestClient(fastapi_app)
            ...

    For full-app smoke tests, import `src.main.app` directly instead of using
    this fixture — that one runs the lifespan (Stripe + DB + schedulers) which
    is too heavy for unit tests.
    """
    return FastAPI()


@pytest.fixture
def test_client(
    fastapi_app: FastAPI,
    mock_db_session: MagicMock,
) -> Generator[TestClient]:
    """Sync TestClient with the `get_db` dependency pre-overridden."""

    def _get_db():
        yield mock_db_session

    fastapi_app.dependency_overrides[get_db] = _get_db
    with TestClient(fastapi_app) as client:
        yield client
    fastapi_app.dependency_overrides.clear()


@pytest.fixture
async def async_client(
    fastapi_app: FastAPI,
    mock_db_session: MagicMock,
) -> AsyncIterator[AsyncClient]:
    """Async httpx client for testing async routes and SSE endpoints."""

    def _get_db():
        yield mock_db_session

    fastapi_app.dependency_overrides[get_db] = _get_db
    transport = ASGITransport(app=fastapi_app)
    async with AsyncClient(transport=transport, base_url="http://testserver") as client:
        yield client
    fastapi_app.dependency_overrides.clear()


# ---------------------------------------------------------------------------
# Entity factories — return detached ORM instances
# ---------------------------------------------------------------------------


def _now() -> datetime:
    return datetime.now(UTC)


@pytest.fixture
def make_user() -> Callable[..., User]:
    """Factory for a fully-populated `User` (not attached to a session).

    Override any field via kwargs. Sensible defaults so callers can say
    `make_user()` and get a valid instance.
    """

    def _make_user(**overrides: Any) -> User:
        defaults: dict[str, Any] = {
            "id": uuid.uuid4(),
            "email": f"user-{uuid.uuid4().hex[:8]}@example.com",
            "password_hash": "$2b$12$abcdefghijklmnopqrstuv",
            "full_name": "Test User",
            "phone": None,
            "stripe_customer_id": "cus_test123",
            "plan": "FREE",
            "stripe_subscription_id": None,
            "plan_expires_at": None,
            "ai_generations_count": 0,
            "ai_generations_reset_at": None,
            "banned_at": None,
            "ban_reason": None,
            "deleted_at": None,
            "created_at": _now(),
            "updated_at": _now(),
        }
        defaults.update(overrides)
        return User(**defaults)

    return _make_user


@pytest.fixture
def make_trip() -> Callable[..., Trip]:
    """Factory for a detached `Trip` instance."""

    def _make_trip(**overrides: Any) -> Trip:
        defaults: dict[str, Any] = {
            "id": uuid.uuid4(),
            "user_id": uuid.uuid4(),
            "title": "Test Trip",
            "origin_iata": "CDG",
            "destination_iata": "BCN",
            "destination_name": "Barcelona",
            "status": "PLANNED",
            "budget_target": None,
            "budget_estimated": None,
            "budget_actual": None,
            "nb_travelers": 2,
            "origin": "MANUAL",
            "date_mode": "EXACT",
            "archived_at": None,
            "created_at": _now(),
            "updated_at": _now(),
        }
        defaults.update(overrides)
        return Trip(**defaults)

    return _make_trip


@pytest.fixture
def make_activity() -> Callable[..., Activity]:
    """Factory for a detached `Activity` instance."""

    def _make_activity(**overrides: Any) -> Activity:
        defaults: dict[str, Any] = {
            "id": uuid.uuid4(),
            "trip_id": uuid.uuid4(),
            "title": "Visit Sagrada Familia",
            "description": "Iconic cathedral",
            "date": _now().date(),
            "category": "SIGHTSEEING",
            "estimated_cost": 25.0,
            "is_booked": False,
            "created_at": _now(),
            "updated_at": _now(),
        }
        defaults.update(overrides)
        return Activity(**defaults)

    return _make_activity


@pytest.fixture
def make_notification() -> Callable[..., Notification]:
    """Factory for a detached `Notification` instance."""

    def _make_notification(**overrides: Any) -> Notification:
        defaults: dict[str, Any] = {
            "id": uuid.uuid4(),
            "user_id": uuid.uuid4(),
            "trip_id": None,
            "type": "DEPARTURE_REMINDER",
            "title": "Test Notification",
            "body": "Body text",
            "is_read": False,
            "created_at": _now(),
        }
        defaults.update(overrides)
        return Notification(**defaults)

    return _make_notification


# ---------------------------------------------------------------------------
# Fake Redis — dict-backed, supports the operations rate_limit/idempotency/lock
# actually use. Intentionally tiny — it's a test double, not a Redis clone.
# ---------------------------------------------------------------------------


class _FakePipeline:
    """Minimal pipeline stub — queues commands, executes atomically on .execute()."""

    def __init__(self, redis: FakeRedis):
        self._redis = redis
        self._commands: list[tuple[str, tuple, dict]] = []

    def incr(self, key: str) -> _FakePipeline:
        self._commands.append(("incr", (key,), {}))
        return self

    def expire(self, key: str, seconds: int) -> _FakePipeline:
        self._commands.append(("expire", (key, seconds), {}))
        return self

    def execute(self) -> list[Any]:
        results = []
        for name, args, kwargs in self._commands:
            results.append(getattr(self._redis, name)(*args, **kwargs))
        self._commands.clear()
        return results


class FakeRedis:
    """Dict-backed Redis stub with just enough semantics for tests.

    Supports: `get`, `set` (with NX/EX), `delete`, `incr`, `ttl`, `expire`,
    `pipeline`, `eval` (Lua CAS for lock release only), `ping`. Expirations
    are tracked lazily — fake time is inherited from `time.monotonic()` unless
    `frozen_now` monkeypatches it.
    """

    def __init__(self) -> None:
        self._store: dict[str, tuple[Any, float | None]] = {}

    def _expired(self, key: str) -> bool:
        if key not in self._store:
            return True
        _, deadline = self._store[key]
        if deadline is None:
            return False
        return time.monotonic() > deadline

    def _sweep(self, key: str) -> None:
        if self._expired(key):
            self._store.pop(key, None)

    def ping(self) -> bool:
        return True

    def get(self, key: str) -> Any:
        self._sweep(key)
        if key not in self._store:
            return None
        return self._store[key][0]

    def set(
        self,
        key: str,
        value: Any,
        *,
        nx: bool = False,
        ex: int | None = None,
    ) -> bool | None:
        self._sweep(key)
        if nx and key in self._store:
            return None
        deadline = time.monotonic() + ex if ex is not None else None
        self._store[key] = (value, deadline)
        return True

    def setex(self, key: str, seconds: int, value: Any) -> bool:
        self._store[key] = (value, time.monotonic() + seconds)
        return True

    def delete(self, *keys: str) -> int:
        deleted = 0
        for key in keys:
            if key in self._store:
                del self._store[key]
                deleted += 1
        return deleted

    def incr(self, key: str) -> int:
        self._sweep(key)
        current = int(self._store.get(key, (0, None))[0] or 0)
        current += 1
        # Preserve existing TTL if any
        _, deadline = self._store.get(key, (0, None))
        self._store[key] = (current, deadline)
        return current

    def ttl(self, key: str) -> int:
        self._sweep(key)
        if key not in self._store:
            return -2
        _, deadline = self._store[key]
        if deadline is None:
            return -1
        return max(0, int(deadline - time.monotonic()))

    def expire(self, key: str, seconds: int) -> bool:
        if key not in self._store:
            return False
        value, _ = self._store[key]
        self._store[key] = (value, time.monotonic() + seconds)
        return True

    def pipeline(self) -> _FakePipeline:
        return _FakePipeline(self)

    def eval(self, script: str, numkeys: int, *keys_and_args: Any) -> int:
        """Minimal Lua CAS support for the lock-release script.

        The only script we need to handle is the classic "delete if value
        matches" pattern from `distributed_lock.py`. Anything else raises.
        """
        if numkeys != 1 or len(keys_and_args) < 2:
            raise NotImplementedError("FakeRedis.eval only supports single-key CAS")
        key = keys_and_args[0]
        expected = keys_and_args[1]
        if self.get(key) == expected:
            self.delete(key)
            return 1
        return 0


@pytest.fixture
def fake_redis() -> FakeRedis:
    """Fresh `FakeRedis` per test — no shared state leakage."""
    return FakeRedis()


# ---------------------------------------------------------------------------
# Time freezing — no new dependency, just monkeypatch
# ---------------------------------------------------------------------------


class _FrozenClock:
    """Holds a mutable "now" value and monkey-patches datetime.now + time.monotonic."""

    def __init__(self, monkeypatch: pytest.MonkeyPatch, initial: datetime) -> None:
        self._monkeypatch = monkeypatch
        self._current = initial
        self._monotonic_base = time.monotonic()

    def advance(self, seconds: float) -> None:
        self._current = datetime.fromtimestamp(
            self._current.timestamp() + seconds, tz=self._current.tzinfo
        )
        self._monotonic_base += seconds

    @property
    def now(self) -> datetime:
        return self._current

    def install(self, module_path: str) -> None:
        """Monkey-patch `datetime.now` within a specific module's namespace.

        Usage:
            frozen_now.install("src.services.plan_service")
            # Now every `datetime.now(UTC)` inside plan_service returns frozen value.
        """
        # We can't patch the datetime builtin; patch the module-level reference
        # in whatever module the code under test imports `datetime` from.
        module = sys.modules[module_path]
        original_datetime = module.datetime

        class _FrozenDatetime(original_datetime):
            @classmethod
            def now(cls, tz=None):  # type: ignore[override]
                return self._current if tz is None else self._current.astimezone(tz)

        self._monkeypatch.setattr(module, "datetime", _FrozenDatetime)


@pytest.fixture
def frozen_now(monkeypatch: pytest.MonkeyPatch) -> _FrozenClock:
    """Controllable clock for time-sensitive tests.

    Example:
        def test_quota_window(frozen_now):
            frozen_now.install("src.services.plan_service")
            frozen_now.advance(3600)  # one hour later
    """
    return _FrozenClock(monkeypatch, initial=datetime.now(UTC))


# ---------------------------------------------------------------------------
# Integration stubs
# ---------------------------------------------------------------------------


@pytest.fixture
def stub_amadeus_service() -> MagicMock:
    """AsyncMock for `AmadeusService` methods used across tests.

    Patch into the module under test:
        with patch("src.api.booking.routes.AmadeusService", stub_amadeus_service):
            ...
    """
    service = AsyncMock(name="AmadeusService")
    service.search_flight_offers = AsyncMock(return_value={"data": []})
    service.search_flight_destinations = AsyncMock(return_value={"data": []})
    service.search_flight_cheapest_dates = AsyncMock(return_value={"data": []})
    service.confirm_flight_price = AsyncMock(return_value={"data": {}})
    service.create_flight_order = AsyncMock(return_value=MagicMock(data={"id": "order_test"}))
    service.search_hotel_list = AsyncMock(return_value=MagicMock(data=[]))
    service.search_hotel_offers = AsyncMock(return_value=MagicMock(data=[]))
    return service


@pytest.fixture
def stub_llm_service() -> MagicMock:
    """AsyncMock for `LLMService` — `acall_llm` returns a valid JSON dict."""
    service = MagicMock(name="LLMService")
    service.call_llm = MagicMock(return_value={"destinations": []})
    service.acall_llm = AsyncMock(return_value={"destinations": []})
    service.acall_llm_messages = AsyncMock(return_value={})
    return service


@pytest.fixture
def mock_stripe_customer() -> MagicMock:
    """Pre-built Stripe customer mock returned by `StripeClient.create_customer`."""
    customer = MagicMock(name="StripeCustomer")
    customer.id = "cus_test_12345"
    return customer

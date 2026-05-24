"""Unit tests for ``POST /v1/trips/{tripId}/cover/refresh`` (SMP-330)."""

import uuid
from datetime import UTC, date, datetime
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from src.api.auth.middleware import get_current_user
from src.api.auth.trip_access import TripAccess, TripRole, get_trip_access, get_trip_owner_access
from src.api.trips.routes import router as trips_router
from src.config.database import get_db
from src.integrations.cover_image.types import CoverCandidate
from src.models.user import User
from src.services.cover_image.service import CoverResult
from src.utils.errors import AppError

app = FastAPI()
app.include_router(trips_router)


@app.exception_handler(AppError)
async def app_error_handler(request: Request, exc: AppError):
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": {"error": exc.message, "code": exc.code, **(exc.detail or {})}},
    )


@pytest.fixture
def client():
    with TestClient(app) as c:
        yield c


@pytest.fixture
def mock_db_session():
    return MagicMock()


@pytest.fixture
def override_get_db(mock_db_session):
    def _get_db():
        yield mock_db_session

    app.dependency_overrides[get_db] = _get_db
    yield
    app.dependency_overrides = {}


@pytest.fixture
def mock_user():
    return User(id=uuid.uuid4(), email="user@example.com")


@pytest.fixture
def mock_trip():
    trip = MagicMock()
    trip.id = uuid.uuid4()
    trip.destination_name = "Tokyo"
    trip.destination_iata = "TYO"
    trip.cover_image_url = "https://local/covers/old.jpg"
    trip.cover_image_source = "wikipedia"
    trip.cover_image_candidates = [{"url": "https://local/covers/old.jpg", "source": "wikipedia"}]
    trip.title = "Tokyo Trip"
    trip.origin_iata = "PAR"
    trip.start_date = date(2027, 12, 1)
    trip.end_date = date(2027, 12, 10)
    trip.status = "PLANNED"
    trip.description = None
    trip.destination_timezone = None
    trip.nb_travelers = 1
    trip.budget_target = None
    trip.origin = None
    trip.date_mode = "EXACT"
    trip.flights_tracking = "TRACKED"
    trip.accommodations_tracking = "TRACKED"
    trip.archived_at = None
    trip.role = None
    trip.created_at = datetime.now(UTC)
    trip.updated_at = datetime.now(UTC)
    return trip


@pytest.fixture
def override_trip_owner_access(mock_trip):
    access = TripAccess(trip=mock_trip, role=TripRole.OWNER)
    app.dependency_overrides[get_trip_access] = lambda: access
    app.dependency_overrides[get_trip_owner_access] = lambda: access
    app.dependency_overrides[get_current_user] = lambda: User(
        id=uuid.uuid4(), email="user@example.com"
    )
    yield
    app.dependency_overrides = {}


def _result(primary_url: str = "https://local/covers/new.jpg") -> CoverResult:
    return CoverResult(
        primary_url=primary_url,
        primary_source="wikipedia",
        candidates=[
            CoverCandidate(url=primary_url, source="wikipedia", title="new"),
            CoverCandidate(
                url="https://local/covers/alt.jpg", source="commons_geo", title="alt"
            ),
        ],
    )


def test_refresh_succeeds_and_writes_new_cover(
    client, override_get_db, override_trip_owner_access, mock_trip, mock_db_session
):
    with (
        patch(
            "src.api.trips.routes.cover_image_service.refresh_cover",
            AsyncMock(return_value=_result()),
        ),
        patch(
            "src.api.trips.routes.TripsService.compute_completion_batch",
            return_value={mock_trip.id: 50},
        ),
    ):
        resp = client.post(f"/v1/trips/{mock_trip.id}/cover/refresh")

    assert resp.status_code == 200, resp.json()
    body = resp.json()
    assert body["cover_image_url"] == "https://local/covers/new.jpg", body
    assert body["cover_image_source"] == "wikipedia"
    assert len(body["cover_image_candidates"]) == 2
    # The trip object was mutated in-place before commit.
    assert mock_trip.cover_image_url == "https://local/covers/new.jpg"
    mock_db_session.commit.assert_called_once()


def test_refresh_404_when_no_candidates(
    client, override_get_db, override_trip_owner_access
):
    with patch(
        "src.api.trips.routes.cover_image_service.refresh_cover",
        AsyncMock(return_value=None),
    ):
        resp = client.post(
            f"/v1/trips/{uuid.uuid4()}/cover/refresh"
        )

    assert resp.status_code == 404
    assert resp.json()["detail"]["code"] == "COVER_NO_CANDIDATES"


def test_refresh_400_when_trip_has_no_destination(
    client, override_get_db, mock_trip
):
    mock_trip.destination_name = None
    mock_trip.destination_iata = None
    access = TripAccess(trip=mock_trip, role=TripRole.OWNER)
    app.dependency_overrides[get_trip_access] = lambda: access
    app.dependency_overrides[get_trip_owner_access] = lambda: access
    app.dependency_overrides[get_current_user] = lambda: User(
        id=uuid.uuid4(), email="u@example.com"
    )
    try:
        resp = client.post(f"/v1/trips/{mock_trip.id}/cover/refresh")
    finally:
        app.dependency_overrides = {}

    assert resp.status_code == 400
    assert resp.json()["detail"]["code"] == "TRIP_DESTINATION_MISSING"


def test_refresh_passes_existing_urls_as_exclude_set(
    client, override_get_db, override_trip_owner_access, mock_trip
):
    refresh_mock = AsyncMock(return_value=_result())
    with (
        patch(
            "src.api.trips.routes.cover_image_service.refresh_cover", refresh_mock
        ),
        patch(
            "src.api.trips.routes.TripsService.compute_completion_batch",
            return_value={mock_trip.id: 0},
        ),
    ):
        client.post(f"/v1/trips/{mock_trip.id}/cover/refresh")

    _, kwargs = refresh_mock.call_args
    exclude = kwargs["exclude_urls"]
    # Both the current cover URL and the existing candidate URL should be
    # in the exclusion set so the user doesn't see them again.
    assert "https://local/covers/old.jpg" in exclude

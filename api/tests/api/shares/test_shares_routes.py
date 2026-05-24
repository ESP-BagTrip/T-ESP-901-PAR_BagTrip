"""Route tests for shares/routes.py — share create/list/delete + pending invites."""

import uuid
from datetime import UTC, datetime, timedelta
from unittest.mock import MagicMock, patch

import pytest
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from src.api.auth.trip_access import (
    TripAccess,
    TripRole,
    get_trip_access,
    get_trip_owner_access,
)
from src.api.shares.routes import router as shares_router
from src.config.database import get_db
from src.utils.errors import AppError


@pytest.fixture
def mock_db() -> MagicMock:
    return MagicMock()


@pytest.fixture
def trip_id() -> uuid.UUID:
    return uuid.uuid4()


@pytest.fixture
def owner_user_id() -> uuid.UUID:
    return uuid.uuid4()


@pytest.fixture
def app(mock_db: MagicMock, trip_id: uuid.UUID, owner_user_id: uuid.UUID) -> FastAPI:
    app = FastAPI()
    app.include_router(shares_router)

    trip = MagicMock()
    trip.id = trip_id
    trip.user_id = owner_user_id
    access = TripAccess(trip=trip, role=TripRole.OWNER)

    app.dependency_overrides[get_trip_owner_access] = lambda: access
    app.dependency_overrides[get_trip_access] = lambda: access
    app.dependency_overrides[get_db] = lambda: mock_db

    @app.exception_handler(AppError)
    async def _handle_app_error(_: Request, exc: AppError) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content={"detail": {"error": exc.message, "code": exc.code}},
        )

    return app


@pytest.fixture
def client(app: FastAPI) -> TestClient:
    return TestClient(app)


def _share_dict(trip_id: uuid.UUID, **overrides):
    base = {
        "id": uuid.uuid4(),
        "trip_id": trip_id,
        "user_id": uuid.uuid4(),
        "role": "VIEWER",
        "invited_at": datetime.now(UTC),
        "user_email": "viewer@example.com",
        "user_full_name": "Viewer User",
    }
    base.update(overrides)
    return base


def _pending_dict(trip_id: uuid.UUID, **overrides):
    base = {
        "id": uuid.uuid4(),
        "trip_id": trip_id,
        "email": "pending@example.com",
        "role": "VIEWER",
        "token": "tok-xyz",
        "created_at": datetime.now(UTC),
        "expires_at": datetime.now(UTC) + timedelta(days=7),
    }
    base.update(overrides)
    return base


class TestCreateShare:
    def test_success_active(self, client: TestClient, trip_id: uuid.UUID) -> None:
        share = _share_dict(trip_id, status="active", invite_token=None)
        with patch(
            "src.api.shares.routes.TripShareService.create_share",
            return_value=share,
        ) as mocked:
            response = client.post(
                f"/v1/trips/{trip_id}/shares",
                json={"email": "viewer@example.com", "role": "VIEWER"},
            )
        assert response.status_code == 201
        body = response.json()
        assert body["user_email"] == "viewer@example.com"
        mocked.assert_called_once()

    def test_quota_exceeded(self, client: TestClient, trip_id: uuid.UUID) -> None:
        with patch(
            "src.api.shares.routes.TripShareService.create_share",
            side_effect=AppError("QUOTA_EXCEEDED", 403, "Too many viewers"),
        ):
            response = client.post(
                f"/v1/trips/{trip_id}/shares",
                json={"email": "viewer@example.com", "role": "VIEWER"},
            )
        assert response.status_code == 403
        assert response.json()["detail"]["code"] == "QUOTA_EXCEEDED"


class TestListShares:
    def test_owner_sees_pending(self, client: TestClient, trip_id: uuid.UUID) -> None:
        shares = [_share_dict(trip_id)]
        pending = [_pending_dict(trip_id)]
        with (
            patch(
                "src.api.shares.routes.TripShareService.get_shares_by_trip",
                return_value=shares,
            ),
            patch(
                "src.api.shares.routes.TripShareService.get_pending_invites_by_trip",
                return_value=pending,
            ),
        ):
            response = client.get(f"/v1/trips/{trip_id}/shares")
        assert response.status_code == 200
        body = response.json()
        assert len(body["items"]) == 1
        assert len(body["pendingInvites"]) == 1

    def test_viewer_no_pending(
        self, app: FastAPI, trip_id: uuid.UUID, owner_user_id: uuid.UUID
    ) -> None:
        trip = MagicMock()
        trip.id = trip_id
        trip.user_id = owner_user_id
        viewer_access = TripAccess(trip=trip, role=TripRole.VIEWER)
        app.dependency_overrides[get_trip_access] = lambda: viewer_access
        client = TestClient(app)

        shares = [_share_dict(trip_id)]
        with (
            patch(
                "src.api.shares.routes.TripShareService.get_shares_by_trip",
                return_value=shares,
            ),
            patch(
                "src.api.shares.routes.TripShareService.get_pending_invites_by_trip",
            ) as pending_mock,
        ):
            response = client.get(f"/v1/trips/{trip_id}/shares")
        assert response.status_code == 200
        assert response.json()["pendingInvites"] == []
        pending_mock.assert_not_called()


class TestDeleteShare:
    def test_success(self, client: TestClient, trip_id: uuid.UUID) -> None:
        share_id = uuid.uuid4()
        with patch(
            "src.api.shares.routes.TripShareService.delete_share",
            return_value=None,
        ) as mocked:
            response = client.delete(f"/v1/trips/{trip_id}/shares/{share_id}")
        assert response.status_code == 204
        mocked.assert_called_once()

    def test_not_found(self, client: TestClient, trip_id: uuid.UUID) -> None:
        share_id = uuid.uuid4()
        with patch(
            "src.api.shares.routes.TripShareService.delete_share",
            side_effect=AppError("SHARE_NOT_FOUND", 404, "Not found"),
        ):
            response = client.delete(f"/v1/trips/{trip_id}/shares/{share_id}")
        assert response.status_code == 404


class TestDeletePendingInvite:
    def test_success(self, client: TestClient, trip_id: uuid.UUID) -> None:
        invite_id = uuid.uuid4()
        with patch(
            "src.api.shares.routes.TripShareService.delete_pending_invite",
            return_value=None,
        ) as mocked:
            response = client.delete(f"/v1/trips/{trip_id}/pending-invites/{invite_id}")
        assert response.status_code == 204
        mocked.assert_called_once()

    def test_not_found(self, client: TestClient, trip_id: uuid.UUID) -> None:
        with patch(
            "src.api.shares.routes.TripShareService.delete_pending_invite",
            side_effect=AppError("INVITE_NOT_FOUND", 404, "Not found"),
        ):
            response = client.delete(f"/v1/trips/{trip_id}/pending-invites/{uuid.uuid4()}")
        assert response.status_code == 404

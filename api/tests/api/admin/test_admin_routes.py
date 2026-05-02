"""Tests pour les routes admin."""

from datetime import UTC, datetime
from unittest.mock import MagicMock, patch
from uuid import uuid4

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from src.api.admin.routes import router as admin_router
from src.api.auth.middleware import get_current_user
from src.utils.errors import AppError

# Setup test app
app = FastAPI()
app.include_router(admin_router)


# Mock dependencies
@pytest.fixture
def mock_db():
    return MagicMock()


@pytest.fixture
def mock_current_user():
    return MagicMock(id=uuid4(), email="admin@example.com", is_admin=True, plan="ADMIN")


@pytest.fixture
def client(mock_db, mock_current_user):
    # Override dependencies
    from src.api.auth.admin_guard import require_admin
    from src.config.database import get_db

    app.dependency_overrides[get_current_user] = lambda: mock_current_user
    app.dependency_overrides[require_admin] = lambda: mock_current_user
    app.dependency_overrides[get_db] = lambda: mock_db

    with TestClient(app) as c:
        yield c

    # Clean up overrides
    app.dependency_overrides = {}


@pytest.fixture
def mock_admin_service():
    with patch("src.api.admin.routes.AdminService") as mock:
        yield mock


class TestAdminRoutes:
    """Tests pour les routes admin."""

    def test_admin_health(self, client):
        """Test du health check admin."""
        response = client.get("/admin/health")
        assert response.status_code == 200
        assert response.json() == {"status": "ok", "message": "Admin routes are working"}

    def test_list_all_users_success(self, client, mock_admin_service):
        """Test listing users successfully."""
        user_id = uuid4()
        now = datetime.now(UTC)
        mock_data = [
            {"id": user_id, "email": "user@example.com", "created_at": now, "updated_at": now}
        ]
        mock_admin_service.get_all_users.return_value = (mock_data, 1, 1)

        response = client.get("/admin/users?page=1&limit=10")

        assert response.status_code == 200
        data = response.json()
        assert data["items"][0]["id"] == str(user_id)
        assert data["total"] == 1
        assert data["page"] == 1
        assert data["limit"] == 10
        assert data["total_pages"] == 1
        mock_admin_service.get_all_users.assert_called_once()

    def test_list_all_users_error(self, client, mock_admin_service):
        """Test listing users with service error."""
        mock_admin_service.get_all_users.side_effect = AppError("DB_ERROR", 500, "Database error")

        response = client.get("/admin/users")

        assert response.status_code == 500
        assert response.json()["detail"]["error"] == "Database error"

    def test_list_all_users_generic_error(self, client, mock_admin_service):
        """Test listing users with generic error."""
        mock_admin_service.get_all_users.side_effect = Exception("Unexpected error")

        response = client.get("/admin/users")

        assert response.status_code == 500
        assert "Failed to fetch users" in response.json()["detail"]["error"]

    def test_list_all_trips_success(self, client, mock_admin_service):
        """Test listing trips successfully."""
        trip_id = uuid4()
        user_id = uuid4()
        now = datetime.now(UTC)
        mock_data = [
            {
                "id": trip_id,
                "user_id": user_id,
                "user_email": "user@example.com",
                "title": "Trip 1",
                "created_at": now,
                "updated_at": now,
            }
        ]
        mock_admin_service.get_all_trips.return_value = (mock_data, 1, 1)

        response = client.get("/admin/trips")

        assert response.status_code == 200
        data = response.json()
        assert data["items"][0]["id"] == str(trip_id)
        mock_admin_service.get_all_trips.assert_called_once()

    def test_list_all_trips_error(self, client, mock_admin_service):
        """Test listing trips with error."""
        mock_admin_service.get_all_trips.side_effect = Exception("Fail")
        response = client.get("/admin/trips")
        assert response.status_code == 500
        assert "Failed to fetch trips" in response.json()["detail"]["error"]

    def test_list_all_travelers_success(self, client, mock_admin_service):
        """Test listing travelers successfully."""
        traveler_id = uuid4()
        trip_id = uuid4()
        now = datetime.now(UTC)
        mock_data = [
            {
                "id": traveler_id,
                "trip_id": trip_id,
                "user_email": "user@example.com",
                "traveler_type": "ADULT",
                "first_name": "John",
                "last_name": "Doe",
                "created_at": now,
                "updated_at": now,
            }
        ]
        mock_admin_service.get_all_travelers.return_value = (mock_data, 1, 1)

        response = client.get("/admin/travelers")

        assert response.status_code == 200
        data = response.json()
        assert data["items"][0]["id"] == str(traveler_id)
        mock_admin_service.get_all_travelers.assert_called_once()

    def test_list_all_travelers_error(self, client, mock_admin_service):
        """Test listing travelers with error."""
        mock_admin_service.get_all_travelers.side_effect = Exception("Fail")
        response = client.get("/admin/travelers")
        assert response.status_code == 500
        assert "Failed to fetch travelers" in response.json()["detail"]["error"]

    def test_list_all_flight_bookings_success(self, client, mock_admin_service):
        """Test listing flight bookings successfully."""
        booking_id = uuid4()
        trip_id = uuid4()
        offer_id = uuid4()
        now = datetime.now(UTC)
        mock_data = [
            {
                "id": booking_id,
                "trip_id": trip_id,
                "user_email": "user@example.com",
                "flight_offer_id": offer_id,
                "created_at": now,
                "updated_at": now,
            }
        ]
        mock_admin_service.get_all_flight_bookings.return_value = (mock_data, 1, 1)

        response = client.get("/admin/flight-bookings")

        assert response.status_code == 200
        data = response.json()
        assert data["items"][0]["id"] == str(booking_id)
        mock_admin_service.get_all_flight_bookings.assert_called_once()

    def test_list_all_flight_bookings_error(self, client, mock_admin_service):
        """Test listing flight bookings with error."""
        mock_admin_service.get_all_flight_bookings.side_effect = Exception("Fail")
        response = client.get("/admin/flight-bookings")
        assert response.status_code == 500
        assert "Failed to fetch flight bookings" in response.json()["detail"]["error"]

    # ──────────────────────── Additional list_all_* happy paths ───────────
    # These routes delegate 1:1 to `AdminService.get_all_*`. Returning an
    # empty tuple (items=[], total=0, total_pages=0) is enough to hit the
    # handler body + response mapping, without fabricating schema-complete
    # dict fixtures per endpoint.

    def test_list_all_traveler_profiles_success(self, client, mock_admin_service):
        mock_admin_service.get_all_traveler_profiles.return_value = ([], 0, 0)
        response = client.get("/admin/traveler-profiles")
        assert response.status_code == 200
        assert response.json()["total"] == 0
        mock_admin_service.get_all_traveler_profiles.assert_called_once()

    def test_list_all_traveler_profiles_error(self, client, mock_admin_service):
        mock_admin_service.get_all_traveler_profiles.side_effect = Exception("Fail")
        response = client.get("/admin/traveler-profiles")
        assert response.status_code == 500

    def test_list_all_booking_intents_success(self, client, mock_admin_service):
        mock_admin_service.get_all_booking_intents.return_value = ([], 0, 0)
        response = client.get("/admin/booking-intents")
        assert response.status_code == 200
        mock_admin_service.get_all_booking_intents.assert_called_once()

    def test_list_all_booking_intents_error(self, client, mock_admin_service):
        mock_admin_service.get_all_booking_intents.side_effect = Exception("Fail")
        response = client.get("/admin/booking-intents")
        assert response.status_code == 500

    def test_list_all_flight_searches_success(self, client, mock_admin_service):
        mock_admin_service.get_all_flight_searches.return_value = ([], 0, 0)
        response = client.get("/admin/flight-searches")
        assert response.status_code == 200
        mock_admin_service.get_all_flight_searches.assert_called_once()

    def test_list_all_flight_searches_error(self, client, mock_admin_service):
        mock_admin_service.get_all_flight_searches.side_effect = Exception("Fail")
        response = client.get("/admin/flight-searches")
        assert response.status_code == 500

    def test_list_all_accommodations_success(self, client, mock_admin_service):
        mock_admin_service.get_all_accommodations.return_value = ([], 0, 0)
        response = client.get("/admin/accommodations")
        assert response.status_code == 200
        mock_admin_service.get_all_accommodations.assert_called_once()

    def test_list_all_accommodations_error(self, client, mock_admin_service):
        mock_admin_service.get_all_accommodations.side_effect = Exception("Fail")
        response = client.get("/admin/accommodations")
        assert response.status_code == 500

    def test_list_all_activities_success(self, client, mock_admin_service):
        mock_admin_service.get_all_activities.return_value = ([], 0, 0)
        response = client.get("/admin/activities")
        assert response.status_code == 200
        mock_admin_service.get_all_activities.assert_called_once()

    def test_list_all_activities_error(self, client, mock_admin_service):
        mock_admin_service.get_all_activities.side_effect = Exception("Fail")
        response = client.get("/admin/activities")
        assert response.status_code == 500

    def test_list_all_budget_items_success(self, client, mock_admin_service):
        mock_admin_service.get_all_budget_items.return_value = ([], 0, 0)
        response = client.get("/admin/budget-items")
        assert response.status_code == 200
        mock_admin_service.get_all_budget_items.assert_called_once()

    def test_list_all_budget_items_error(self, client, mock_admin_service):
        mock_admin_service.get_all_budget_items.side_effect = Exception("Fail")
        response = client.get("/admin/budget-items")
        assert response.status_code == 500

    def test_list_all_baggage_items_success(self, client, mock_admin_service):
        mock_admin_service.get_all_baggage_items.return_value = ([], 0, 0)
        response = client.get("/admin/baggage-items")
        assert response.status_code == 200
        mock_admin_service.get_all_baggage_items.assert_called_once()

    def test_list_all_baggage_items_error(self, client, mock_admin_service):
        mock_admin_service.get_all_baggage_items.side_effect = Exception("Fail")
        response = client.get("/admin/baggage-items")
        assert response.status_code == 500

    def test_list_all_trip_shares_success(self, client, mock_admin_service):
        mock_admin_service.get_all_trip_shares.return_value = ([], 0, 0)
        response = client.get("/admin/trip-shares")
        assert response.status_code == 200
        mock_admin_service.get_all_trip_shares.assert_called_once()

    def test_list_all_trip_shares_error(self, client, mock_admin_service):
        mock_admin_service.get_all_trip_shares.side_effect = Exception("Fail")
        response = client.get("/admin/trip-shares")
        assert response.status_code == 500

    def test_list_all_feedbacks_success(self, client, mock_admin_service):
        mock_admin_service.get_all_feedbacks.return_value = ([], 0, 0)
        response = client.get("/admin/feedbacks")
        assert response.status_code == 200
        mock_admin_service.get_all_feedbacks.assert_called_once()

    def test_list_all_feedbacks_error(self, client, mock_admin_service):
        mock_admin_service.get_all_feedbacks.side_effect = Exception("Fail")
        response = client.get("/admin/feedbacks")
        assert response.status_code == 500

    def test_list_all_notifications_success(self, client, mock_admin_service):
        mock_admin_service.get_all_notifications.return_value = ([], 0, 0)
        response = client.get("/admin/notifications")
        assert response.status_code == 200
        mock_admin_service.get_all_notifications.assert_called_once()

    def test_list_all_notifications_error(self, client, mock_admin_service):
        mock_admin_service.get_all_notifications.side_effect = Exception("Fail")
        response = client.get("/admin/notifications")
        assert response.status_code == 500

    # ──────────────────────── Management endpoints ───────────────────────

    def test_delete_feedback_success(self, client, mock_admin_service):
        mock_admin_service.delete_feedback.return_value = None
        response = client.delete(f"/admin/feedbacks/{uuid4()}")
        assert response.status_code == 204
        mock_admin_service.delete_feedback.assert_called_once()

    def test_delete_feedback_error(self, client, mock_admin_service):
        mock_admin_service.delete_feedback.side_effect = Exception("Fail")
        response = client.delete(f"/admin/feedbacks/{uuid4()}")
        assert response.status_code == 500

    def test_update_user_plan_success(self, client, mock_admin_service):
        mock_admin_service.update_user_plan.return_value = None
        response = client.patch(
            f"/admin/users/{uuid4()}/plan",
            json={"plan": "PREMIUM"},
        )
        assert response.status_code == 200
        assert response.json()["plan"] == "PREMIUM"

    def test_update_user_plan_error(self, client, mock_admin_service):
        mock_admin_service.update_user_plan.side_effect = Exception("Fail")
        response = client.patch(
            f"/admin/users/{uuid4()}/plan",
            json={"plan": "PREMIUM"},
        )
        assert response.status_code == 500

    def test_get_user_detail_success(self, client, mock_admin_service):
        user_id = uuid4()
        now = datetime.now(UTC)
        mock_admin_service.get_user_detail.return_value = {
            "id": user_id,
            "email": "user@example.com",
            "created_at": now,
        }
        response = client.get(f"/admin/users/{user_id}")
        assert response.status_code == 200
        assert response.json()["id"] == str(user_id)

    def test_get_user_detail_error(self, client, mock_admin_service):
        mock_admin_service.get_user_detail.side_effect = Exception("Fail")
        response = client.get(f"/admin/users/{uuid4()}")
        assert response.status_code == 500

    def test_update_user_success(self, client, mock_admin_service):
        mock_admin_service.update_user.return_value = None
        response = client.patch(
            f"/admin/users/{uuid4()}",
            json={"full_name": "New Name"},
        )
        assert response.status_code == 200

    def test_update_user_error(self, client, mock_admin_service):
        mock_admin_service.update_user.side_effect = Exception("Fail")
        response = client.patch(
            f"/admin/users/{uuid4()}",
            json={"full_name": "X"},
        )
        assert response.status_code == 500

    def test_reset_ai_quota_success(self, client, mock_admin_service):
        mock_admin_service.reset_ai_quota.return_value = None
        response = client.patch(f"/admin/users/{uuid4()}/ai-quota/reset")
        assert response.status_code == 200

    def test_reset_ai_quota_error(self, client, mock_admin_service):
        mock_admin_service.reset_ai_quota.side_effect = Exception("Fail")
        response = client.patch(f"/admin/users/{uuid4()}/ai-quota/reset")
        assert response.status_code == 500

    def test_ban_user_success(self, client, mock_admin_service):
        mock_admin_service.ban_user.return_value = None
        response = client.post(
            f"/admin/users/{uuid4()}/ban",
            json={"reason": "spam"},
        )
        assert response.status_code == 200

    def test_ban_user_error(self, client, mock_admin_service):
        mock_admin_service.ban_user.side_effect = Exception("Fail")
        response = client.post(
            f"/admin/users/{uuid4()}/ban",
            json={"reason": "spam"},
        )
        assert response.status_code == 500

    def test_unban_user_success(self, client, mock_admin_service):
        mock_admin_service.unban_user.return_value = None
        response = client.post(f"/admin/users/{uuid4()}/unban")
        assert response.status_code == 200

    def test_unban_user_error(self, client, mock_admin_service):
        mock_admin_service.unban_user.side_effect = Exception("Fail")
        response = client.post(f"/admin/users/{uuid4()}/unban")
        assert response.status_code == 500

    def test_delete_user_success(self, client, mock_admin_service):
        mock_admin_service.delete_user.return_value = None
        response = client.delete(f"/admin/users/{uuid4()}")
        assert response.status_code == 200

    def test_delete_user_error(self, client, mock_admin_service):
        mock_admin_service.delete_user.side_effect = Exception("Fail")
        response = client.delete(f"/admin/users/{uuid4()}")
        assert response.status_code == 500

    def test_bulk_change_plan_success(self, client, mock_admin_service):
        mock_admin_service.bulk_update_plan.return_value = 2
        response = client.post(
            "/admin/users/bulk/plan",
            json={"user_ids": [str(uuid4()), str(uuid4())], "plan": "PREMIUM"},
        )
        assert response.status_code == 200
        assert response.json()["count"] == 2

    def test_bulk_change_plan_error(self, client, mock_admin_service):
        mock_admin_service.bulk_update_plan.side_effect = Exception("Fail")
        response = client.post(
            "/admin/users/bulk/plan",
            json={"user_ids": [str(uuid4())], "plan": "PREMIUM"},
        )
        assert response.status_code == 500

    # NOTE: POST /admin/users/bulk/ban is shadowed by POST /admin/users/{userId}/ban
    # ({userId} is typed UUID and "bulk" fails parsing → 422). Effectively unreachable
    # via TestClient, not tested here.

    def test_get_trip_detail_success(self, client, mock_admin_service):
        trip_id = uuid4()
        user_id = uuid4()
        now = datetime.now(UTC)
        mock_admin_service.get_trip_detail.return_value = {
            "id": trip_id,
            "user_id": user_id,
            "user_email": "u@example.com",
            "created_at": now,
            "updated_at": now,
        }
        response = client.get(f"/admin/trips/{trip_id}")
        assert response.status_code == 200

    def test_get_trip_detail_error(self, client, mock_admin_service):
        mock_admin_service.get_trip_detail.side_effect = Exception("Fail")
        response = client.get(f"/admin/trips/{uuid4()}")
        assert response.status_code == 500

    def test_update_trip_success(self, client, mock_admin_service):
        mock_admin_service.update_trip.return_value = None
        response = client.patch(
            f"/admin/trips/{uuid4()}",
            json={"title": "New Title"},
        )
        assert response.status_code == 200

    def test_update_trip_error(self, client, mock_admin_service):
        mock_admin_service.update_trip.side_effect = Exception("Fail")
        response = client.patch(
            f"/admin/trips/{uuid4()}",
            json={"title": "New"},
        )
        assert response.status_code == 500

    def test_delete_trip_success(self, client, mock_admin_service):
        mock_admin_service.delete_trip.return_value = None
        response = client.delete(f"/admin/trips/{uuid4()}")
        assert response.status_code == 204

    def test_delete_trip_error(self, client, mock_admin_service):
        mock_admin_service.delete_trip.side_effect = Exception("Fail")
        response = client.delete(f"/admin/trips/{uuid4()}")
        assert response.status_code == 500

    def test_archive_trip_success(self, client, mock_admin_service):
        mock_admin_service.archive_trip.return_value = None
        response = client.patch(f"/admin/trips/{uuid4()}/archive")
        assert response.status_code == 200

    def test_archive_trip_error(self, client, mock_admin_service):
        mock_admin_service.archive_trip.side_effect = Exception("Fail")
        response = client.patch(f"/admin/trips/{uuid4()}/archive")
        assert response.status_code == 500

    def test_get_booking_intent_detail_success(self, client, mock_admin_service):
        mock_admin_service.get_booking_intent_detail.return_value = {"id": "abc"}
        response = client.get(f"/admin/booking-intents/{uuid4()}/detail")
        assert response.status_code == 200

    def test_get_booking_intent_detail_error(self, client, mock_admin_service):
        mock_admin_service.get_booking_intent_detail.side_effect = Exception("Fail")
        response = client.get(f"/admin/booking-intents/{uuid4()}/detail")
        assert response.status_code == 500

    def test_force_booking_status_success(self, client, mock_admin_service):
        mock_admin_service.force_booking_status.return_value = None
        response = client.patch(
            f"/admin/booking-intents/{uuid4()}/status",
            json={"status": "BOOKED"},
        )
        assert response.status_code == 200

    def test_force_booking_status_error(self, client, mock_admin_service):
        mock_admin_service.force_booking_status.side_effect = Exception("Fail")
        response = client.patch(
            f"/admin/booking-intents/{uuid4()}/status",
            json={"status": "BOOKED"},
        )
        assert response.status_code == 500

    def test_cancel_booking_success(self, client, mock_admin_service):
        mock_admin_service.force_booking_status.return_value = None
        response = client.post(f"/admin/booking-intents/{uuid4()}/cancel")
        assert response.status_code == 200

    def test_cancel_booking_error(self, client, mock_admin_service):
        mock_admin_service.force_booking_status.side_effect = Exception("Fail")
        response = client.post(f"/admin/booking-intents/{uuid4()}/cancel")
        assert response.status_code == 500

    def test_mark_refunded_success(self, client, mock_admin_service):
        mock_admin_service.force_booking_status.return_value = None
        response = client.post(f"/admin/booking-intents/{uuid4()}/refund")
        assert response.status_code == 200

    def test_mark_refunded_error(self, client, mock_admin_service):
        mock_admin_service.force_booking_status.side_effect = Exception("Fail")
        response = client.post(f"/admin/booking-intents/{uuid4()}/refund")
        assert response.status_code == 500

    def test_admin_create_activity_success(self, client, mock_admin_service):
        activity_id = uuid4()
        mock_admin_service.create_activity.return_value = MagicMock(id=activity_id)
        response = client.post(
            f"/admin/trips/{uuid4()}/activities",
            json={"title": "Visit", "date": "2026-05-12"},
        )
        assert response.status_code == 200

    def test_admin_create_activity_error(self, client, mock_admin_service):
        mock_admin_service.create_activity.side_effect = Exception("Fail")
        response = client.post(
            f"/admin/trips/{uuid4()}/activities",
            json={"title": "X", "date": "2026-05-12"},
        )
        assert response.status_code == 500

    def test_admin_update_activity_success(self, client, mock_admin_service):
        mock_admin_service.update_activity.return_value = None
        response = client.patch(
            f"/admin/trips/{uuid4()}/activities/{uuid4()}",
            json={"title": "Updated"},
        )
        assert response.status_code == 200

    def test_admin_update_activity_error(self, client, mock_admin_service):
        mock_admin_service.update_activity.side_effect = Exception("Fail")
        response = client.patch(
            f"/admin/trips/{uuid4()}/activities/{uuid4()}",
            json={"title": "X"},
        )
        assert response.status_code == 500

    def test_admin_delete_activity_success(self, client, mock_admin_service):
        mock_admin_service.delete_activity.return_value = None
        response = client.delete(f"/admin/trips/{uuid4()}/activities/{uuid4()}")
        assert response.status_code == 204

    def test_admin_delete_activity_error(self, client, mock_admin_service):
        mock_admin_service.delete_activity.side_effect = Exception("Fail")
        response = client.delete(f"/admin/trips/{uuid4()}/activities/{uuid4()}")
        assert response.status_code == 500

    def test_admin_create_accommodation_success(self, client, mock_admin_service):
        acc_id = uuid4()
        mock_admin_service.create_accommodation.return_value = MagicMock(id=acc_id)
        response = client.post(
            f"/admin/trips/{uuid4()}/accommodations",
            json={"name": "Hotel"},
        )
        assert response.status_code == 200

    def test_admin_create_accommodation_error(self, client, mock_admin_service):
        mock_admin_service.create_accommodation.side_effect = Exception("Fail")
        response = client.post(
            f"/admin/trips/{uuid4()}/accommodations",
            json={"name": "Hotel"},
        )
        assert response.status_code == 500

    def test_admin_update_accommodation_success(self, client, mock_admin_service):
        mock_admin_service.update_accommodation.return_value = None
        response = client.patch(
            f"/admin/trips/{uuid4()}/accommodations/{uuid4()}",
            json={"name": "Updated"},
        )
        assert response.status_code == 200

    def test_admin_update_accommodation_error(self, client, mock_admin_service):
        mock_admin_service.update_accommodation.side_effect = Exception("Fail")
        response = client.patch(
            f"/admin/trips/{uuid4()}/accommodations/{uuid4()}",
            json={"name": "X"},
        )
        assert response.status_code == 500

    def test_admin_delete_accommodation_success(self, client, mock_admin_service):
        mock_admin_service.delete_accommodation.return_value = None
        response = client.delete(f"/admin/trips/{uuid4()}/accommodations/{uuid4()}")
        assert response.status_code == 204

    def test_admin_delete_accommodation_error(self, client, mock_admin_service):
        mock_admin_service.delete_accommodation.side_effect = Exception("Fail")
        response = client.delete(f"/admin/trips/{uuid4()}/accommodations/{uuid4()}")
        assert response.status_code == 500

    def test_admin_delete_budget_item_success(self, client, mock_admin_service):
        mock_admin_service.delete_budget_item.return_value = None
        response = client.delete(f"/admin/trips/{uuid4()}/budget-items/{uuid4()}")
        assert response.status_code == 204

    def test_admin_delete_budget_item_error(self, client, mock_admin_service):
        mock_admin_service.delete_budget_item.side_effect = Exception("Fail")
        response = client.delete(f"/admin/trips/{uuid4()}/budget-items/{uuid4()}")
        assert response.status_code == 500

    def test_admin_delete_baggage_item_success(self, client, mock_admin_service):
        mock_admin_service.delete_baggage_item.return_value = None
        response = client.delete(f"/admin/trips/{uuid4()}/baggage/{uuid4()}")
        assert response.status_code == 204

    def test_admin_delete_baggage_item_error(self, client, mock_admin_service):
        mock_admin_service.delete_baggage_item.side_effect = Exception("Fail")
        response = client.delete(f"/admin/trips/{uuid4()}/baggage/{uuid4()}")
        assert response.status_code == 500

    def test_admin_delete_share_success(self, client, mock_admin_service):
        mock_admin_service.delete_share.return_value = None
        response = client.delete(f"/admin/trips/{uuid4()}/shares/{uuid4()}")
        assert response.status_code == 204

    def test_admin_delete_share_error(self, client, mock_admin_service):
        mock_admin_service.delete_share.side_effect = Exception("Fail")
        response = client.delete(f"/admin/trips/{uuid4()}/shares/{uuid4()}")
        assert response.status_code == 500

    def test_list_audit_logs_success(self, client):
        with patch("src.services.audit_service.AuditService.get_logs") as mock_logs:
            mock_logs.return_value = ([], 0, 0)
            response = client.get("/admin/audit-logs")
        assert response.status_code == 200
        assert response.json()["total"] == 0

    def test_list_audit_logs_error(self, client):
        with patch("src.services.audit_service.AuditService.get_logs") as mock_logs:
            mock_logs.side_effect = Exception("Fail")
            response = client.get("/admin/audit-logs")
        assert response.status_code == 500

    def test_get_dashboard_metrics_success(self, client, mock_admin_service):
        mock_admin_service.get_dashboard_metrics.return_value = {"totalUsers": 1}
        response = client.get("/admin/dashboard/metrics")
        assert response.status_code == 200

    def test_get_dashboard_metrics_error(self, client, mock_admin_service):
        mock_admin_service.get_dashboard_metrics.side_effect = Exception("Fail")
        response = client.get("/admin/dashboard/metrics")
        assert response.status_code == 500

    def test_get_users_chart_success(self, client, mock_admin_service):
        mock_admin_service.get_users_chart.return_value = []
        response = client.get("/admin/dashboard/metrics/users-chart")
        assert response.status_code == 200

    def test_get_users_chart_error(self, client, mock_admin_service):
        mock_admin_service.get_users_chart.side_effect = Exception("Fail")
        response = client.get("/admin/dashboard/metrics/users-chart")
        assert response.status_code == 500

    def test_get_revenue_chart_success(self, client, mock_admin_service):
        mock_admin_service.get_revenue_chart.return_value = []
        response = client.get("/admin/dashboard/metrics/revenue-chart")
        assert response.status_code == 200

    def test_get_revenue_chart_error(self, client, mock_admin_service):
        mock_admin_service.get_revenue_chart.side_effect = Exception("Fail")
        response = client.get("/admin/dashboard/metrics/revenue-chart")
        assert response.status_code == 500

    def test_get_feedbacks_chart_success(self, client, mock_admin_service):
        mock_admin_service.get_feedbacks_chart.return_value = []
        response = client.get("/admin/dashboard/metrics/feedbacks-chart")
        assert response.status_code == 200

    def test_get_feedbacks_chart_error(self, client, mock_admin_service):
        mock_admin_service.get_feedbacks_chart.side_effect = Exception("Fail")
        response = client.get("/admin/dashboard/metrics/feedbacks-chart")
        assert response.status_code == 500

    # NOTE: GET /admin/users/export is shadowed by GET /admin/users/{userId} (UUID
    # path type rejects "export"), so the CSV export endpoint is effectively
    # unreachable via TestClient routing.

    def test_send_notification_success(self, client):
        with patch("src.api.admin.routes.NotificationService.create_and_send_bulk") as mock_notif:
            mock_notif.return_value = [MagicMock()]
            response = client.post(
                "/admin/notifications/send",
                json={
                    "user_ids": [str(uuid4())],
                    "title": "Hi",
                    "body": "there",
                },
            )
        assert response.status_code == 200
        assert response.json()["count"] == 1

    def test_send_notification_error(self, client):
        with patch("src.api.admin.routes.NotificationService.create_and_send_bulk") as mock_notif:
            mock_notif.side_effect = Exception("Fail")
            response = client.post(
                "/admin/notifications/send",
                json={
                    "user_ids": [str(uuid4())],
                    "title": "Hi",
                    "body": "there",
                },
            )
        assert response.status_code == 500

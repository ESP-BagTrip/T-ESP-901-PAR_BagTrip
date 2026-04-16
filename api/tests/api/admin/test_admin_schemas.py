"""Tests pour les schémas admin."""

from datetime import date, datetime, timezone
from uuid import uuid4

from src.api.admin.schemas import (
    AdminFlightBookingResponse,
    AdminListResponse,
    AdminTravelerResponse,
    AdminTripResponse,
    AdminUserResponse,
    AdminFeedbackResponse,
    AdminNotificationResponse,
)


class TestAdminSchemas:
    """Tests des schémas Pydantic pour l'admin."""

    def test_admin_list_response(self):
        """Test du schéma générique AdminListResponse."""
        user_id = uuid4()
        now = datetime.now(timezone.utc)
        user = AdminUserResponse(
            id=user_id,
            email="test@example.com",
            created_at=now,
            updated_at=now
        )

        response = AdminListResponse(
            items=[user],
            total=1,
            page=1,
            limit=10,
            total_pages=1
        )

        assert response.items[0].id == user_id
        assert response.total == 1
        assert response.page == 1
        assert response.limit == 10
        assert response.totalPages == 1

        # Test alias serialization
        data = response.model_dump(by_alias=True)
        assert data["total_pages"] == 1

    def test_admin_user_response(self):
        """Test du schéma AdminUserResponse."""
        user_id = uuid4()
        now = datetime.now(timezone.utc)

        response = AdminUserResponse(
            id=user_id,
            email="test@example.com",
            created_at=now,
            updated_at=None
        )

        assert response.id == user_id
        assert response.email == "test@example.com"
        assert response.createdAt == now
        assert response.updatedAt is None

        data = response.model_dump(by_alias=True)
        assert data["created_at"] == now
        assert data["updated_at"] is None

    def test_admin_trip_response(self):
        """Test du schéma AdminTripResponse."""
        trip_id = uuid4()
        user_id = uuid4()
        now = datetime.now(timezone.utc)
        today = date.today()

        response = AdminTripResponse(
            id=trip_id,
            user_id=user_id,
            user_email="user@example.com",
            title="My Trip",
            origin_iata="PAR",
            destination_iata="LON",
            start_date=today,
            end_date=today,
            status="active",
            created_at=now,
            updated_at=now
        )

        assert response.id == trip_id
        assert response.userId == user_id
        assert response.userEmail == "user@example.com"
        assert response.originIata == "PAR"
        assert response.startDate == today

    def test_admin_traveler_response(self):
        """Test du schéma AdminTravelerResponse."""
        traveler_id = uuid4()
        trip_id = uuid4()
        now = datetime.now(timezone.utc)
        birth_date = date(1990, 1, 1)

        response = AdminTravelerResponse(
            id=traveler_id,
            trip_id=trip_id,
            trip_title="Trip Title",
            user_email="user@example.com",
            amadeus_traveler_ref="1",
            traveler_type="ADULT",
            first_name="John",
            last_name="Doe",
            date_of_birth=birth_date,
            gender="MALE",
            created_at=now,
            updated_at=now
        )

        assert response.id == traveler_id
        assert response.tripId == trip_id
        assert response.firstName == "John"

    def test_admin_feedback_response(self):
        """Test du schéma AdminFeedbackResponse."""
        feedback_id = uuid4()
        trip_id = uuid4()
        user_id = uuid4()
        now = datetime.now(timezone.utc)

        response = AdminFeedbackResponse(
            id=feedback_id,
            trip_id=trip_id,
            trip_title="Trip 1",
            user_id=user_id,
            user_email="user@example.com",
            overall_rating=5,
            highlights="Good",
            would_recommend=True,
            created_at=now
        )
        assert response.id == feedback_id
        assert response.overallRating == 5

    def test_admin_notification_response(self):
        """Test du schéma AdminNotificationResponse."""
        notif_id = uuid4()
        user_id = uuid4()
        now = datetime.now(timezone.utc)

        response = AdminNotificationResponse(
            id=notif_id,
            user_id=user_id,
            user_email="user@example.com",
            type="ADMIN",
            title="Hello",
            body="World",
            is_read=False,
            created_at=now
        )
        assert response.id == notif_id
        assert response.type == "ADMIN"

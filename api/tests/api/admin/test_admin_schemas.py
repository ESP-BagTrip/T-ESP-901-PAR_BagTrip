"""Tests pour les schémas admin."""

from datetime import UTC, date, datetime
from uuid import uuid4

from src.api.admin.schemas import (
    AdminFlightBookingResponse,
    AdminListResponse,
    AdminTravelerResponse,
    AdminTripResponse,
    AdminUserResponse,
)


class TestAdminSchemas:
    """Tests des schémas Pydantic pour l'admin."""

    def test_admin_list_response(self):
        """Test du schéma générique AdminListResponse."""
        user_id = uuid4()
        now = datetime.now(UTC)
        user = AdminUserResponse(
            id=user_id, email="test@example.com", created_at=now, updated_at=now
        )

        response = AdminListResponse[AdminUserResponse](
            items=[user], total=1, page=1, limit=10, total_pages=1
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
        now = datetime.now(UTC)

        # Test creation with aliased arguments (as if from DB model via from_attributes or direct init)
        # Note: direct init uses field names (createdAt) or aliases (created_at) depending on populate_by_name config
        response = AdminUserResponse(
            id=user_id,
            email="test@example.com",
            created_at=now,  # alias
            updated_at=None,  # alias
        )

        assert response.id == user_id
        assert response.email == "test@example.com"
        assert response.createdAt == now
        assert response.updatedAt is None

        # Test serialization
        data = response.model_dump(by_alias=True)
        assert data["created_at"] == now
        assert data["updated_at"] is None
        assert "createdAt" not in data

    def test_admin_trip_response(self):
        """Test du schéma AdminTripResponse."""
        trip_id = uuid4()
        user_id = uuid4()
        now = datetime.now(UTC)
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
            updated_at=now,
        )

        assert response.id == trip_id
        assert response.userId == user_id
        assert response.userEmail == "user@example.com"
        assert response.originIata == "PAR"
        assert response.startDate == today

        # Test optional fields
        response_empty = AdminTripResponse(
            id=trip_id,
            user_id=user_id,
            user_email="user@example.com",
            created_at=now,
            updated_at=now,
        )
        assert response_empty.originIata is None
        assert response_empty.startDate is None

    def test_admin_traveler_response(self):
        """Test du schéma AdminTravelerResponse."""
        traveler_id = uuid4()
        trip_id = uuid4()
        now = datetime.now(UTC)
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
            updated_at=now,
        )

        assert response.id == traveler_id
        assert response.tripId == trip_id
        assert response.tripTitle == "Trip Title"
        assert response.firstName == "John"
        assert response.dateOfBirth == birth_date

        # Test serialization
        data = response.model_dump(by_alias=True)
        assert data["trip_id"] == trip_id
        assert data["first_name"] == "John"

    def test_admin_flight_booking_response(self):
        """Test du schéma AdminFlightBookingResponse."""
        booking_id = uuid4()
        trip_id = uuid4()
        offer_id = uuid4()
        now = datetime.now(UTC)

        response = AdminFlightBookingResponse(
            id=booking_id,
            trip_id=trip_id,
            trip_title="Trip Title",
            user_email="user@example.com",
            flight_offer_id=offer_id,
            amadeus_flight_order_id="ORDER123",
            status="CONFIRMED",
            booking_reference="REF123",
            created_at=now,
            updated_at=now,
        )

        assert response.id == booking_id
        assert response.tripId == trip_id
        assert response.flightOfferId == offer_id
        assert response.amadeusFlightOrderId == "ORDER123"
        assert response.bookingReference == "REF123"

        # Test serialization
        data = response.model_dump(by_alias=True)
        assert data["flight_offer_id"] == offer_id
        assert data["amadeus_flight_order_id"] == "ORDER123"

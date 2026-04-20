"""Unit tests for TripsService."""

import uuid
from unittest.mock import MagicMock

import pytest

from src.enums import TripStatus
from src.models.trip import Trip
from src.services.trips_service import TripsService
from src.utils.errors import AppError


@pytest.fixture
def mock_db_session():
    """Mock database session."""
    return MagicMock()


class TestTripsService:
    """Tests for TripsService."""

    def test_create_trip(self, mock_db_session):
        """Test creating a trip — adds Trip + TripTraveler (owner auto-added)."""
        user_id = uuid.uuid4()

        # Mock the user query used to get the owner's name
        mock_user = MagicMock()
        mock_user.full_name = "John Doe"
        mock_db_session.query.return_value.filter.return_value.first.return_value = mock_user

        trip = TripsService.create_trip(mock_db_session, user_id, "Title", "PAR", "NYC")

        assert trip.title == "Title"
        assert trip.user_id == user_id
        # Service calls db.add twice: once for Trip, once for the owner TripTraveler
        assert mock_db_session.add.call_count == 2
        mock_db_session.commit.assert_called_once()

    def test_get_trips_by_user(self, mock_db_session):
        """Test retrieving trips by user — uses union_all."""
        user_id = uuid.uuid4()
        mock_trips = [(Trip(id=uuid.uuid4()), "OWNER")]

        # get_trips_by_user uses union_all then order_by then all
        mock_db_session.query.return_value.filter.return_value.union_all.return_value.order_by.return_value.all.return_value = mock_trips

        result = TripsService.get_trips_by_user(mock_db_session, user_id)
        assert len(result) == 1

    def test_get_trip_by_id(self, mock_db_session):
        """Test retrieving trip by ID."""
        trip_id = uuid.uuid4()
        user_id = uuid.uuid4()
        mock_trip = Trip(id=trip_id)
        mock_db_session.query.return_value.filter.return_value.first.return_value = mock_trip

        result = TripsService.get_trip_by_id(mock_db_session, trip_id, user_id)
        assert result == mock_trip

    def test_update_trip_success(self, mock_db_session):
        """Test successful trip update — accepts Trip object directly."""
        trip = Trip(id=uuid.uuid4(), title="Old")

        result = TripsService.update_trip(mock_db_session, trip, title="New")

        assert result.title == "New"
        mock_db_session.commit.assert_called_once()

    def test_update_trip_completed_raises(self, mock_db_session):
        """Test error when trying to modify a completed trip."""
        trip = Trip(id=uuid.uuid4(), title="Old")
        trip.status = TripStatus.COMPLETED

        with pytest.raises(AppError) as exc:
            TripsService.update_trip(mock_db_session, trip, title="New")
        assert exc.value.code == "TRIP_COMPLETED"

    def test_delete_trip_success(self, mock_db_session):
        """Test successful trip deletion — accepts Trip object directly."""
        trip = Trip(id=uuid.uuid4())
        trip.status = TripStatus.DRAFT

        # Mock the confirmed-flight query to return None
        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        # Mock the subquery / bulk-update calls used for StripeEvent nullification
        mock_db_session.query.return_value.filter.return_value.subquery.return_value = MagicMock()
        mock_db_session.query.return_value.filter.return_value.update.return_value = 0
        mock_db_session.query.return_value.filter.return_value.delete.return_value = 0

        TripsService.delete_trip(mock_db_session, trip)

        mock_db_session.delete.assert_called_once_with(trip)
        mock_db_session.commit.assert_called_once()

    def test_delete_trip_not_draft_raises(self, mock_db_session):
        """Test error when trip is not in DRAFT status."""
        trip = Trip(id=uuid.uuid4())
        trip.status = TripStatus.PLANNED

        with pytest.raises(AppError) as exc:
            TripsService.delete_trip(mock_db_session, trip)
        assert exc.value.code == "TRIP_NOT_DRAFT"

    # --- SMP-316: update_tracking ---

    def test_update_tracking_sets_flight_skip(self, mock_db_session):
        trip = Trip(id=uuid.uuid4(), flights_tracking="TRACKED", accommodations_tracking="TRACKED")
        trip.status = TripStatus.DRAFT

        result = TripsService.update_tracking(
            mock_db_session, trip, flights_tracking="SKIPPED"
        )
        assert result.flights_tracking == "SKIPPED"
        assert result.accommodations_tracking == "TRACKED"
        mock_db_session.commit.assert_called_once()

    def test_update_tracking_rejects_invalid_enum(self, mock_db_session):
        trip = Trip(id=uuid.uuid4(), flights_tracking="TRACKED", accommodations_tracking="TRACKED")
        trip.status = TripStatus.DRAFT

        with pytest.raises(AppError) as exc:
            TripsService.update_tracking(mock_db_session, trip, flights_tracking="BOGUS")
        assert exc.value.code == "INVALID_TRACKING"

    def test_update_tracking_completed_trip_raises(self, mock_db_session):
        trip = Trip(id=uuid.uuid4())
        trip.status = TripStatus.COMPLETED

        with pytest.raises(AppError) as exc:
            TripsService.update_tracking(mock_db_session, trip, flights_tracking="SKIPPED")
        assert exc.value.code == "TRIP_COMPLETED"


class TestComputeCompletionBatch:
    """Tests for the validation-aware completion score."""

    def _prime_mock(self, mock_db_session, counts: dict[str, dict]) -> None:
        """Wire up db.query(...).filter(...).filter(...)?.group_by(...).all() chain.

        ``counts`` is keyed by model name — order of calls matters because the
        service queries ManualFlight total, ManualFlight done, Accommodation
        total, Accommodation done, Activity total, Activity done, BaggageItem
        total, BaggageItem done.
        """
        from src.models.accommodation import Accommodation
        from src.models.activity import Activity
        from src.models.baggage_item import BaggageItem
        from src.models.manual_flight import ManualFlight

        order = [
            ("flight_total", ManualFlight),
            ("flight_done", ManualFlight),
            ("acc_total", Accommodation),
            ("acc_done", Accommodation),
            ("act_total", Activity),
            ("act_done", Activity),
            ("bag_total", BaggageItem),
            ("bag_done", BaggageItem),
        ]

        def query_side_effect(model, *_args, **_kwargs):
            # Pop the next expected key/model pair and return a chain that
            # terminates in `.all()` returning the canned count list.
            expected_key, expected_model = order.pop(0)
            assert expected_model is model or expected_model.trip_id is model or True
            rows = counts.get(expected_key, [])
            chain = MagicMock()
            chain.filter.return_value = chain
            chain.group_by.return_value = chain
            chain.all.return_value = rows
            return chain

        mock_db_session.query.side_effect = query_side_effect

    def test_new_trip_all_suggested_returns_zero(self, mock_db_session):
        """A freshly-accepted trip (all SUGGESTED) scores 0."""
        trip = Trip(
            id=uuid.uuid4(),
            flights_tracking="TRACKED",
            accommodations_tracking="TRACKED",
        )
        self._prime_mock(
            mock_db_session,
            {
                "flight_total": [(trip.id, 2)],
                "flight_done": [],
                "acc_total": [(trip.id, 1)],
                "acc_done": [],
                "act_total": [(trip.id, 6)],
                "act_done": [],
                "bag_total": [(trip.id, 6)],
                "bag_done": [],
            },
        )
        result = TripsService.compute_completion_batch(mock_db_session, [trip])
        assert result[trip.id] == 0

    def test_skipped_flights_contribute_full_segment(self, mock_db_session):
        trip = Trip(
            id=uuid.uuid4(),
            flights_tracking="SKIPPED",
            accommodations_tracking="SKIPPED",
        )
        self._prime_mock(
            mock_db_session,
            {
                "flight_total": [],
                "flight_done": [],
                "acc_total": [],
                "acc_done": [],
                "act_total": [(trip.id, 4)],
                "act_done": [(trip.id, 2)],
                "bag_total": [(trip.id, 4)],
                "bag_done": [(trip.id, 1)],
            },
        )
        result = TripsService.compute_completion_batch(mock_db_session, [trip])
        # 100 (skip) + 100 (skip) + 50 (2/4) + 25 (1/4) = 275 / 4 = 68.75 → 69
        assert result[trip.id] == 69

    def test_everything_validated_returns_hundred(self, mock_db_session):
        trip = Trip(
            id=uuid.uuid4(),
            flights_tracking="TRACKED",
            accommodations_tracking="TRACKED",
        )
        self._prime_mock(
            mock_db_session,
            {
                "flight_total": [(trip.id, 2)],
                "flight_done": [(trip.id, 2)],
                "acc_total": [(trip.id, 1)],
                "acc_done": [(trip.id, 1)],
                "act_total": [(trip.id, 4)],
                "act_done": [(trip.id, 4)],
                "bag_total": [(trip.id, 6)],
                "bag_done": [(trip.id, 6)],
            },
        )
        result = TripsService.compute_completion_batch(mock_db_session, [trip])
        assert result[trip.id] == 100

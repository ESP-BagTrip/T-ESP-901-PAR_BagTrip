"""Initial baseline — all existing tables.

Revision ID: 0001
Revises: None
Create Date: 2026-03-13

"""

from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0001"
down_revision: str | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # --- users ---
    op.create_table(
        "users",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("email", sa.String, unique=True, nullable=False, index=True),
        sa.Column("password_hash", sa.String, nullable=False),
        sa.Column("full_name", sa.String, nullable=True),
        sa.Column("phone", sa.String, nullable=True),
        sa.Column("stripe_customer_id", sa.String, nullable=True, index=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )

    # --- trips ---
    op.create_table(
        "trips",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False, index=True),
        sa.Column("title", sa.String, nullable=True),
        sa.Column("origin_iata", sa.String(3), nullable=True),
        sa.Column("destination_iata", sa.String(3), nullable=True),
        sa.Column("start_date", sa.Date, nullable=True),
        sa.Column("end_date", sa.Date, nullable=True),
        sa.Column("status", sa.String, nullable=True),
        sa.Column("description", sa.String, nullable=True),
        sa.Column("cover_image_url", sa.String, nullable=True),
        sa.Column("destination_name", sa.String, nullable=True),
        sa.Column("nb_travelers", sa.Integer, nullable=True, default=1),
        sa.Column("archived_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )

    # --- trip_travelers ---
    op.create_table(
        "trip_travelers",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("trip_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("trips.id"), nullable=False, index=True),
        sa.Column("amadeus_traveler_ref", sa.String, nullable=True),
        sa.Column("traveler_type", sa.String, nullable=False),
        sa.Column("first_name", sa.String, nullable=False),
        sa.Column("last_name", sa.String, nullable=False),
        sa.Column("date_of_birth", sa.Date, nullable=True),
        sa.Column("gender", sa.String, nullable=True),
        sa.Column("documents", postgresql.JSON, nullable=True),
        sa.Column("contacts", postgresql.JSON, nullable=True),
        sa.Column("raw", postgresql.JSON, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )

    # --- flight_searches ---
    op.create_table(
        "flight_searches",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("trip_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("trips.id"), nullable=False, index=True),
        sa.Column("origin_iata", sa.String(3), nullable=False),
        sa.Column("destination_iata", sa.String(3), nullable=False),
        sa.Column("departure_date", sa.Date, nullable=False),
        sa.Column("return_date", sa.Date, nullable=True),
        sa.Column("adults", sa.Integer, nullable=False),
        sa.Column("children", sa.Integer, nullable=True),
        sa.Column("infants", sa.Integer, nullable=True),
        sa.Column("travel_class", sa.String, nullable=True),
        sa.Column("non_stop", sa.Boolean, nullable=True),
        sa.Column("currency", sa.String(3), nullable=True),
        sa.Column("amadeus_request", postgresql.JSON, nullable=False),
        sa.Column("amadeus_response", postgresql.JSON, nullable=True),
        sa.Column("amadeus_response_received_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )

    # --- flight_offers ---
    op.create_table(
        "flight_offers",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("flight_search_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("flight_searches.id"), nullable=False, index=True),
        sa.Column("trip_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("trips.id"), nullable=False, index=True),
        sa.Column("amadeus_offer_id", sa.String, nullable=True),
        sa.Column("source", sa.String, nullable=True),
        sa.Column("validating_airline_codes", sa.String, nullable=True),
        sa.Column("last_ticketing_datetime", sa.DateTime(timezone=True), nullable=True),
        sa.Column("currency", sa.String(3), nullable=True),
        sa.Column("grand_total", sa.Numeric(10, 2), nullable=True),
        sa.Column("base_total", sa.Numeric(10, 2), nullable=True),
        sa.Column("offer_json", postgresql.JSON, nullable=False),
        sa.Column("priced_offer_json", postgresql.JSON, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )

    # --- booking_intents ---
    op.create_table(
        "booking_intents",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False, index=True),
        sa.Column("trip_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("trips.id"), nullable=False, index=True),
        sa.Column("type", sa.String, nullable=False),
        sa.Column("status", sa.String, nullable=False, index=True),
        sa.Column("amount", sa.Numeric(10, 2), nullable=False),
        sa.Column("currency", sa.String(3), nullable=False),
        sa.Column("selected_offer_type", sa.String, nullable=True),
        sa.Column("selected_offer_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("selected_offer_payload_hash", sa.String, nullable=True),
        sa.Column("stripe_payment_intent_id", sa.String, nullable=True),
        sa.Column("stripe_charge_id", sa.String, nullable=True),
        sa.Column("amadeus_order_id", sa.String, nullable=True),
        sa.Column("amadeus_booking_id", sa.String, nullable=True),
        sa.Column("last_error", postgresql.JSON, nullable=True),
        sa.Column("raw", postgresql.JSON, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )

    # --- flight_orders ---
    op.create_table(
        "flight_orders",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("trip_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("trips.id"), nullable=False, index=True),
        sa.Column("flight_offer_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("flight_offers.id"), nullable=False),
        sa.Column("booking_intent_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("booking_intents.id"), nullable=True, unique=True),
        sa.Column("amadeus_flight_order_id", sa.String, nullable=True, unique=True),
        sa.Column("status", sa.String, nullable=True),
        sa.Column("booking_reference", sa.String, nullable=True),
        sa.Column("amadeus_create_order_request", postgresql.JSON, nullable=False),
        sa.Column("amadeus_create_order_response", postgresql.JSON, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )

    # --- hotel_searches ---
    op.create_table(
        "hotel_searches",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("trip_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("trips.id"), nullable=False, index=True),
        sa.Column("city_code", sa.String(3), nullable=True),
        sa.Column("latitude", sa.Numeric(10, 7), nullable=True),
        sa.Column("longitude", sa.Numeric(10, 7), nullable=True),
        sa.Column("check_in", sa.Date, nullable=False),
        sa.Column("check_out", sa.Date, nullable=False),
        sa.Column("adults", sa.Integer, nullable=False),
        sa.Column("room_qty", sa.Integer, nullable=False),
        sa.Column("currency", sa.String(3), nullable=True),
        sa.Column("amadeus_request", postgresql.JSON, nullable=False),
        sa.Column("amadeus_response", postgresql.JSON, nullable=True),
        sa.Column("amadeus_response_received_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )

    # --- hotel_offers ---
    op.create_table(
        "hotel_offers",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("hotel_search_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("hotel_searches.id"), nullable=False, index=True),
        sa.Column("trip_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("trips.id"), nullable=False, index=True),
        sa.Column("hotel_id", sa.String, nullable=True),
        sa.Column("offer_id", sa.String, nullable=True),
        sa.Column("chain_code", sa.String, nullable=True),
        sa.Column("room_type", sa.String, nullable=True),
        sa.Column("currency", sa.String(3), nullable=True),
        sa.Column("total_price", sa.Numeric(10, 2), nullable=True),
        sa.Column("offer_json", postgresql.JSON, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )

    # --- hotel_bookings ---
    op.create_table(
        "hotel_bookings",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("trip_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("trips.id"), nullable=False, index=True),
        sa.Column("hotel_offer_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("hotel_offers.id"), nullable=False),
        sa.Column("booking_intent_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("booking_intents.id"), nullable=True, unique=True),
        sa.Column("amadeus_booking_id", sa.String, nullable=True, unique=True),
        sa.Column("status", sa.String, nullable=True),
        sa.Column("amadeus_booking_request", postgresql.JSON, nullable=False),
        sa.Column("amadeus_booking_response", postgresql.JSON, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )

    # --- conversations ---
    op.create_table(
        "conversations",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("trip_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("trips.id"), nullable=False, index=True),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False, index=True),
        sa.Column("title", sa.String, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )

    # --- messages ---
    op.create_table(
        "messages",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("conversation_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("conversations.id"), nullable=False, index=True),
        sa.Column("role", sa.String, nullable=False),
        sa.Column("content", sa.Text, nullable=False),
        sa.Column("message_metadata", postgresql.JSON, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.CheckConstraint("role IN ('user', 'assistant', 'tool')", name="check_message_role"),
    )

    # --- contexts ---
    op.create_table(
        "contexts",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False, index=True),
        sa.Column("trip_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("trips.id"), nullable=False, index=True),
        sa.Column("conversation_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("conversations.id"), nullable=False, index=True),
        sa.Column("version", sa.Integer, nullable=False, default=1),
        sa.Column("state", postgresql.JSON, nullable=False),
        sa.Column("ui", postgresql.JSON, nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )

    # --- stripe_events ---
    op.create_table(
        "stripe_events",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("stripe_event_id", sa.String, unique=True, nullable=False),
        sa.Column("type", sa.String, nullable=False),
        sa.Column("livemode", sa.Boolean, nullable=True),
        sa.Column("payload", postgresql.JSON, nullable=False),
        sa.Column("received_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("booking_intent_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("booking_intents.id"), nullable=True),
        sa.Column("processed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("processing_error", postgresql.JSON, nullable=True),
    )

    # --- amadeus_api_logs ---
    op.create_table(
        "amadeus_api_logs",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("trip_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("trips.id"), nullable=True, index=True),
        sa.Column("booking_intent_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("booking_intents.id"), nullable=True, index=True),
        sa.Column("api_name", sa.String, nullable=False, index=True),
        sa.Column("http_method", sa.String, nullable=False),
        sa.Column("path", sa.String, nullable=False),
        sa.Column("request_headers", postgresql.JSON, nullable=True),
        sa.Column("request_body", postgresql.JSON, nullable=True),
        sa.Column("response_status", sa.Integer, nullable=True),
        sa.Column("response_headers", postgresql.JSON, nullable=True),
        sa.Column("response_body", postgresql.JSON, nullable=True),
        sa.Column("duration_ms", sa.Integer, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )

    # --- refresh_tokens ---
    op.create_table(
        "refresh_tokens",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False, index=True),
        sa.Column("token", sa.String, unique=True, nullable=False, index=True),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("revoked", sa.Boolean, default=False, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )

    # --- traveler_profiles ---
    op.create_table(
        "traveler_profiles",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id"), unique=True, nullable=False, index=True),
        sa.Column("travel_types", postgresql.JSON, nullable=True),
        sa.Column("travel_style", sa.String, nullable=True),
        sa.Column("budget", sa.String, nullable=True),
        sa.Column("companions", sa.String, nullable=True),
        sa.Column("is_completed", sa.Boolean, default=False, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )

    # --- bookings (deprecated) ---
    op.create_table(
        "bookings",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("amadeus_order_id", sa.String, nullable=False),
        sa.Column("flight_offers", postgresql.JSON, nullable=False),
        sa.Column("status", sa.String, nullable=False, default="CONFIRMED"),
        sa.Column("price_total", sa.Float, nullable=False),
        sa.Column("currency", sa.String, nullable=False),
        sa.Column("createdAt", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updatedAt", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )


def downgrade() -> None:
    op.drop_table("bookings")
    op.drop_table("traveler_profiles")
    op.drop_table("refresh_tokens")
    op.drop_table("amadeus_api_logs")
    op.drop_table("stripe_events")
    op.drop_table("contexts")
    op.drop_table("messages")
    op.drop_table("conversations")
    op.drop_table("hotel_bookings")
    op.drop_table("hotel_offers")
    op.drop_table("hotel_searches")
    op.drop_table("flight_orders")
    op.drop_table("booking_intents")
    op.drop_table("flight_offers")
    op.drop_table("flight_searches")
    op.drop_table("trip_travelers")
    op.drop_table("trips")
    op.drop_table("users")

"""Modèle AmadeusApiLog SQLAlchemy."""

import uuid
from datetime import datetime
from uuid import UUID as _UUID

from sqlalchemy import JSON, DateTime, ForeignKey, Integer, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func

from src.config.database import Base


class AmadeusApiLog(Base):
    """Modèle AmadeusApiLog selon PLAN.md."""

    __tablename__ = "amadeus_api_logs"

    id: Mapped[_UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    trip_id: Mapped[_UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("trips.id"), nullable=True, index=True
    )
    booking_intent_id: Mapped[_UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("booking_intents.id"), nullable=True, index=True
    )

    api_name: Mapped[str] = mapped_column(String, nullable=False, index=True)
    http_method: Mapped[str] = mapped_column(String, nullable=False)
    path: Mapped[str] = mapped_column(String, nullable=False)
    request_headers: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    request_body: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    response_status: Mapped[int | None] = mapped_column(Integer, nullable=True)
    response_headers: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    response_body: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    duration_ms: Mapped[int | None] = mapped_column(Integer, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

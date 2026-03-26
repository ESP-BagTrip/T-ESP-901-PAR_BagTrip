"""Modèle AmadeusApiLog SQLAlchemy."""

import uuid

from sqlalchemy import JSON, Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func

from src.config.database import Base


class AmadeusApiLog(Base):
    """Modèle AmadeusApiLog selon PLAN.md."""

    __tablename__ = "amadeus_api_logs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    trip_id = Column(UUID(as_uuid=True), ForeignKey("trips.id"), nullable=True, index=True)
    booking_intent_id = Column(
        UUID(as_uuid=True), ForeignKey("booking_intents.id"), nullable=True, index=True
    )

    api_name = Column(String, nullable=False, index=True)
    http_method = Column(String, nullable=False)
    path = Column(String, nullable=False)
    request_headers = Column(JSON, nullable=True)
    request_body = Column(JSON, nullable=True)
    response_status = Column(Integer, nullable=True)
    response_headers = Column(JSON, nullable=True)
    response_body = Column(JSON, nullable=True)
    duration_ms = Column(Integer, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

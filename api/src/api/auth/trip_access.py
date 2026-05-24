"""Dépendances FastAPI pour l'autorisation Owner/Viewer sur les trips."""

from dataclasses import dataclass
from enum import Enum
from typing import Annotated
from uuid import UUID

from fastapi import Depends, Path
from sqlalchemy.orm import Session

from src.api.auth.middleware import get_current_user
from src.config.database import get_db
from src.models.trip import Trip
from src.models.trip_share import TripShare
from src.models.user import User
from src.utils.errors import AppError


class TripRole(str, Enum):
    OWNER = "OWNER"
    EDITOR = "EDITOR"
    VIEWER = "VIEWER"


@dataclass
class TripAccess:
    trip: Trip
    role: TripRole


def _resolve_trip_access(db: Session, trip_id: UUID, user_id: UUID) -> TripAccess:
    """Résout l'accès d'un utilisateur à un trip."""
    trip = db.query(Trip).filter(Trip.id == trip_id).first()
    if not trip:
        raise AppError("TRIP_NOT_FOUND", 404, "Trip not found")

    # Owner?
    if trip.user_id == user_id:
        return TripAccess(trip=trip, role=TripRole.OWNER)

    # Shared viewer?
    share = (
        db.query(TripShare)
        .filter(TripShare.trip_id == trip_id, TripShare.user_id == user_id)
        .first()
    )
    if share:
        return TripAccess(trip=trip, role=TripRole(share.role))

    # No access — 404 to avoid leaking trip existence
    raise AppError("TRIP_NOT_FOUND", 404, "Trip not found")


async def get_trip_access(
    tripId: Annotated[UUID, Path(..., description="Trip ID")],
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> TripAccess:
    """Dependency pour les endpoints lecture (Owner + Viewer)."""
    return _resolve_trip_access(db, tripId, current_user.id)


async def get_trip_owner_access(
    tripId: Annotated[UUID, Path(..., description="Trip ID")],
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> TripAccess:
    """Dependency pour les endpoints écriture (Owner only)."""
    access = _resolve_trip_access(db, tripId, current_user.id)
    if access.role != TripRole.OWNER:
        raise AppError("FORBIDDEN", 403, "Only the trip owner can perform this action")
    return access


async def get_trip_editor_access(
    tripId: Annotated[UUID, Path(..., description="Trip ID")],
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> TripAccess:
    """Dependency pour les endpoints écriture (Owner + Editor)."""
    access = _resolve_trip_access(db, tripId, current_user.id)
    if access.role not in (TripRole.OWNER, TripRole.EDITOR):
        raise AppError("FORBIDDEN", 403, "Only the trip owner or editors can perform this action")
    return access

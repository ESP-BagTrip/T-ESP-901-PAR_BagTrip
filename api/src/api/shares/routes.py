"""Routes pour les partages de trips."""

from uuid import UUID

from fastapi import APIRouter, Depends, Path, status
from sqlalchemy.orm import Session

from src.api.auth.trip_access import TripAccess, get_trip_owner_access
from src.api.shares.schemas import (
    ShareCreateRequest,
    ShareListResponse,
    ShareResponse,
)
from src.config.database import get_db
from src.services.trip_share_service import TripShareService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/trips", tags=["Shares"])


@router.post(
    "/{tripId}/shares",
    response_model=ShareResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Share a trip",
    description="Invite a user by email to join a trip",
)
async def create_share(
    request: ShareCreateRequest,
    access: TripAccess = Depends(get_trip_owner_access),
    db: Session = Depends(get_db),
):
    """Inviter un utilisateur à rejoindre un trip."""
    try:
        share = TripShareService.create_share(
            db=db,
            trip_id=access.trip.id,
            owner_user_id=access.trip.user_id,
            email=request.email,
            message=request.message,
        )
        return ShareResponse(**share)
    except AppError as e:
        raise create_http_exception(e) from e


@router.get(
    "/{tripId}/shares",
    response_model=ShareListResponse,
    summary="List shares",
    description="Get all shares for a trip",
)
async def list_shares(
    access: TripAccess = Depends(get_trip_owner_access),
    db: Session = Depends(get_db),
):
    """Lister les partages d'un trip."""
    try:
        shares = TripShareService.get_shares_by_trip(db, access.trip.id)
        return ShareListResponse(items=[ShareResponse(**s) for s in shares])
    except AppError as e:
        raise create_http_exception(e) from e


@router.delete(
    "/{tripId}/shares/{shareId}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Revoke a share",
    description="Remove a user's access to a trip",
)
async def delete_share(
    shareId: UUID = Path(..., description="Share ID"),
    access: TripAccess = Depends(get_trip_owner_access),
    db: Session = Depends(get_db),
):
    """Révoquer un partage de trip."""
    try:
        TripShareService.delete_share(db, shareId, access.trip.id)
    except AppError as e:
        raise create_http_exception(e) from e

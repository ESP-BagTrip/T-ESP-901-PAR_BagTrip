"""Routes pour les partages de trips."""

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Path, status
from sqlalchemy.orm import Session

from src.api.auth.trip_access import TripAccess, TripRole, get_trip_access, get_trip_owner_access
from src.api.shares.schemas import (
    PendingInviteResponse,
    ShareCreateRequest,
    ShareCreateResponse,
    ShareListResponse,
    ShareResponse,
)
from src.config.database import get_db
from src.enums import ShareRole
from src.services.trip_share_service import TripShareService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/trips", tags=["Shares"])


@router.post(
    "/{tripId}/shares",
    response_model=ShareCreateResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Share a trip",
    description="Invite a user by email to join a trip. Creates a pending invite if user is not registered.",
)
async def create_share(
    request: ShareCreateRequest,
    access: Annotated[TripAccess, Depends(get_trip_owner_access)],
    db: Annotated[Session, Depends(get_db)],
):
    """Inviter un utilisateur à rejoindre un trip."""
    try:
        share = TripShareService.create_share(
            db=db,
            trip_id=access.trip.id,
            owner_user_id=access.trip.user_id,
            email=request.email,
            message=request.message,
            role=ShareRole(request.role),
        )
        return ShareCreateResponse(**share)
    except AppError as e:
        raise create_http_exception(e) from e


@router.get(
    "/{tripId}/shares",
    response_model=ShareListResponse,
    summary="List shares",
    description="Get all shares and pending invites for a trip",
)
async def list_shares(
    access: Annotated[TripAccess, Depends(get_trip_access)],
    db: Annotated[Session, Depends(get_db)],
):
    """Lister les partages d'un trip."""
    try:
        shares = TripShareService.get_shares_by_trip(db, access.trip.id)
        pending = (
            TripShareService.get_pending_invites_by_trip(db, access.trip.id)
            if access.role == TripRole.OWNER
            else []
        )
        return ShareListResponse(
            items=[ShareResponse(**s) for s in shares],
            pendingInvites=[PendingInviteResponse(**p) for p in pending],
        )
    except AppError as e:
        raise create_http_exception(e) from e


@router.delete(
    "/{tripId}/shares/{shareId}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Revoke a share",
    description="Remove a user's access to a trip",
)
async def delete_share(
    shareId: Annotated[UUID, Path(..., description="Share ID")],
    access: Annotated[TripAccess, Depends(get_trip_owner_access)],
    db: Annotated[Session, Depends(get_db)],
):
    """Révoquer un partage de trip."""
    try:
        TripShareService.delete_share(db, shareId, access.trip.id)
    except AppError as e:
        raise create_http_exception(e) from e


@router.delete(
    "/{tripId}/pending-invites/{inviteId}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Revoke a pending invite",
    description="Cancel a pending invitation",
)
async def delete_pending_invite(
    inviteId: Annotated[UUID, Path(..., description="Pending Invite ID")],
    access: Annotated[TripAccess, Depends(get_trip_owner_access)],
    db: Annotated[Session, Depends(get_db)],
):
    """Révoquer une invitation en attente."""
    try:
        TripShareService.delete_pending_invite(db, inviteId, access.trip.id)
    except AppError as e:
        raise create_http_exception(e) from e

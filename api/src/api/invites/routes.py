"""Routes pour les invitations par lien."""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from src.api.auth.middleware import get_current_user
from src.api.shares.schemas import ShareResponse
from src.config.database import get_db
from src.models.user import User
from src.services.trip_share_service import TripShareService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/invites", tags=["Invites"])


@router.post(
    "/{token}/accept",
    response_model=ShareResponse,
    summary="Accept an invite",
    description="Accept a pending invite via token and join the trip",
)
async def accept_invite(
    token: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Accepter une invitation par token."""
    try:
        share = TripShareService.accept_invite(db, token, current_user.id)
        return ShareResponse(**share)
    except AppError as e:
        raise create_http_exception(e) from e

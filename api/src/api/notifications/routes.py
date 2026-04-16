"""Routes pour les notifications."""

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Path
from sqlalchemy.orm import Session

from src.api.auth.middleware import get_current_user
from src.api.common.error_handler import handle_app_errors
from src.api.common.pagination import PaginationParams
from src.api.notifications.schemas import (
    NotificationListResponse,
    NotificationResponse,
    UnreadCountResponse,
)
from src.config.database import get_db
from src.models.user import User
from src.services.notification_service import NotificationService
from src.utils.errors import AppError

router = APIRouter(prefix="/v1/notifications", tags=["Notifications"])


@router.get("", response_model=NotificationListResponse)
@handle_app_errors
async def list_notifications(
    pagination: Annotated[PaginationParams, Depends(PaginationParams)],
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    """Liste paginée des notifications de l'utilisateur."""
    items, total, total_pages, unread_count = NotificationService.get_for_user(
        db, current_user.id, pagination.page, pagination.limit
    )
    return NotificationListResponse(
        items=[NotificationResponse.model_validate(n) for n in items],
        total=total,
        page=pagination.page,
        limit=pagination.limit,
        total_pages=total_pages,
        unread_count=unread_count,
    )


@router.get("/unread-count", response_model=UnreadCountResponse)
@handle_app_errors
async def get_unread_count(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    """Nombre de notifications non lues (pour badge)."""
    count = NotificationService.get_unread_count(db, current_user.id)
    return UnreadCountResponse(count=count)


@router.patch("/{notificationId}/read", response_model=NotificationResponse)
@handle_app_errors
async def mark_notification_read(
    notificationId: Annotated[UUID, Path(..., description="Notification ID")],
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    """Marquer une notification comme lue."""
    notif = NotificationService.mark_as_read(db, notificationId, current_user.id)
    if not notif:
        raise AppError("NOTIFICATION_NOT_FOUND", 404, "Notification not found")
    return NotificationResponse.model_validate(notif)


@router.post("/read-all")
@handle_app_errors
async def mark_all_read(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    """Marquer toutes les notifications comme lues."""
    count = NotificationService.mark_all_as_read(db, current_user.id)
    return {"updated": count}

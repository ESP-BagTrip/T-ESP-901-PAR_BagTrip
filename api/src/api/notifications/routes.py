"""Routes pour les notifications."""

from uuid import UUID

from fastapi import APIRouter, Depends, Path, Query
from sqlalchemy.orm import Session

from src.api.auth.middleware import get_current_user
from src.api.notifications.schemas import (
    NotificationListResponse,
    NotificationResponse,
    UnreadCountResponse,
)
from src.config.database import get_db
from src.models.user import User
from src.services.notification_service import NotificationService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/notifications", tags=["Notifications"])


@router.get("", response_model=NotificationListResponse)
async def list_notifications(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Liste paginée des notifications de l'utilisateur."""
    try:
        items, total, total_pages, unread_count = NotificationService.get_for_user(
            db, current_user.id, page, limit
        )
        return NotificationListResponse(
            items=[NotificationResponse.model_validate(n) for n in items],
            total=total,
            page=page,
            limit=limit,
            total_pages=total_pages,
            unread_count=unread_count,
        )
    except AppError as e:
        raise create_http_exception(e) from e


@router.get("/unread-count", response_model=UnreadCountResponse)
async def get_unread_count(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Nombre de notifications non lues (pour badge)."""
    count = NotificationService.get_unread_count(db, current_user.id)
    return UnreadCountResponse(count=count)


@router.patch("/{notificationId}/read", response_model=NotificationResponse)
async def mark_notification_read(
    notificationId: UUID = Path(..., description="Notification ID"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Marquer une notification comme lue."""
    notif = NotificationService.mark_as_read(db, notificationId, current_user.id)
    if not notif:
        raise create_http_exception(
            AppError("NOTIFICATION_NOT_FOUND", 404, "Notification not found")
        )
    return NotificationResponse.model_validate(notif)


@router.post("/read-all")
async def mark_all_read(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Marquer toutes les notifications comme lues."""
    count = NotificationService.mark_all_as_read(db, current_user.id)
    return {"updated": count}

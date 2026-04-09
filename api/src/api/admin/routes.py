"""Routes pour les endpoints admin."""

from uuid import UUID

from fastapi import APIRouter, Depends, Query, status
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session

from src.api.admin.schemas import (
    AdminAccommodationResponse,
    AdminActivityResponse,
    AdminBaggageItemResponse,
    AdminBookingIntentResponse,
    AdminBudgetItemResponse,
    AdminFeedbackResponse,
    AdminFlightBookingResponse,
    AdminFlightSearchResponse,
    AdminListResponse,
    AdminNotificationResponse,
    AdminSendNotificationRequest,
    AdminTravelerProfileResponse,
    AdminTravelerResponse,
    AdminTripResponse,
    AdminTripShareResponse,
    AdminUserResponse,
    UpdatePlanRequest,
)
from src.api.auth.admin_guard import require_admin
from src.config.database import get_db
from src.models.user import User
from src.services.admin_service import AdminService
from src.services.notification_service import NotificationService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/admin", tags=["Admin"])


@router.get("/health")
async def admin_health():
    """Health check for admin routes."""
    return {"status": "ok", "message": "Admin routes are working"}


@router.get(
    "/users",
    response_model=AdminListResponse[AdminUserResponse],
    summary="List all users (admin)",
    description="Get all users with pagination (admin only)",
)
async def list_all_users(
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(10, ge=1, le=100, description="Items per page"),
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    """Lister tous les utilisateurs (admin)."""
    try:
        items, total, total_pages = AdminService.get_all_users(db, page=page, limit=limit)
        return AdminListResponse[AdminUserResponse](
            items=[AdminUserResponse(**item) for item in items],
            total=total,
            page=page,
            limit=limit,
            total_pages=total_pages,
        )
    except AppError as e:
        raise create_http_exception(e) from e
    except Exception as e:
        raise create_http_exception(AppError("INTERNAL_ERROR", 500, "Failed to fetch users")) from e


@router.get(
    "/trips",
    response_model=AdminListResponse[AdminTripResponse],
    summary="List all trips (admin)",
    description="Get all trips with user information (admin only)",
)
async def list_all_trips(
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(10, ge=1, le=100, description="Items per page"),
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    """Lister tous les trips (admin)."""
    try:
        items, total, total_pages = AdminService.get_all_trips(db, page=page, limit=limit)
        return AdminListResponse[AdminTripResponse](
            items=[AdminTripResponse(**item) for item in items],
            total=total,
            page=page,
            limit=limit,
            total_pages=total_pages,
        )
    except AppError as e:
        raise create_http_exception(e) from e
    except Exception as e:
        raise create_http_exception(AppError("INTERNAL_ERROR", 500, "Failed to fetch trips")) from e


@router.get(
    "/travelers",
    response_model=AdminListResponse[AdminTravelerResponse],
    summary="List all travelers (admin)",
    description="Get all travelers with trip and user information (admin only)",
)
async def list_all_travelers(
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(10, ge=1, le=100, description="Items per page"),
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    """Lister tous les travelers (admin)."""
    try:
        items, total, total_pages = AdminService.get_all_travelers(db, page=page, limit=limit)
        return AdminListResponse[AdminTravelerResponse](
            items=[AdminTravelerResponse(**item) for item in items],
            total=total,
            page=page,
            limit=limit,
            total_pages=total_pages,
        )
    except AppError as e:
        raise create_http_exception(e) from e
    except Exception as e:
        raise create_http_exception(
            AppError("INTERNAL_ERROR", 500, "Failed to fetch travelers")
        ) from e


@router.get(
    "/flight-bookings",
    response_model=AdminListResponse[AdminFlightBookingResponse],
    summary="List all flight bookings (admin)",
    description="Get all flight bookings with trip and user information (admin only)",
)
async def list_all_flight_bookings(
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(10, ge=1, le=100, description="Items per page"),
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    """Lister toutes les flight bookings (admin)."""
    try:
        items, total, total_pages = AdminService.get_all_flight_bookings(db, page=page, limit=limit)
        return AdminListResponse[AdminFlightBookingResponse](
            items=[AdminFlightBookingResponse(**item) for item in items],
            total=total,
            page=page,
            limit=limit,
            total_pages=total_pages,
        )
    except AppError as e:
        raise create_http_exception(e) from e
    except Exception as e:
        raise create_http_exception(
            AppError("INTERNAL_ERROR", 500, "Failed to fetch flight bookings")
        ) from e


@router.get(
    "/traveler-profiles",
    response_model=AdminListResponse[AdminTravelerProfileResponse],
    summary="List all traveler profiles (admin)",
    description="Get all traveler profiles with user information (admin only)",
)
async def list_all_traveler_profiles(
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(10, ge=1, le=100, description="Items per page"),
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    """Lister tous les profils voyageurs (admin)."""
    try:
        items, total, total_pages = AdminService.get_all_traveler_profiles(
            db, page=page, limit=limit
        )
        return AdminListResponse[AdminTravelerProfileResponse](
            items=[AdminTravelerProfileResponse(**item) for item in items],
            total=total,
            page=page,
            limit=limit,
            total_pages=total_pages,
        )
    except AppError as e:
        raise create_http_exception(e) from e
    except Exception as e:
        raise create_http_exception(
            AppError("INTERNAL_ERROR", 500, "Failed to fetch traveler profiles")
        ) from e


@router.get(
    "/booking-intents",
    response_model=AdminListResponse[AdminBookingIntentResponse],
    summary="List all booking intents (admin)",
    description="Get all booking intents with trip and user information (admin only)",
)
async def list_all_booking_intents(
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(10, ge=1, le=100, description="Items per page"),
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    """Lister tous les booking intents (admin)."""
    try:
        items, total, total_pages = AdminService.get_all_booking_intents(db, page=page, limit=limit)
        return AdminListResponse[AdminBookingIntentResponse](
            items=[AdminBookingIntentResponse(**item) for item in items],
            total=total,
            page=page,
            limit=limit,
            total_pages=total_pages,
        )
    except AppError as e:
        raise create_http_exception(e) from e
    except Exception as e:
        raise create_http_exception(
            AppError("INTERNAL_ERROR", 500, "Failed to fetch booking intents")
        ) from e


@router.get(
    "/flight-searches",
    response_model=AdminListResponse[AdminFlightSearchResponse],
    summary="List all flight searches (admin)",
    description="Get all flight searches with trip information (admin only)",
)
async def list_all_flight_searches(
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(10, ge=1, le=100, description="Items per page"),
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    """Lister toutes les recherches de vols (admin)."""
    try:
        items, total, total_pages = AdminService.get_all_flight_searches(db, page=page, limit=limit)
        return AdminListResponse[AdminFlightSearchResponse](
            items=[AdminFlightSearchResponse(**item) for item in items],
            total=total,
            page=page,
            limit=limit,
            total_pages=total_pages,
        )
    except AppError as e:
        raise create_http_exception(e) from e
    except Exception as e:
        raise create_http_exception(
            AppError("INTERNAL_ERROR", 500, "Failed to fetch flight searches")
        ) from e


@router.get(
    "/accommodations",
    response_model=AdminListResponse[AdminAccommodationResponse],
    summary="List all accommodations (admin)",
    description="Get all accommodations with trip and user information (admin only)",
)
async def list_all_accommodations(
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(10, ge=1, le=100, description="Items per page"),
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    """Lister tous les hébergements (admin)."""
    try:
        items, total, total_pages = AdminService.get_all_accommodations(db, page=page, limit=limit)
        return AdminListResponse[AdminAccommodationResponse](
            items=[AdminAccommodationResponse(**item) for item in items],
            total=total,
            page=page,
            limit=limit,
            total_pages=total_pages,
        )
    except AppError as e:
        raise create_http_exception(e) from e
    except Exception as e:
        raise create_http_exception(
            AppError("INTERNAL_ERROR", 500, "Failed to fetch accommodations")
        ) from e


@router.get(
    "/activities",
    response_model=AdminListResponse[AdminActivityResponse],
    summary="List all activities (admin)",
    description="Get all activities with trip and user information (admin only)",
)
async def list_all_activities(
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(10, ge=1, le=100, description="Items per page"),
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    """Lister toutes les activités (admin)."""
    try:
        items, total, total_pages = AdminService.get_all_activities(db, page=page, limit=limit)
        return AdminListResponse[AdminActivityResponse](
            items=[AdminActivityResponse(**item) for item in items],
            total=total,
            page=page,
            limit=limit,
            total_pages=total_pages,
        )
    except AppError as e:
        raise create_http_exception(e) from e
    except Exception as e:
        raise create_http_exception(
            AppError("INTERNAL_ERROR", 500, "Failed to fetch activities")
        ) from e


@router.get(
    "/budget-items",
    response_model=AdminListResponse[AdminBudgetItemResponse],
    summary="List all budget items (admin)",
    description="Get all budget items with trip and user information (admin only)",
)
async def list_all_budget_items(
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(10, ge=1, le=100, description="Items per page"),
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    """Lister tous les budget items (admin)."""
    try:
        items, total, total_pages = AdminService.get_all_budget_items(db, page=page, limit=limit)
        return AdminListResponse[AdminBudgetItemResponse](
            items=[AdminBudgetItemResponse(**item) for item in items],
            total=total,
            page=page,
            limit=limit,
            total_pages=total_pages,
        )
    except AppError as e:
        raise create_http_exception(e) from e
    except Exception as e:
        raise create_http_exception(
            AppError("INTERNAL_ERROR", 500, "Failed to fetch budget items")
        ) from e


@router.get(
    "/baggage-items",
    response_model=AdminListResponse[AdminBaggageItemResponse],
    summary="List all baggage items (admin)",
    description="Get all baggage items with trip and user information (admin only)",
)
async def list_all_baggage_items(
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(10, ge=1, le=100, description="Items per page"),
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    """Lister tous les éléments de bagage (admin)."""
    try:
        items, total, total_pages = AdminService.get_all_baggage_items(db, page=page, limit=limit)
        return AdminListResponse[AdminBaggageItemResponse](
            items=[AdminBaggageItemResponse(**item) for item in items],
            total=total,
            page=page,
            limit=limit,
            total_pages=total_pages,
        )
    except AppError as e:
        raise create_http_exception(e) from e
    except Exception as e:
        raise create_http_exception(
            AppError("INTERNAL_ERROR", 500, "Failed to fetch baggage items")
        ) from e


@router.get(
    "/trip-shares",
    response_model=AdminListResponse[AdminTripShareResponse],
    summary="List all trip shares (admin)",
    description="Get all trip shares with trip and user information (admin only)",
)
async def list_all_trip_shares(
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(10, ge=1, le=100, description="Items per page"),
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    """Lister tous les partages de trips (admin)."""
    try:
        items, total, total_pages = AdminService.get_all_trip_shares(db, page=page, limit=limit)
        return AdminListResponse[AdminTripShareResponse](
            items=[AdminTripShareResponse(**item) for item in items],
            total=total,
            page=page,
            limit=limit,
            total_pages=total_pages,
        )
    except AppError as e:
        raise create_http_exception(e) from e
    except Exception as e:
        raise create_http_exception(
            AppError("INTERNAL_ERROR", 500, "Failed to fetch trip shares")
        ) from e


@router.get(
    "/feedbacks",
    response_model=AdminListResponse[AdminFeedbackResponse],
    summary="List all feedbacks (admin)",
    description="Get all feedbacks with trip and user information (admin only)",
)
async def list_all_feedbacks(
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(10, ge=1, le=100, description="Items per page"),
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    """Lister tous les feedbacks (admin)."""
    try:
        items, total, total_pages = AdminService.get_all_feedbacks(db, page=page, limit=limit)
        return AdminListResponse[AdminFeedbackResponse](
            items=[AdminFeedbackResponse(**item) for item in items],
            total=total,
            page=page,
            limit=limit,
            total_pages=total_pages,
        )
    except AppError as e:
        raise create_http_exception(e) from e
    except Exception as e:
        raise create_http_exception(
            AppError("INTERNAL_ERROR", 500, "Failed to fetch feedbacks")
        ) from e


@router.get(
    "/notifications",
    response_model=AdminListResponse[AdminNotificationResponse],
    summary="List all notifications (admin)",
    description="Get all notifications with user and trip information (admin only)",
)
async def list_all_notifications(
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(10, ge=1, le=100, description="Items per page"),
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    """Lister toutes les notifications (admin)."""
    try:
        items, total, total_pages = AdminService.get_all_notifications(db, page=page, limit=limit)
        return AdminListResponse[AdminNotificationResponse](
            items=[AdminNotificationResponse(**item) for item in items],
            total=total,
            page=page,
            limit=limit,
            total_pages=total_pages,
        )
    except AppError as e:
        raise create_http_exception(e) from e
    except Exception as e:
        raise create_http_exception(
            AppError("INTERNAL_ERROR", 500, "Failed to fetch notifications")
        ) from e


@router.delete(
    "/feedbacks/{feedbackId}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete feedback (admin)",
    description="Delete a feedback (admin only)",
)
async def delete_feedback(
    feedbackId: UUID,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    """Supprimer un feedback (admin)."""
    try:
        AdminService.delete_feedback(db, feedbackId)
    except AppError as e:
        raise create_http_exception(e) from e
    except Exception as e:
        raise create_http_exception(
            AppError("INTERNAL_ERROR", 500, "Failed to delete feedback")
        ) from e


@router.patch(
    "/users/{userId}/plan",
    summary="Update user plan (admin)",
    description="Change a user's plan (admin only)",
)
async def update_user_plan(
    userId: UUID,
    body: UpdatePlanRequest,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    """Mettre à jour le plan d'un utilisateur (admin)."""
    try:
        AdminService.update_user_plan(db, userId, body.plan)
        return {"message": "Plan updated", "user_id": str(userId), "plan": body.plan}
    except AppError as e:
        raise create_http_exception(e) from e
    except Exception as e:
        raise create_http_exception(
            AppError("INTERNAL_ERROR", 500, "Failed to update user plan")
        ) from e


@router.get(
    "/users/export",
    summary="Export users as CSV (admin)",
    description="Export all users as a CSV file (admin only)",
)
async def export_users_csv(
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    """Exporter tous les utilisateurs en CSV."""
    try:
        csv_content = AdminService.export_users_csv(db)
        return StreamingResponse(
            iter([csv_content]),
            media_type="text/csv",
            headers={"Content-Disposition": "attachment; filename=users.csv"},
        )
    except AppError as e:
        raise create_http_exception(e) from e
    except Exception as e:
        raise create_http_exception(
            AppError("INTERNAL_ERROR", 500, "Failed to export users")
        ) from e


@router.get(
    "/dashboard/metrics",
    summary="Get dashboard metrics (admin)",
    description="Get KPI metrics for the admin dashboard",
)
async def get_dashboard_metrics(
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    """Récupérer les métriques du tableau de bord."""
    try:
        metrics = AdminService.get_dashboard_metrics(db)
        return {"data": metrics}
    except AppError as e:
        raise create_http_exception(e) from e
    except Exception as e:
        raise create_http_exception(
            AppError("INTERNAL_ERROR", 500, "Failed to fetch metrics")
        ) from e


@router.get(
    "/dashboard/metrics/users-chart",
    summary="Get user registrations chart (admin)",
    description="Get user registrations grouped by period",
)
async def get_users_chart(
    period: str = Query("month", pattern="^(week|month|year)$"),
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    """Récupérer le graphique d'inscriptions utilisateurs."""
    try:
        data = AdminService.get_users_chart(db, period)
        return {"data": data}
    except AppError as e:
        raise create_http_exception(e) from e
    except Exception as e:
        raise create_http_exception(
            AppError("INTERNAL_ERROR", 500, "Failed to fetch users chart")
        ) from e


@router.get(
    "/dashboard/metrics/revenue-chart",
    summary="Get revenue chart (admin)",
    description="Get revenue grouped by period",
)
async def get_revenue_chart(
    period: str = Query("month", pattern="^(week|month|year)$"),
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    """Récupérer le graphique de revenus."""
    try:
        data = AdminService.get_revenue_chart(db, period)
        return {"data": data}
    except AppError as e:
        raise create_http_exception(e) from e
    except Exception as e:
        raise create_http_exception(
            AppError("INTERNAL_ERROR", 500, "Failed to fetch revenue chart")
        ) from e


@router.get(
    "/dashboard/metrics/feedbacks-chart",
    summary="Get feedbacks chart (admin)",
    description="Get feedbacks distribution by rating",
)
async def get_feedbacks_chart(
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    """Récupérer le graphique de distribution des feedbacks."""
    try:
        data = AdminService.get_feedbacks_chart(db)
        return {"data": data}
    except AppError as e:
        raise create_http_exception(e) from e
    except Exception as e:
        raise create_http_exception(
            AppError("INTERNAL_ERROR", 500, "Failed to fetch feedbacks chart")
        ) from e


@router.post(
    "/notifications/send",
    summary="Send notification to users (admin)",
    description="Send a push notification to one or more users (admin only)",
)
async def send_notification(
    body: AdminSendNotificationRequest,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    """Envoyer une notification aux utilisateurs sélectionnés."""
    try:
        notifications = NotificationService.create_and_send_bulk(
            db=db,
            user_ids=body.user_ids,
            trip_id=body.trip_id,
            notif_type=body.type,
            title=body.title,
            body=body.body,
        )
        return {
            "message": f"{len(notifications)} notification(s) sent",
            "count": len(notifications),
        }
    except AppError as e:
        raise create_http_exception(e) from e
    except Exception as e:
        raise create_http_exception(
            AppError("INTERNAL_ERROR", 500, "Failed to send notifications")
        ) from e

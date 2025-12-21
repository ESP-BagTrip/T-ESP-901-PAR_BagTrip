"""Routes pour les endpoints admin."""

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from src.api.admin.schemas import (
    AdminFlightBookingResponse,
    AdminHotelBookingResponse,
    AdminListResponse,
    AdminTravelerResponse,
    AdminTripResponse,
    AdminUserResponse,
)
from src.api.auth.middleware import get_current_user
from src.config.database import get_db
from src.models.user import User
from src.services.admin_service import AdminService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/admin", tags=["Admin"])


@router.get(
    "/users",
    response_model=AdminListResponse[AdminUserResponse],
    summary="List all users (admin)",
    description="Get all users with pagination (admin only)",
)
async def list_all_users(
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(10, ge=1, le=100, description="Items per page"),
    current_user: User = Depends(get_current_user),
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
        raise create_http_exception(
            AppError("INTERNAL_ERROR", 500, f"Failed to fetch users: {str(e)}")
        ) from e


@router.get(
    "/trips",
    response_model=AdminListResponse[AdminTripResponse],
    summary="List all trips (admin)",
    description="Get all trips with user information (admin only)",
)
async def list_all_trips(
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(10, ge=1, le=100, description="Items per page"),
    current_user: User = Depends(get_current_user),
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
        raise create_http_exception(
            AppError("INTERNAL_ERROR", 500, f"Failed to fetch trips: {str(e)}")
        ) from e


@router.get(
    "/travelers",
    response_model=AdminListResponse[AdminTravelerResponse],
    summary="List all travelers (admin)",
    description="Get all travelers with trip and user information (admin only)",
)
async def list_all_travelers(
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(10, ge=1, le=100, description="Items per page"),
    current_user: User = Depends(get_current_user),
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
            AppError("INTERNAL_ERROR", 500, f"Failed to fetch travelers: {str(e)}")
        ) from e


@router.get(
    "/hotel-bookings",
    response_model=AdminListResponse[AdminHotelBookingResponse],
    summary="List all hotel bookings (admin)",
    description="Get all hotel bookings with trip and user information (admin only)",
)
async def list_all_hotel_bookings(
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(10, ge=1, le=100, description="Items per page"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Lister toutes les hotel bookings (admin)."""
    try:
        items, total, total_pages = AdminService.get_all_hotel_bookings(db, page=page, limit=limit)
        return AdminListResponse[AdminHotelBookingResponse](
            items=[AdminHotelBookingResponse(**item) for item in items],
            total=total,
            page=page,
            limit=limit,
            total_pages=total_pages,
        )
    except AppError as e:
        raise create_http_exception(e) from e
    except Exception as e:
        raise create_http_exception(
            AppError("INTERNAL_ERROR", 500, f"Failed to fetch hotel bookings: {str(e)}")
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
    current_user: User = Depends(get_current_user),
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
            AppError("INTERNAL_ERROR", 500, f"Failed to fetch flight bookings: {str(e)}")
        ) from e

"""Routes pour les flight orders."""

from uuid import UUID

from fastapi import APIRouter, Depends, Path
from sqlalchemy.orm import Session

from src.api.auth.trip_access import TripAccess, TripRole, get_trip_access, get_trip_owner_access
from src.api.flights.orders.schemas import FlightOrderResponse
from src.config.database import get_db
from src.enums import FlightOrderStatus
from src.models.flight_order import FlightOrder
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/trips", tags=["Flight Orders"])


@router.get("/{tripId}/flights/orders", response_model=list[FlightOrderResponse])
async def list_flight_orders(
    access: TripAccess = Depends(get_trip_access),
    db: Session = Depends(get_db),
):
    """Liste les flight orders d'un trip."""
    try:
        orders = (
            db.query(FlightOrder)
            .filter(FlightOrder.trip_id == access.trip.id)
            .order_by(FlightOrder.created_at.desc())
            .all()
        )
        is_viewer = access.role == TripRole.VIEWER
        return [
            FlightOrderResponse(
                id=order.id,
                status=order.status,
                bookingReference=order.booking_reference,
                paymentId=None if is_viewer else order.payment_id,
                ticketUrl=order.ticket_url,
                createdAt=order.created_at,
            )
            for order in orders
        ]
    except AppError as e:
        raise create_http_exception(e) from e


@router.get(
    "/{tripId}/flights/orders/{orderId}",
    response_model=FlightOrderResponse,
)
async def get_flight_order(
    orderId: UUID = Path(..., description="Order ID"),
    access: TripAccess = Depends(get_trip_access),
    db: Session = Depends(get_db),
):
    """Récupère un flight order."""
    try:
        order = (
            db.query(FlightOrder)
            .filter(
                FlightOrder.id == orderId,
                FlightOrder.trip_id == access.trip.id,
            )
            .first()
        )
        if not order:
            raise AppError("ORDER_NOT_FOUND", 404, "Flight order not found")

        is_viewer = access.role == TripRole.VIEWER
        return FlightOrderResponse(
            id=order.id,
            status=order.status,
            bookingReference=order.booking_reference,
            paymentId=None if is_viewer else order.payment_id,
            ticketUrl=order.ticket_url,
            createdAt=order.created_at,
        )
    except AppError as e:
        raise create_http_exception(e) from e


@router.delete("/{tripId}/flights/orders/{orderId}", status_code=204)
async def delete_flight_order(
    orderId: UUID = Path(..., description="Order ID"),
    access: TripAccess = Depends(get_trip_owner_access),
    db: Session = Depends(get_db),
):
    """Supprime un flight order (interdit si confirmé)."""
    order = (
        db.query(FlightOrder)
        .filter(
            FlightOrder.id == orderId,
            FlightOrder.trip_id == access.trip.id,
        )
        .first()
    )
    if not order:
        raise AppError("ORDER_NOT_FOUND", 404, "Flight order not found")
    if order.status == FlightOrderStatus.CONFIRMED:
        raise AppError(
            "CONFIRMED_FLIGHT_IMMUTABLE",
            403,
            "Un vol confirmé ne peut pas être supprimé. Contactez la compagnie pour une annulation.",
        )
    db.delete(order)
    db.commit()

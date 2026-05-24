"""Admin service — dashboard KPIs and charts."""

from sqlalchemy import func
from sqlalchemy.orm import Session

from src.models.booking_intent import BookingIntent
from src.models.feedback import Feedback
from src.models.trip import Trip
from src.models.user import User


class AdminStatsService:
    """Dashboard KPIs and chart aggregations for the admin panel."""

    @staticmethod
    def get_dashboard_metrics(db: Session) -> dict:
        """Get dashboard KPI metrics."""
        total_users = db.query(func.count(User.id)).scalar() or 0

        active_users = db.query(func.count(func.distinct(Trip.user_id))).scalar() or 0
        inactive_users = total_users - active_users

        total_trips = db.query(func.count(Trip.id)).scalar() or 0

        total_revenue = (
            db.query(func.coalesce(func.sum(BookingIntent.amount), 0))
            .filter(BookingIntent.status == "CAPTURED")
            .scalar()
        )

        total_feedbacks = db.query(func.count(Feedback.id)).scalar() or 0
        pending_feedbacks = total_feedbacks

        avg_rating = db.query(func.avg(Feedback.overall_rating)).scalar()

        return {
            "totalUsers": total_users,
            "activeUsers": active_users,
            "inactiveUsers": inactive_users,
            "totalTrips": total_trips,
            "totalRevenue": float(total_revenue),
            "totalFeedbacks": total_feedbacks,
            "pendingFeedbacks": pending_feedbacks,
            "averageRating": round(float(avg_rating), 1) if avg_rating else 0,
        }

    @staticmethod
    def get_users_chart(db: Session, period: str = "month") -> list[dict]:
        """User registrations grouped by period."""
        if period == "week":
            trunc = func.date_trunc("day", User.created_at)
        elif period == "year":
            trunc = func.date_trunc("month", User.created_at)
        else:
            trunc = func.date_trunc("week", User.created_at)

        rows = (
            db.query(trunc.label("date"), func.count(User.id).label("value"))
            .group_by(trunc)
            .order_by(trunc)
            .all()
        )
        return [
            {
                "name": row.date.strftime("%Y-%m-%d"),
                "value": row.value,
                "date": row.date.strftime("%Y-%m-%d"),
            }
            for row in rows
        ]

    @staticmethod
    def get_revenue_chart(db: Session, period: str = "month") -> list[dict]:
        """Revenue grouped by period (captured booking intents)."""
        if period == "week":
            trunc = func.date_trunc("day", BookingIntent.created_at)
        elif period == "year":
            trunc = func.date_trunc("month", BookingIntent.created_at)
        else:
            trunc = func.date_trunc("week", BookingIntent.created_at)

        rows = (
            db.query(
                trunc.label("date"),
                func.coalesce(func.sum(BookingIntent.amount), 0).label("value"),
            )
            .filter(BookingIntent.status == "CAPTURED")
            .group_by(trunc)
            .order_by(trunc)
            .all()
        )
        return [
            {
                "name": row.date.strftime("%Y-%m-%d"),
                "value": float(row.value),
                "date": row.date.strftime("%Y-%m-%d"),
            }
            for row in rows
        ]

    @staticmethod
    def get_feedbacks_chart(db: Session) -> list[dict]:
        """Feedbacks count grouped by rating."""
        rows = (
            db.query(
                Feedback.overall_rating.label("rating"),
                func.count(Feedback.id).label("count"),
            )
            .group_by(Feedback.overall_rating)
            .order_by(Feedback.overall_rating)
            .all()
        )
        return [
            {"name": f"{row.rating} étoile{'s' if row.rating > 1 else ''}", "value": row.count}
            for row in rows
        ]

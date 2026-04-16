"""Backward-compat facade — delegates to the split admin sub-services.

Historically `AdminService` was a god-object (~990 LoC). The implementation now
lives in `src/services/admin/` split by domain (users, trips, bookings,
content, notifications, stats); this module keeps the public surface area
alive so routes and tests don't need a bulk rename.
"""

from src.services.admin.bookings import AdminBookingsService
from src.services.admin.content import AdminContentService
from src.services.admin.notifications import AdminNotificationsService
from src.services.admin.stats import AdminStatsService
from src.services.admin.trips import AdminTripsService
from src.services.admin.users import AdminUsersService

__all__ = [
    "AdminBookingsService",
    "AdminContentService",
    "AdminNotificationsService",
    "AdminService",
    "AdminStatsService",
    "AdminTripsService",
    "AdminUsersService",
]


class AdminService:
    """Facade over the split admin services — DO NOT add new methods here.

    New admin features belong to the relevant sub-service under
    `src/services/admin/`. This facade only preserves the historical public
    surface to avoid touching every admin route + test in a single PR.
    """

    # ──────────────────────── Users ────────────────────────
    get_all_users = staticmethod(AdminUsersService.get_all_users)
    get_all_traveler_profiles = staticmethod(AdminUsersService.get_all_traveler_profiles)
    update_user_plan = staticmethod(AdminUsersService.update_user_plan)
    get_user_detail = staticmethod(AdminUsersService.get_user_detail)
    update_user = staticmethod(AdminUsersService.update_user)
    reset_ai_quota = staticmethod(AdminUsersService.reset_ai_quota)
    ban_user = staticmethod(AdminUsersService.ban_user)
    unban_user = staticmethod(AdminUsersService.unban_user)
    delete_user = staticmethod(AdminUsersService.delete_user)
    bulk_update_plan = staticmethod(AdminUsersService.bulk_update_plan)
    bulk_ban = staticmethod(AdminUsersService.bulk_ban)
    export_users_csv = staticmethod(AdminUsersService.export_users_csv)

    # ──────────────────────── Trips ────────────────────────
    get_all_trips = staticmethod(AdminTripsService.get_all_trips)
    get_all_travelers = staticmethod(AdminTripsService.get_all_travelers)
    get_all_trip_shares = staticmethod(AdminTripsService.get_all_trip_shares)
    get_all_feedbacks = staticmethod(AdminTripsService.get_all_feedbacks)
    delete_feedback = staticmethod(AdminTripsService.delete_feedback)
    get_trip_detail = staticmethod(AdminTripsService.get_trip_detail)
    update_trip = staticmethod(AdminTripsService.update_trip)
    delete_trip = staticmethod(AdminTripsService.delete_trip)
    archive_trip = staticmethod(AdminTripsService.archive_trip)
    delete_share = staticmethod(AdminTripsService.delete_share)

    # ──────────────────────── Bookings ────────────────────────
    get_all_flight_bookings = staticmethod(AdminBookingsService.get_all_flight_bookings)
    get_all_booking_intents = staticmethod(AdminBookingsService.get_all_booking_intents)
    get_all_flight_searches = staticmethod(AdminBookingsService.get_all_flight_searches)
    get_booking_intent_detail = staticmethod(AdminBookingsService.get_booking_intent_detail)
    force_booking_status = staticmethod(AdminBookingsService.force_booking_status)

    # ──────────────────────── Content ────────────────────────
    get_all_accommodations = staticmethod(AdminContentService.get_all_accommodations)
    get_all_baggage_items = staticmethod(AdminContentService.get_all_baggage_items)
    get_all_activities = staticmethod(AdminContentService.get_all_activities)
    get_all_budget_items = staticmethod(AdminContentService.get_all_budget_items)
    create_activity = staticmethod(AdminContentService.create_activity)
    update_activity = staticmethod(AdminContentService.update_activity)
    delete_activity = staticmethod(AdminContentService.delete_activity)
    create_accommodation = staticmethod(AdminContentService.create_accommodation)
    update_accommodation = staticmethod(AdminContentService.update_accommodation)
    delete_accommodation = staticmethod(AdminContentService.delete_accommodation)
    delete_budget_item = staticmethod(AdminContentService.delete_budget_item)
    delete_baggage_item = staticmethod(AdminContentService.delete_baggage_item)

    # ──────────────────────── Notifications ────────────────────────
    get_all_notifications = staticmethod(AdminNotificationsService.get_all_notifications)

    # ──────────────────────── Stats / charts ────────────────────────
    get_dashboard_metrics = staticmethod(AdminStatsService.get_dashboard_metrics)
    get_users_chart = staticmethod(AdminStatsService.get_users_chart)
    get_revenue_chart = staticmethod(AdminStatsService.get_revenue_chart)
    get_feedbacks_chart = staticmethod(AdminStatsService.get_feedbacks_chart)

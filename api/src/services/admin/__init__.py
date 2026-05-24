"""Admin sub-services package.

The historical `AdminService` god-object has been split by domain into the
sub-services exported below. `src/services/admin_service.py` remains as a
backward-compat facade so existing routes and tests keep working unchanged.
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
    "AdminStatsService",
    "AdminTripsService",
    "AdminUsersService",
]

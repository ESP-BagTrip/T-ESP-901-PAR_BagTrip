"""FastAPI dependency for admin-only access."""

from fastapi import Depends

from src.api.auth.middleware import get_current_user
from src.models.user import User
from src.utils.errors import AppError


async def require_admin(
    current_user: User = Depends(get_current_user),
) -> User:
    """Dependency that requires ADMIN plan."""
    if getattr(current_user, "plan", None) != "ADMIN":
        raise AppError("FORBIDDEN", 403, "Admin access required")
    return current_user

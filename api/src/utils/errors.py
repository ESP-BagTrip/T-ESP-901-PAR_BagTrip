"""Gestion des erreurs HTTP."""

from fastapi import HTTPException


class AppError(Exception):
    """Erreur applicative personnalisée."""

    def __init__(
        self,
        code: str,
        status_code: int = 500,
        message: str | None = None,
        detail: dict | None = None,
    ):
        """Initialise l'erreur."""
        self.code = code
        self.status_code = status_code
        self.message = message or "An error occurred"
        self.detail = detail
        super().__init__(self.message)


def create_http_exception(error: AppError) -> HTTPException:
    """Convertit une AppError en HTTPException FastAPI."""
    return HTTPException(
        status_code=error.status_code,
        detail={
            "error": error.message,
            "code": error.code,
            **(error.detail or {}),
        },
    )

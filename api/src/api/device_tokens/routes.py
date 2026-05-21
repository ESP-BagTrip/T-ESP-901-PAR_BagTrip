"""Routes pour les device tokens FCM."""

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from src.api.auth.middleware import get_current_user
from src.api.device_tokens.schemas import (
    DeviceTokenRegisterRequest,
    DeviceTokenResponse,
    DeviceTokenUnregisterRequest,
)
from src.config.database import get_db
from src.models.user import User
from src.services.device_token_service import DeviceTokenService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/device-tokens", tags=["DeviceTokens"])


@router.post(
    "",
    response_model=DeviceTokenResponse,
    status_code=status.HTTP_201_CREATED,
)
async def register_device_token(
    request: DeviceTokenRegisterRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    """Enregistrer un token FCM pour l'utilisateur connecté."""
    try:
        token = DeviceTokenService.register(
            db=db,
            user_id=current_user.id,
            fcm_token=request.fcmToken,
            platform=request.platform,
            locale=request.locale,
        )
        return DeviceTokenResponse.model_validate(token)
    except AppError as e:
        raise create_http_exception(e) from e


@router.delete(
    "",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def unregister_device_token(
    request: DeviceTokenUnregisterRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    """Supprimer un token FCM.

    Le token transite par le body — pas par l'URL — pour ne pas fuiter
    dans les access logs.
    """
    try:
        DeviceTokenService.unregister(db, current_user.id, request.fcmToken)
    except AppError as e:
        raise create_http_exception(e) from e

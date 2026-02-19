"""Routes du profil voyageur."""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from src.api.auth.middleware import get_current_user
from src.api.profile.schemas import (
    ProfileCompletionResponse,
    ProfileCreateUpdateRequest,
    ProfileResponse,
)
from src.config.database import get_db
from src.models.user import User
from src.services.profile_service import ProfileService

router = APIRouter(prefix="/v1/profile", tags=["Profile"])


@router.get(
    "",
    response_model=ProfileResponse,
    summary="Get traveler profile",
    description="Retrieve the traveler profile for the current user. Creates an empty profile if none exists.",
)
async def get_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Récupérer le profil voyageur (crée un profil vide si inexistant)."""
    profile = ProfileService.get_profile(db, current_user.id)
    if not profile:
        profile = ProfileService.create_or_update_profile(db, current_user.id)
    return ProfileResponse(
        id=profile.id,
        travel_types=profile.travel_types,
        travel_style=profile.travel_style,
        budget=profile.budget,
        companions=profile.companions,
        is_completed=profile.is_completed,
        created_at=profile.created_at,
        updated_at=profile.updated_at,
    )


@router.put(
    "",
    response_model=ProfileResponse,
    summary="Create or update traveler profile",
    description="Upsert the traveler profile with personalization preferences.",
)
async def update_profile(
    request: ProfileCreateUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Créer ou mettre à jour le profil voyageur."""
    profile = ProfileService.create_or_update_profile(
        db=db,
        user_id=current_user.id,
        travel_types=request.travelTypes,
        travel_style=request.travelStyle,
        budget=request.budget,
        companions=request.companions,
    )
    return ProfileResponse(
        id=profile.id,
        travel_types=profile.travel_types,
        travel_style=profile.travel_style,
        budget=profile.budget,
        companions=profile.companions,
        is_completed=profile.is_completed,
        created_at=profile.created_at,
        updated_at=profile.updated_at,
    )


@router.get(
    "/completion",
    response_model=ProfileCompletionResponse,
    summary="Check profile completion",
    description="Check if the traveler profile is complete and return missing fields.",
)
async def check_completion(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Vérifier la completion du profil voyageur."""
    is_completed, missing_fields = ProfileService.check_completion(db, current_user.id)
    return ProfileCompletionResponse(
        is_completed=is_completed,
        missing_fields=missing_fields,
    )

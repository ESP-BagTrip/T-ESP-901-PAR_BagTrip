"""Service pour la gestion du profil voyageur."""

from uuid import UUID

from sqlalchemy.orm import Session

from src.models.traveler_profile import TravelerProfile


class ProfileService:
    """Service pour les opérations sur le profil voyageur."""

    @staticmethod
    def get_profile(db: Session, user_id: UUID) -> TravelerProfile | None:
        """Récupérer le profil voyageur d'un utilisateur."""
        return db.query(TravelerProfile).filter(TravelerProfile.user_id == user_id).first()

    @staticmethod
    def create_or_update_profile(
        db: Session,
        user_id: UUID,
        travel_types: list[str] | None = None,
        travel_style: str | None = None,
        budget: str | None = None,
        companions: str | None = None,
        medical_constraints: str | None = None,
        travel_frequency: str | None = None,
    ) -> TravelerProfile:
        """Créer ou mettre à jour le profil voyageur (upsert)."""
        profile = db.query(TravelerProfile).filter(TravelerProfile.user_id == user_id).first()

        if not profile:
            profile = TravelerProfile(user_id=user_id)
            db.add(profile)

        if travel_types is not None:
            profile.travel_types = travel_types
        if travel_style is not None:
            profile.travel_style = travel_style
        if budget is not None:
            profile.budget = budget
        if companions is not None:
            profile.companions = companions
        if medical_constraints is not None:
            profile.medical_constraints = medical_constraints
        if travel_frequency is not None:
            profile.travel_frequency = travel_frequency

        # Calculer is_completed : tous les champs doivent être renseignés
        profile.is_completed = all(
            [
                profile.travel_types,
                profile.travel_style,
                profile.budget,
                profile.companions,
            ]
        )

        db.commit()
        db.refresh(profile)
        return profile

    @staticmethod
    def check_completion(db: Session, user_id: UUID) -> tuple[bool, list[str]]:
        """Vérifier la completion du profil et retourner les champs manquants."""
        profile = db.query(TravelerProfile).filter(TravelerProfile.user_id == user_id).first()

        if not profile:
            return False, ["travelTypes", "travelStyle", "budget", "companions"]

        missing = []
        if not profile.travel_types:
            missing.append("travelTypes")
        if not profile.travel_style:
            missing.append("travelStyle")
        if not profile.budget:
            missing.append("budget")
        if not profile.companions:
            missing.append("companions")

        return len(missing) == 0, missing

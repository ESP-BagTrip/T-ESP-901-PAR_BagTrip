"""Service pour la gestion des contextes."""

from uuid import UUID

from sqlalchemy.orm import Session

from src.models.context import Context
from src.services.conversation_service import ConversationService
from src.utils.errors import AppError


class ContextService:
    """Service pour les opérations CRUD sur les contextes."""

    @staticmethod
    def get_context(
        db: Session,
        user_id: UUID,
        trip_id: UUID,
        conversation_id: UUID,
    ) -> Context | None:
        """
        Récupérer le contexte actuel (dernière version).
        - Rechercher le contexte avec la version la plus élevée
        - Vérifier ownership
        - Retourner None si non trouvé
        """
        # Vérifier que la conversation appartient à l'utilisateur
        conversation = ConversationService.get_conversation_by_id(
            db, conversation_id, user_id
        )
        if not conversation:
            return None

        # Récupérer le contexte avec la version la plus élevée
        context = (
            db.query(Context)
            .filter(
                Context.user_id == user_id,
                Context.trip_id == trip_id,
                Context.conversation_id == conversation_id,
            )
            .order_by(Context.version.desc())
            .first()
        )
        return context

    @staticmethod
    def create_context(
        db: Session,
        user_id: UUID,
        trip_id: UUID,
        conversation_id: UUID,
        state: dict,
        ui: dict,
    ) -> Context:
        """
        Créer un nouveau contexte (version 1).
        - Vérifier ownership
        - Créer avec version=1
        - Retourner le contexte créé
        """
        # Vérifier que la conversation appartient à l'utilisateur
        conversation = ConversationService.get_conversation_by_id(
            db, conversation_id, user_id
        )
        if not conversation:
            raise AppError("CONVERSATION_NOT_FOUND", 404, "Conversation not found")

        context = Context(
            user_id=user_id,
            trip_id=trip_id,
            conversation_id=conversation_id,
            version=1,
            state=state,
            ui=ui,
        )
        db.add(context)
        db.commit()
        db.refresh(context)
        return context

    @staticmethod
    def update_context(
        db: Session,
        context_id: UUID,
        state: dict,
        ui: dict,
        current_version: int,
    ) -> Context:
        """
        Mettre à jour un contexte (incrémenter version).
        - Vérifier que current_version correspond à la version actuelle
        - Incrémenter version
        - Mettre à jour state et ui
        - Retourner le contexte mis à jour
        """
        context = db.query(Context).filter(Context.id == context_id).first()
        if not context:
            raise AppError("CONTEXT_NOT_FOUND", 404, "Context not found")

        # Optimistic locking: vérifier que la version correspond
        if context.version != current_version:
            raise AppError(
                "CONTEXT_VERSION_MISMATCH",
                409,
                f"Context version mismatch. Expected {current_version}, "
                f"but current version is {context.version}",
            )

        # Mettre à jour le contexte
        context.version = current_version + 1
        context.state = state
        context.ui = ui

        db.commit()
        db.refresh(context)
        return context

    @staticmethod
    def increment_context_version(
        db: Session,
        context_id: UUID,
    ) -> int:
        """
        Incrémenter la version d'un contexte (sans modifier state/ui).
        Utile pour invalider un contexte sans le modifier.
        - Retourner la nouvelle version
        """
        context = db.query(Context).filter(Context.id == context_id).first()
        if not context:
            raise AppError("CONTEXT_NOT_FOUND", 404, "Context not found")

        context.version = context.version + 1
        db.commit()
        db.refresh(context)
        return context.version

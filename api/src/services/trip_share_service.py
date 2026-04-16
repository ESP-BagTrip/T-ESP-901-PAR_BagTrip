"""Service pour la gestion des partages de trips."""

import uuid as uuid_mod
from datetime import timezone, datetime, timedelta
from uuid import UUID

from sqlalchemy.orm import Session

from src.enums import NotificationType, ShareRole, TripStatus
from src.models.pending_invite import PendingInvite
from src.models.trip import Trip
from src.models.trip_share import TripShare
from src.models.user import User
from src.utils.errors import AppError
from src.utils.logger import logger


class TripShareService:
    """Service pour les opérations CRUD sur les partages de trips."""

    @staticmethod
    def _check_trip_not_completed(db: Session, trip_id: UUID) -> None:
        trip = db.query(Trip).filter(Trip.id == trip_id).first()
        if trip and trip.status == TripStatus.COMPLETED:
            raise AppError(
                "TRIP_COMPLETED",
                403,
                "Cannot modify shares on a completed trip.",
            )

    @staticmethod
    def _check_quota(db: Session, trip_id: UUID, owner_user_id: UUID) -> None:
        """Check share + pending invite quota."""
        from src.services.plan_service import PlanService

        owner = db.query(User).filter(User.id == owner_user_id).first()
        limit = PlanService.get_share_limit(owner) if owner else 2
        share_count = db.query(TripShare).filter(TripShare.trip_id == trip_id).count()
        pending_count = (
            db.query(PendingInvite)
            .filter(
                PendingInvite.trip_id == trip_id,
                PendingInvite.expires_at > datetime.now(timezone.utc),
            )
            .count()
        )
        total = share_count + pending_count
        if limit is not None and total >= limit:
            raise AppError(
                "SHARE_QUOTA_EXCEEDED",
                402,
                f"Maximum {limit} shares reached. Upgrade for more.",
            )

    @staticmethod
    def create_share(
        db: Session,
        trip_id: UUID,
        owner_user_id: UUID,
        email: str,
        message: str | None = None,
        role: ShareRole = ShareRole.VIEWER,
    ) -> dict:
        """Inviter un utilisateur par email à rejoindre un trip.
        Si l'utilisateur n'existe pas, crée une invitation en attente."""
        TripShareService._check_trip_not_completed(db, trip_id)

        # Resolve user by email
        user = db.query(User).filter(User.email == email).first()

        if user:
            # User exists — check not self-sharing by ID
            if user.id == owner_user_id:
                raise AppError("SELF_SHARING", 400, "Cannot share a trip with yourself")

            # Check not already shared
            existing = (
                db.query(TripShare)
                .filter(TripShare.trip_id == trip_id, TripShare.user_id == user.id)
                .first()
            )
            if existing:
                raise AppError("ALREADY_SHARED", 409, "Trip already shared with this user")

            # Check quota based on owner's plan
            from src.services.plan_service import PlanService

            owner = db.query(User).filter(User.id == owner_user_id).first()
            limit = PlanService.get_share_limit(owner) if owner else 2
            share_count = db.query(TripShare).filter(TripShare.trip_id == trip_id).count()
            if limit is not None and share_count >= limit:
                raise AppError(
                    "SHARE_QUOTA_EXCEEDED",
                    402,
                    f"Maximum {limit} shares reached. Upgrade for more.",
                )

            # Create share
            share = TripShare(trip_id=trip_id, user_id=user.id, role=role)
            db.add(share)
            db.commit()
            db.refresh(share)

            # Best-effort push notification to the invited user
            try:
                from src.services.notification_service import NotificationService

                trip = db.query(Trip).filter(Trip.id == trip_id).first()
                NotificationService.create_and_send(
                    db=db,
                    user_id=user.id,
                    trip_id=trip_id,
                    notif_type=NotificationType.TRIP_SHARED,
                    title="Nouveau voyage partagé !",
                    body=f"{owner.full_name or owner.email} vous a invité : {message}"
                    if message
                    else f"{owner.full_name or owner.email} vous a invité à « {trip.title or 'un voyage'} »",
                    data={"screen": "tripHome", "tripId": str(trip_id)},
                )
            except Exception as e:
                logger.error(f"[SHARE] Failed to send TRIP_SHARED notification: {e}")

            return {
                "id": share.id,
                "trip_id": share.trip_id,
                "user_id": share.user_id,
                "role": share.role,
                "invited_at": share.invited_at,
                "user_email": user.email,
                "user_full_name": user.full_name,
                "status": "active",
            }

        # User does not exist — check self-sharing by owner email
        owner = db.query(User).filter(User.id == owner_user_id).first()
        if owner and owner.email == email:
            raise AppError("SELF_SHARING", 400, "Cannot share a trip with yourself")

        # Create pending invite
        existing_pending = (
            db.query(PendingInvite)
            .filter(PendingInvite.trip_id == trip_id, PendingInvite.email == email)
            .first()
        )
        if existing_pending:
            raise AppError("ALREADY_SHARED", 409, "An invitation is already pending for this email")

        TripShareService._check_quota(db, trip_id, owner_user_id)

        token = str(uuid_mod.uuid4())
        pending = PendingInvite(
            trip_id=trip_id,
            email=email,
            role=role,
            token=token,
            message=message,
            invited_by=owner_user_id,
            expires_at=datetime.now(timezone.utc) + timedelta(days=7),
        )
        db.add(pending)
        db.commit()
        db.refresh(pending)

        return {
            "id": pending.id,
            "trip_id": pending.trip_id,
            "user_id": None,
            "role": pending.role,
            "invited_at": pending.created_at,
            "user_email": email,
            "user_full_name": None,
            "status": "pending",
            "invite_token": token,
        }

    @staticmethod
    def get_shares_by_trip(db: Session, trip_id: UUID) -> list[dict]:
        """Récupérer tous les partages d'un trip."""
        shares = (
            db.query(
                TripShare, User.email.label("user_email"), User.full_name.label("user_full_name")
            )
            .join(User, TripShare.user_id == User.id)
            .filter(TripShare.trip_id == trip_id)
            .all()
        )
        return [
            {
                "id": share.id,
                "trip_id": share.trip_id,
                "user_id": share.user_id,
                "role": share.role,
                "invited_at": share.invited_at,
                "user_email": user_email,
                "user_full_name": user_full_name,
            }
            for share, user_email, user_full_name in shares
        ]

    @staticmethod
    def get_pending_invites_by_trip(db: Session, trip_id: UUID) -> list[dict]:
        """Récupérer les invitations en attente d'un trip."""
        pending = (
            db.query(PendingInvite)
            .filter(
                PendingInvite.trip_id == trip_id,
                PendingInvite.expires_at > datetime.now(timezone.utc),
            )
            .all()
        )
        return [
            {
                "id": p.id,
                "trip_id": p.trip_id,
                "email": p.email,
                "role": p.role,
                "token": p.token,
                "created_at": p.created_at,
                "expires_at": p.expires_at,
            }
            for p in pending
        ]

    @staticmethod
    def delete_share(db: Session, share_id: UUID, trip_id: UUID) -> None:
        """Révoquer un partage."""
        TripShareService._check_trip_not_completed(db, trip_id)
        share = (
            db.query(TripShare)
            .filter(TripShare.id == share_id, TripShare.trip_id == trip_id)
            .first()
        )
        if not share:
            raise AppError("SHARE_NOT_FOUND", 404, "Share not found")

        db.delete(share)
        db.commit()

    @staticmethod
    def delete_pending_invite(db: Session, invite_id: UUID, trip_id: UUID) -> None:
        """Révoquer une invitation en attente."""
        TripShareService._check_trip_not_completed(db, trip_id)
        invite = (
            db.query(PendingInvite)
            .filter(PendingInvite.id == invite_id, PendingInvite.trip_id == trip_id)
            .first()
        )
        if not invite:
            raise AppError("INVITE_NOT_FOUND", 404, "Pending invite not found")

        db.delete(invite)
        db.commit()

    @staticmethod
    def accept_invite(db: Session, token: str, user_id: UUID) -> dict:
        """Accepter une invitation par token."""
        invite = db.query(PendingInvite).filter(PendingInvite.token == token).first()
        if not invite:
            raise AppError("INVITE_NOT_FOUND", 404, "Invite not found or expired")

        if invite.expires_at < datetime.now(timezone.utc):
            db.delete(invite)
            db.commit()
            raise AppError("INVITE_EXPIRED", 410, "This invite has expired")

        # Check not already shared
        existing = (
            db.query(TripShare)
            .filter(TripShare.trip_id == invite.trip_id, TripShare.user_id == user_id)
            .first()
        )
        if existing:
            db.delete(invite)
            db.commit()
            raise AppError("ALREADY_SHARED", 409, "You already have access to this trip")

        # Create the share
        share = TripShare(trip_id=invite.trip_id, user_id=user_id, role=invite.role)
        db.add(share)
        db.delete(invite)
        db.commit()
        db.refresh(share)

        user = db.query(User).filter(User.id == user_id).first()
        return {
            "id": share.id,
            "trip_id": share.trip_id,
            "user_id": share.user_id,
            "role": share.role,
            "invited_at": share.invited_at,
            "user_email": user.email if user else "",
            "user_full_name": user.full_name if user else None,
        }

    @staticmethod
    def claim_pending_invites(db: Session, email: str, user_id: UUID) -> int:
        """Réclamer toutes les invitations en attente pour un email (appelé à l'inscription).
        Retourne le nombre d'invitations réclamées."""
        pending = (
            db.query(PendingInvite)
            .filter(
                PendingInvite.email == email,
                PendingInvite.expires_at > datetime.now(timezone.utc),
            )
            .all()
        )
        claimed = 0
        for invite in pending:
            existing = (
                db.query(TripShare)
                .filter(TripShare.trip_id == invite.trip_id, TripShare.user_id == user_id)
                .first()
            )
            if not existing:
                share = TripShare(trip_id=invite.trip_id, user_id=user_id, role=invite.role)
                db.add(share)
                claimed += 1
            db.delete(invite)
        if claimed:
            db.commit()
        return claimed

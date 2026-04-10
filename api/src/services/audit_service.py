"""Service de journalisation des actions admin."""

from math import ceil

from sqlalchemy.orm import Session

from src.models.audit_log import AuditLog
from src.models.user import User


class AuditService:
    """Log and query admin audit entries."""

    @staticmethod
    def log(
        db: Session,
        actor_id,
        action: str,
        entity_type: str,
        entity_id,
        diff: dict | None = None,
        metadata: dict | None = None,
    ) -> AuditLog:
        """Create an audit log entry."""
        entry = AuditLog(
            actor_id=actor_id,
            action=action,
            entity_type=entity_type,
            entity_id=entity_id,
            diff_json=diff,
            metadata_=metadata,
        )
        db.add(entry)
        db.commit()
        db.refresh(entry)
        return entry

    @staticmethod
    def get_logs(
        db: Session,
        page: int = 1,
        limit: int = 20,
        entity_type: str | None = None,
        entity_id: str | None = None,
        actor_id: str | None = None,
        action: str | None = None,
    ) -> tuple[list[dict], int, int]:
        """Query audit logs with optional filters."""
        query = (
            db.query(AuditLog, User.email.label("actor_email"))
            .join(User, AuditLog.actor_id == User.id)
            .order_by(AuditLog.created_at.desc())
        )

        if entity_type:
            query = query.filter(AuditLog.entity_type == entity_type)
        if entity_id:
            query = query.filter(AuditLog.entity_id == entity_id)
        if actor_id:
            query = query.filter(AuditLog.actor_id == actor_id)
        if action:
            query = query.filter(AuditLog.action == action)

        total = query.count()
        offset = (page - 1) * limit
        results = query.offset(offset).limit(limit).all()

        items = []
        for log, actor_email in results:
            items.append(
                {
                    "id": log.id,
                    "actor_id": log.actor_id,
                    "actor_email": actor_email,
                    "action": log.action,
                    "entity_type": log.entity_type,
                    "entity_id": log.entity_id,
                    "diff_json": log.diff_json,
                    "metadata": log.metadata_,
                    "created_at": log.created_at,
                }
            )

        total_pages = ceil(total / limit) if limit > 0 else 0
        return items, total, total_pages

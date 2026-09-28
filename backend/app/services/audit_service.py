from typing import Optional, Dict, Any
from datetime import datetime, timezone
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.timeline import TimelineEvent
from app.models.audit import AuditLog

class AuditService:
    @staticmethod
    async def log_timeline(
        db: AsyncSession,
        case_id: int,
        event_type: str,
        description: str,
        actor_id: Optional[int] = None,
        old_state: Optional[Dict[str, Any]] = None,
        new_state: Optional[Dict[str, Any]] = None
    ) -> TimelineEvent:
        event = TimelineEvent(
            case_id=case_id,
            actor_id=actor_id,
            event_type=event_type,
            description=description,
            old_state=old_state,
            new_state=new_state,
            created_at=datetime.now(timezone.utc)
        )
        db.add(event)
        return event

    @staticmethod
    async def log_audit(
        db: AsyncSession,
        action: str,
        entity_type: str,
        entity_id: Optional[int] = None,
        actor_id: Optional[int] = None,
        previous_state: Optional[Dict[str, Any]] = None,
        new_state: Optional[Dict[str, Any]] = None,
        ip_address: Optional[str] = None
    ) -> AuditLog:
        audit = AuditLog(
            actor_id=actor_id,
            action=action,
            entity_type=entity_type,
            entity_id=entity_id,
            previous_state=previous_state,
            new_state=new_state,
            ip_address=ip_address,
            created_at=datetime.now(timezone.utc)
        )
        db.add(audit)
        return audit

audit_service = AuditService()

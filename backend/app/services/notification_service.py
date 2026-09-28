from typing import Optional, List
from datetime import datetime, timezone
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.notification import InAppNotification

class NotificationService:
    @staticmethod
    async def create_notification(
        db: AsyncSession,
        user_id: int,
        title: str,
        message: str,
        notification_type: str = "INFO",
        case_id: Optional[int] = None
    ) -> InAppNotification:
        notification = InAppNotification(
            user_id=user_id,
            case_id=case_id,
            title=title,
            message=message,
            notification_type=notification_type,
            is_read=False,
            created_at=datetime.now(timezone.utc)
        )
        db.add(notification)
        return notification

    @staticmethod
    async def get_user_notifications(
        db: AsyncSession,
        user_id: int,
        unread_only: bool = False
    ) -> List[InAppNotification]:
        stmt = select(InAppNotification).where(InAppNotification.user_id == user_id)
        if unread_only:
            stmt = stmt.where(InAppNotification.is_read == False)
        stmt = stmt.order_by(InAppNotification.created_at.desc()).limit(50)
        res = await db.execute(stmt)
        return list(res.scalars().all())

    @staticmethod
    async def mark_as_read(
        db: AsyncSession,
        notification_id: int,
        user_id: int
    ) -> Optional[InAppNotification]:
        stmt = select(InAppNotification).where(
            InAppNotification.id == notification_id,
            InAppNotification.user_id == user_id
        )
        res = await db.execute(stmt)
        notification = res.scalar_one_or_none()
        if notification:
            notification.is_read = True
            notification.read_at = datetime.now(timezone.utc)
            await db.commit()
            await db.refresh(notification)
        return notification

notification_service = NotificationService()

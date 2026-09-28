import os
import hashlib
from typing import List, Optional
from datetime import datetime, timezone
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import UploadFile

from app.core.config import settings
from app.core.exceptions import EntityNotFoundError, PermissionDeniedError
from app.models.case import Case, CaseStatus
from app.models.user import User, UserRole
from app.models.communication import CaseMessage, InternalNote, CaseAttachment
from app.schemas.communication import CaseMessageCreate, InternalNoteCreate
from app.services.audit_service import audit_service
from app.services.notification_service import notification_service
from app.services.storage_service import storage_service

class CommunicationService:
    @staticmethod
    async def add_message(
        db: AsyncSession,
        case: Case,
        sender: User,
        message_in: CaseMessageCreate
    ) -> CaseMessage:
        msg = CaseMessage(
            case_id=case.id,
            sender_id=sender.id,
            message=message_in.message,
            is_information_request=message_in.is_information_request,
            is_ai_drafted=message_in.is_ai_drafted,
            created_at=datetime.now(timezone.utc)
        )
        db.add(msg)
        await db.flush()

        # If it is an information request from operator, set status to WAITING_FOR_INFORMATION
        if message_in.is_information_request and sender.role in [UserRole.OPERATOR, UserRole.TEAM_LEAD, UserRole.ADMIN]:
            if case.status in [CaseStatus.ASSIGNED, CaseStatus.INVESTIGATING]:
                case.status = CaseStatus.WAITING_FOR_INFORMATION
                case.updated_at = datetime.now(timezone.utc)
                await audit_service.log_timeline(
                    db=db,
                    case_id=case.id,
                    actor_id=sender.id,
                    event_type="INFO_REQUESTED",
                    description=f"{sender.full_name} requested missing information from the requester."
                )
                await notification_service.create_notification(
                    db=db,
                    user_id=case.requester_id,
                    case_id=case.id,
                    title=f"Information Needed: Case {case.case_number}",
                    message=f"IT Support requested additional details: {message_in.message[:100]}...",
                    notification_type="INFO_REQUEST"
                )

        # If requester responded while waiting for info, move back to INVESTIGATING
        elif sender.id == case.requester_id and case.status == CaseStatus.WAITING_FOR_INFORMATION:
            case.status = CaseStatus.INVESTIGATING
            case.updated_at = datetime.now(timezone.utc)
            await audit_service.log_timeline(
                db=db,
                case_id=case.id,
                actor_id=sender.id,
                event_type="REQUESTER_RESPONDED",
                description=f"Requester {sender.full_name} responded with clarification."
            )
            if case.assigned_operator_id:
                await notification_service.create_notification(
                    db=db,
                    user_id=case.assigned_operator_id,
                    case_id=case.id,
                    title=f"Response Received on {case.case_number}",
                    message=f"{sender.full_name} responded to your inquiry.",
                    notification_type="MESSAGE"
                )

        await db.commit()
        await db.refresh(msg)
        return msg

    @staticmethod
    async def get_messages(
        db: AsyncSession,
        case_id: int
    ) -> List[CaseMessage]:
        stmt = select(CaseMessage).where(
            CaseMessage.case_id == case_id
        ).options(
            selectinload(CaseMessage.sender),
            selectinload(CaseMessage.attachments)
        ).order_by(CaseMessage.created_at.asc())
        res = await db.execute(stmt)
        return list(res.scalars().all())

    @staticmethod
    async def add_internal_note(
        db: AsyncSession,
        case: Case,
        author: User,
        note_in: InternalNoteCreate
    ) -> InternalNote:
        if author.role == UserRole.REQUESTER:
            raise PermissionDeniedError("Requesters cannot create internal notes.")

        note = InternalNote(
            case_id=case.id,
            author_id=author.id,
            note=note_in.note,
            created_at=datetime.now(timezone.utc)
        )
        db.add(note)

        await audit_service.log_timeline(
            db=db,
            case_id=case.id,
            actor_id=author.id,
            event_type="INTERNAL_NOTE_ADDED",
            description=f"Private internal note added by {author.full_name}."
        )

        await db.commit()
        await db.refresh(note)
        return note

    @staticmethod
    async def get_internal_notes(
        db: AsyncSession,
        case_id: int,
        viewer: User
    ) -> List[InternalNote]:
        if viewer.role == UserRole.REQUESTER:
            return []  # Strictly scrubbed from requesters

        stmt = select(InternalNote).where(
            InternalNote.case_id == case_id
        ).options(
            selectinload(InternalNote.author)
        ).order_by(InternalNote.created_at.asc())
        res = await db.execute(stmt)
        return list(res.scalars().all())

    @staticmethod
    async def save_attachment(
        db: AsyncSession,
        case: Case,
        uploader: User,
        file: UploadFile,
        message_id: Optional[int] = None
    ) -> CaseAttachment:
        file_path, file_hash, file_size, mime_type = await storage_service.upload_file(file)

        attachment = CaseAttachment(
            case_id=case.id,
            message_id=message_id,
            uploader_id=uploader.id,
            file_name=file.filename or "attachment",
            file_path=file_path,
            file_size_bytes=file_size,
            mime_type=mime_type,
            file_hash=file_hash,
            created_at=datetime.now(timezone.utc)
        )
        db.add(attachment)

        await audit_service.log_timeline(
            db=db,
            case_id=case.id,
            actor_id=uploader.id,
            event_type="ATTACHMENT_UPLOADED",
            description=f"File '{file.filename}' uploaded by {uploader.full_name}."
        )

        await db.commit()
        await db.refresh(attachment)
        return attachment

communication_service = CommunicationService()

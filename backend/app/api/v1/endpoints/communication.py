from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.api.deps import get_current_user, require_roles
from app.models.user import User, UserRole
from app.models.case import Case
from app.schemas.communication import (
    CaseMessageCreate, CaseMessageOut,
    InternalNoteCreate, InternalNoteOut,
    CaseAttachmentOut
)
from app.services.case_service import case_service
from app.services.communication_service import communication_service

router = APIRouter()

@router.get("/{case_id}/messages", response_model=List[CaseMessageOut])
async def get_messages(
    case_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    case = await case_service.get_case_by_id(db, case_id)
    if not case:
        raise HTTPException(status_code=404, detail="Case not found")

    if current_user.role == UserRole.REQUESTER and case.requester_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to view messages")

    return await communication_service.get_messages(db, case_id)

@router.post("/{case_id}/messages", response_model=CaseMessageOut, status_code=status.HTTP_201_CREATED)
async def post_message(
    case_id: int,
    msg_in: CaseMessageCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    case = await case_service.get_case_by_id(db, case_id)
    if not case:
        raise HTTPException(status_code=404, detail="Case not found")

    if current_user.role == UserRole.REQUESTER and case.requester_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to post to this case")

    return await communication_service.add_message(db, case, current_user, msg_in)

@router.get("/{case_id}/internal-notes", response_model=List[InternalNoteOut])
async def get_internal_notes(
    case_id: int,
    current_user: User = Depends(require_roles(UserRole.OPERATOR, UserRole.TEAM_LEAD, UserRole.MANAGER, UserRole.ADMIN)),
    db: AsyncSession = Depends(get_db)
):
    return await communication_service.get_internal_notes(db, case_id, current_user)

@router.post("/{case_id}/internal-notes", response_model=InternalNoteOut, status_code=status.HTTP_201_CREATED)
async def create_internal_note(
    case_id: int,
    note_in: InternalNoteCreate,
    current_user: User = Depends(require_roles(UserRole.OPERATOR, UserRole.TEAM_LEAD, UserRole.MANAGER, UserRole.ADMIN)),
    db: AsyncSession = Depends(get_db)
):
    case = await case_service.get_case_by_id(db, case_id)
    if not case:
        raise HTTPException(status_code=404, detail="Case not found")

    return await communication_service.add_internal_note(db, case, current_user, note_in)

@router.post("/{case_id}/attachments", response_model=CaseAttachmentOut, status_code=status.HTTP_201_CREATED)
async def upload_attachment(
    case_id: int,
    file: UploadFile = File(...),
    message_id: Optional[int] = Form(None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    case = await case_service.get_case_by_id(db, case_id)
    if not case:
        raise HTTPException(status_code=404, detail="Case not found")

    return await communication_service.save_attachment(
        db=db,
        case=case,
        uploader=current_user,
        file=file,
        message_id=message_id
    )

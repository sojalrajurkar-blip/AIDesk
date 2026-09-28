from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.api.deps import get_current_user, require_roles
from app.models.user import User, UserRole
from app.models.task import CaseTask
from app.models.investigation import InvestigationRecord
from app.schemas.task import (
    CaseTaskCreate, CaseTaskUpdate, CaseTaskOut,
    InvestigationRecordCreate, InvestigationRecordOut
)
from app.services.case_service import case_service
from app.services.task_service import task_service

router = APIRouter()

@router.get("/{case_id}/tasks", response_model=List[CaseTaskOut])
async def list_case_tasks(
    case_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(CaseTask).where(
        CaseTask.case_id == case_id
    ).options(
        selectinload(CaseTask.assignee)
    ).order_by(CaseTask.created_at.asc())
    res = await db.execute(stmt)
    return list(res.scalars().all())

@router.post("/{case_id}/tasks", response_model=CaseTaskOut, status_code=status.HTTP_201_CREATED)
async def create_case_task(
    case_id: int,
    task_in: CaseTaskCreate,
    current_user: User = Depends(require_roles(UserRole.OPERATOR, UserRole.TEAM_LEAD, UserRole.MANAGER, UserRole.ADMIN)),
    db: AsyncSession = Depends(get_db)
):
    case = await case_service.get_case_by_id(db, case_id)
    if not case:
        raise HTTPException(status_code=404, detail="Case not found")

    return await task_service.create_task(db, case, current_user, task_in)

@router.patch("/{case_id}/tasks/{task_id}", response_model=CaseTaskOut)
async def update_case_task(
    case_id: int,
    task_id: int,
    task_in: CaseTaskUpdate,
    current_user: User = Depends(require_roles(UserRole.OPERATOR, UserRole.TEAM_LEAD, UserRole.MANAGER, UserRole.ADMIN)),
    db: AsyncSession = Depends(get_db)
):
    return await task_service.update_task(db, task_id, current_user, task_in)

@router.get("/{case_id}/investigation", response_model=List[InvestigationRecordOut])
async def get_investigation_records(
    case_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(InvestigationRecord).where(
        InvestigationRecord.case_id == case_id
    ).options(
        selectinload(InvestigationRecord.investigator)
    ).order_by(InvestigationRecord.created_at.desc())
    res = await db.execute(stmt)
    return list(res.scalars().all())

@router.post("/{case_id}/investigation", response_model=InvestigationRecordOut, status_code=status.HTTP_201_CREATED)
async def record_investigation(
    case_id: int,
    inv_in: InvestigationRecordCreate,
    current_user: User = Depends(require_roles(UserRole.OPERATOR, UserRole.TEAM_LEAD, UserRole.MANAGER, UserRole.ADMIN)),
    db: AsyncSession = Depends(get_db)
):
    case = await case_service.get_case_by_id(db, case_id)
    if not case:
        raise HTTPException(status_code=404, detail="Case not found")

    return await task_service.record_investigation(db, case, current_user, inv_in)

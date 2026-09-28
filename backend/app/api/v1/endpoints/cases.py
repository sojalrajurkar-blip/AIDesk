from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.db.session import get_db
from app.api.deps import get_current_user, require_roles
from app.models.user import User, UserRole
from app.models.case import Case, CaseStatus, CasePriority
from app.models.timeline import TimelineEvent
from app.schemas.case import (
    CaseCreate, CaseUpdate, CaseOut, CaseDetailOut,
    StatusTransitionRequest, AssignCaseRequest
)
from app.schemas.sla import CaseEscalationCreate, CaseEscalationOut
from app.schemas.audit import TimelineEventOut
from app.services.case_service import case_service

router = APIRouter()

@router.get("", response_model=List[CaseOut])
async def list_cases(
    status: Optional[CaseStatus] = None,
    priority: Optional[CasePriority] = None,
    category_id: Optional[int] = None,
    team_id: Optional[int] = None,
    operator_id: Optional[int] = None,
    search: Optional[str] = None,
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    return await case_service.list_cases(
        db=db,
        current_user=current_user,
        status=status,
        priority=priority,
        category_id=category_id,
        team_id=team_id,
        operator_id=operator_id,
        search=search,
        limit=limit,
        offset=offset
    )

@router.post("", response_model=CaseOut, status_code=status.HTTP_201_CREATED)
async def create_case(
    case_in: CaseCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    return await case_service.create_case(
        db=db,
        case_in=case_in,
        requester=current_user
    )

@router.get("/{case_id}", response_model=CaseDetailOut)
async def get_case(
    case_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    case = await case_service.get_case_by_id(db, case_id)
    if not case:
        raise HTTPException(status_code=404, detail="Case not found")

    # Requester authorization check
    if current_user.role == UserRole.REQUESTER and case.requester_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to view this case")

    # Compute count stats
    detail = CaseDetailOut.model_validate(case)
    detail.messages_count = len(case.messages)
    detail.tasks_count = len(case.tasks)
    detail.attachments_count = len(case.attachments)
    return detail

@router.post("/{case_id}/transition", response_model=CaseOut)
async def transition_case_status(
    case_id: int,
    trans_req: StatusTransitionRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    case = await case_service.get_case_by_id(db, case_id)
    if not case:
        raise HTTPException(status_code=404, detail="Case not found")

    # Authorization
    if current_user.role == UserRole.REQUESTER and trans_req.target_status not in [CaseStatus.CANCELLED, CaseStatus.CONFIRMED, CaseStatus.REOPENED]:
        raise HTTPException(status_code=403, detail="Requesters cannot set arbitrary statuses.")

    return await case_service.transition_status(
        db=db,
        case=case,
        target_status=trans_req.target_status,
        actor=current_user,
        comment=trans_req.comment
    )

@router.post("/{case_id}/assign", response_model=CaseOut)
async def assign_case(
    case_id: int,
    assign_req: AssignCaseRequest,
    current_user: User = Depends(require_roles(UserRole.OPERATOR, UserRole.TEAM_LEAD, UserRole.MANAGER, UserRole.ADMIN)),
    db: AsyncSession = Depends(get_db)
):
    case = await case_service.get_case_by_id(db, case_id)
    if not case:
        raise HTTPException(status_code=404, detail="Case not found")

    return await case_service.assign_case(
        db=db,
        case=case,
        actor=current_user,
        assigned_team_id=assign_req.assigned_team_id,
        assigned_operator_id=assign_req.assigned_operator_id,
        comment=assign_req.comment
    )

@router.post("/{case_id}/escalate", response_model=CaseEscalationOut)
async def escalate_case(
    case_id: int,
    esc_in: CaseEscalationCreate,
    current_user: User = Depends(require_roles(UserRole.OPERATOR, UserRole.TEAM_LEAD, UserRole.MANAGER, UserRole.ADMIN)),
    db: AsyncSession = Depends(get_db)
):
    case = await case_service.get_case_by_id(db, case_id)
    if not case:
        raise HTTPException(status_code=404, detail="Case not found")

    return await case_service.escalate_case(
        db=db,
        case=case,
        actor=current_user,
        reason=esc_in.reason,
        new_priority=esc_in.new_priority
    )

@router.get("/{case_id}/timeline", response_model=List[TimelineEventOut])
async def get_case_timeline(
    case_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    case = await case_service.get_case_by_id(db, case_id)
    if not case:
        raise HTTPException(status_code=404, detail="Case not found")

    if current_user.role == UserRole.REQUESTER and case.requester_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")

    stmt = select(TimelineEvent).where(
        TimelineEvent.case_id == case_id
    ).options(
        selectinload(TimelineEvent.actor)
    ).order_by(TimelineEvent.created_at.asc())
    
    res = await db.execute(stmt)
    return list(res.scalars().all())

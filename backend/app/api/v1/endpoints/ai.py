from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.api.deps import get_current_user, require_roles
from app.models.user import User, UserRole
from app.models.case import Case
from app.models.ai_analysis import AICaseAnalysis
from app.schemas.ai import (
    AITriageRequest, AITriageResponse, AICaseAnalysisOut,
    AISummaryResponse, AIDraftResponse
)
from app.services.case_service import case_service
from app.services.ai_service import ai_service

router = APIRouter()

@router.post("/triage", response_model=AITriageResponse)
async def live_ai_triage(
    triage_req: AITriageRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    return await ai_service.analyze_and_triage(
        db=db,
        title=triage_req.title,
        description=triage_req.description,
        location=triage_req.location
    )

@router.get("/cases/{case_id}/analysis", response_model=List[AICaseAnalysisOut])
async def get_case_ai_analyses(
    case_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(AICaseAnalysis).where(
        AICaseAnalysis.case_id == case_id
    ).options(
        selectinload(AICaseAnalysis.suggested_category),
        selectinload(AICaseAnalysis.suggested_team)
    ).order_by(AICaseAnalysis.created_at.desc())
    res = await db.execute(stmt)
    return list(res.scalars().all())

@router.get("/cases/{case_id}/summary", response_model=AISummaryResponse)
async def get_ai_case_summary(
    case_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    case = await case_service.get_case_by_id(db, case_id)
    if not case:
        raise HTTPException(status_code=404, detail="Case not found")

    return await ai_service.generate_summary(case)

@router.get("/cases/{case_id}/draft", response_model=AIDraftResponse)
async def generate_ai_draft(
    case_id: int,
    draft_type: str = Query("INFO_REQUEST", pattern="^(INFO_REQUEST|ESCALATION|RESOLUTION|STATUS_UPDATE)$"),
    context: Optional[str] = None,
    current_user: User = Depends(require_roles(UserRole.OPERATOR, UserRole.TEAM_LEAD, UserRole.MANAGER, UserRole.ADMIN)),
    db: AsyncSession = Depends(get_db)
):
    case = await case_service.get_case_by_id(db, case_id)
    if not case:
        raise HTTPException(status_code=404, detail="Case not found")

    return await ai_service.generate_communication_draft(
        draft_type=draft_type,
        case=case,
        extra_context=context
    )

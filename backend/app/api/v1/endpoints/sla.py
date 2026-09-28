from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.api.deps import get_current_user, require_roles
from app.models.user import User, UserRole
from app.models.sla import SLAPolicy, CaseRiskRecord
from app.schemas.sla import SLAPolicyOut, SLAPolicyCreate, CaseRiskRecordOut
from app.services.case_service import case_service
from app.services.sla_service import sla_service

router = APIRouter()

@router.get("/policies", response_model=List[SLAPolicyOut])
async def list_sla_policies(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(SLAPolicy).order_by(SLAPolicy.response_time_minutes.asc())
    res = await db.execute(stmt)
    return list(res.scalars().all())

@router.post("/policies", response_model=SLAPolicyOut, status_code=status.HTTP_201_CREATED)
async def create_sla_policy(
    policy_in: SLAPolicyCreate,
    current_user: User = Depends(require_roles(UserRole.ADMIN)),
    db: AsyncSession = Depends(get_db)
):
    policy = SLAPolicy(**policy_in.model_dump())
    db.add(policy)
    await db.commit()
    await db.refresh(policy)
    return policy

@router.get("/cases/{case_id}/risks", response_model=List[CaseRiskRecordOut])
async def get_case_risks(
    case_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(CaseRiskRecord).where(
        CaseRiskRecord.case_id == case_id
    ).order_by(CaseRiskRecord.detected_at.desc())
    res = await db.execute(stmt)
    return list(res.scalars().all())

@router.post("/audit-risks", status_code=status.HTTP_200_OK)
async def trigger_sla_audit(
    current_user: User = Depends(require_roles(UserRole.TEAM_LEAD, UserRole.MANAGER, UserRole.ADMIN)),
    db: AsyncSession = Depends(get_db)
):
    await sla_service.run_periodic_sla_audit(db)
    return {"status": "success", "message": "SLA risk assessment executed successfully"}

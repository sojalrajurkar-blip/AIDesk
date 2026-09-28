from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.api.deps import get_current_user, require_roles
from app.models.user import User, UserRole
from app.schemas.resolution import (
    CaseResolutionCreate, RequesterSignOffRequest, CaseResolutionOut
)
from app.services.case_service import case_service
from app.services.resolution_service import resolution_service

router = APIRouter()

@router.post("/{case_id}/resolution", response_model=CaseResolutionOut, status_code=status.HTTP_201_CREATED)
async def propose_case_resolution(
    case_id: int,
    res_in: CaseResolutionCreate,
    current_user: User = Depends(require_roles(UserRole.OPERATOR, UserRole.TEAM_LEAD, UserRole.MANAGER, UserRole.ADMIN)),
    db: AsyncSession = Depends(get_db)
):
    case = await case_service.get_case_by_id(db, case_id)
    if not case:
        raise HTTPException(status_code=404, detail="Case not found")

    return await resolution_service.propose_resolution(
        db=db,
        case=case,
        operator=current_user,
        res_in=res_in
    )

@router.post("/{case_id}/sign-off", response_model=CaseResolutionOut)
async def requester_sign_off(
    case_id: int,
    sign_off_in: RequesterSignOffRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    case = await case_service.get_case_by_id(db, case_id)
    if not case:
        raise HTTPException(status_code=404, detail="Case not found")

    return await resolution_service.process_requester_sign_off(
        db=db,
        case=case,
        requester=current_user,
        sign_off=sign_off_in
    )

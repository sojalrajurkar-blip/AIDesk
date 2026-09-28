from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.api.deps import get_current_user, require_roles
from app.models.user import User, UserRole
from app.schemas.dashboard import (
    RequesterDashboardOut, OperatorDashboardOut, TeamLeadDashboardOut,
    ManagerDashboardOut, AdminDashboardOut
)
from app.services.dashboard_service import dashboard_service

router = APIRouter()

@router.get("/requester", response_model=RequesterDashboardOut)
async def get_requester_dashboard(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    return await dashboard_service.get_requester_dashboard(db, current_user)

@router.get("/operator", response_model=OperatorDashboardOut)
async def get_operator_dashboard(
    current_user: User = Depends(require_roles(UserRole.OPERATOR, UserRole.TEAM_LEAD, UserRole.MANAGER, UserRole.ADMIN)),
    db: AsyncSession = Depends(get_db)
):
    return await dashboard_service.get_operator_dashboard(db, current_user)

@router.get("/team-lead", response_model=TeamLeadDashboardOut)
async def get_team_lead_dashboard(
    current_user: User = Depends(require_roles(UserRole.TEAM_LEAD, UserRole.MANAGER, UserRole.ADMIN)),
    db: AsyncSession = Depends(get_db)
):
    return await dashboard_service.get_team_lead_dashboard(db, current_user)

@router.get("/manager", response_model=ManagerDashboardOut)
async def get_manager_dashboard(
    current_user: User = Depends(require_roles(UserRole.MANAGER, UserRole.ADMIN)),
    db: AsyncSession = Depends(get_db)
):
    return await dashboard_service.get_manager_dashboard(db)

@router.get("/admin", response_model=AdminDashboardOut)
async def get_admin_dashboard(
    current_user: User = Depends(require_roles(UserRole.ADMIN)),
    db: AsyncSession = Depends(get_db)
):
    return await dashboard_service.get_admin_dashboard(db)

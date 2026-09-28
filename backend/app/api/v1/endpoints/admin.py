from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.api.deps import require_roles
from app.models.user import User, UserRole
from app.models.team import Team
from app.models.category import Category
from app.schemas.user import UserOut, UserUpdate
from app.schemas.case import TeamOut, CategoryOut
from app.services.audit_service import audit_service

router = APIRouter()

@router.get("/users", response_model=List[UserOut])
async def list_users(
    role: Optional[UserRole] = None,
    current_user: User = Depends(require_roles(UserRole.ADMIN, UserRole.MANAGER)),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(User).order_by(User.id.asc())
    if role:
        stmt = stmt.where(User.role == role)
    res = await db.execute(stmt)
    return list(res.scalars().all())

@router.patch("/users/{user_id}", response_model=UserOut)
async def update_user(
    user_id: int,
    user_in: UserUpdate,
    current_user: User = Depends(require_roles(UserRole.ADMIN)),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(User).where(User.id == user_id)
    res = await db.execute(stmt)
    user = res.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    old_role = user.role.value
    if user_in.full_name is not None:
        user.full_name = user_in.full_name
    if user_in.role is not None:
        user.role = user_in.role
    if user_in.department is not None:
        user.department = user_in.department
    if user_in.office_location is not None:
        user.office_location = user_in.office_location
    if user_in.is_active is not None:
        user.is_active = user_in.is_active
    if user_in.team_id is not None:
        user.team_id = user_in.team_id

    await audit_service.log_audit(
        db=db,
        actor_id=current_user.id,
        action="UPDATE_USER_GOVERNANCE",
        entity_type="USER",
        entity_id=user.id,
        previous_state={"role": old_role},
        new_state={"role": user.role.value}
    )

    await db.commit()
    await db.refresh(user)
    return user

@router.get("/teams", response_model=List[TeamOut])
async def list_teams(
    db: AsyncSession = Depends(get_db)
):
    stmt = select(Team).order_by(Team.id.asc())
    res = await db.execute(stmt)
    return list(res.scalars().all())

@router.get("/categories", response_model=List[CategoryOut])
async def list_categories(
    db: AsyncSession = Depends(get_db)
):
    stmt = select(Category).order_by(Category.id.asc())
    res = await db.execute(stmt)
    return list(res.scalars().all())

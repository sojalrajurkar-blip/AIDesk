from datetime import timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.security import verify_password, get_password_hash, create_access_token
from app.core.exceptions import AuthenticationError
from app.db.session import get_db
from app.models.user import User, UserRole
from app.schemas.auth import Token, LoginRequest, RegisterRequest
from app.schemas.user import UserOut
from app.api.deps import get_current_user
from app.services.audit_service import audit_service

router = APIRouter()

DEMO_ACCOUNTS = {
    "requester": ("requester@company.com", "RequesterPass123!"),
    "operator": ("operator@company.com", "OperatorPass123!"),
    "team_lead": ("teamlead@company.com", "TeamLeadPass123!"),
    "manager": ("manager@company.com", "ManagerPass123!"),
    "admin": ("admin@company.com", "AdminPass123!")
}

@router.post("/login", response_model=Token)
async def login(login_req: LoginRequest, db: AsyncSession = Depends(get_db)):
    stmt = select(User).where(User.email == login_req.email)
    res = await db.execute(stmt)
    user = res.scalar_one_or_none()

    if not user or not verify_password(login_req.password, user.hashed_password):
        raise AuthenticationError("Incorrect email or password")
    if not user.is_active:
        raise HTTPException(status_code=400, detail="Account is deactivated")

    access_token = create_access_token(
        subject=user.id,
        role=user.role.value
    )

    await audit_service.log_audit(
        db=db,
        actor_id=user.id,
        action="USER_LOGIN",
        entity_type="USER",
        entity_id=user.id
    )
    await db.commit()

    user_dict = {
        "id": str(user.id),
        "email": user.email,
        "full_name": user.full_name,
        "role": user.role.value,
        "is_active": user.is_active,
        "department": user.department,
        "office_location": user.office_location,
        "created_at": user.created_at.isoformat() if user.created_at else None
    }

    return Token(
        access_token=access_token,
        token_type="bearer",
        role=user.role.value,
        user_id=user.id,
        full_name=user.full_name,
        email=user.email,
        user=user_dict
    )

@router.post("/demo-login/{role_key}", response_model=Token)
async def demo_login_path(role_key: str, db: AsyncSession = Depends(get_db)):
    return await _process_demo_login(role_key, db)

@router.post("/demo-login", response_model=Token)
async def demo_login_query(role: str = "REQUESTER", db: AsyncSession = Depends(get_db)):
    return await _process_demo_login(role, db)

async def _process_demo_login(role_key: str, db: AsyncSession) -> Token:
    clean_role = role_key.lower().replace("-", "_")
    if clean_role not in DEMO_ACCOUNTS:
        raise HTTPException(status_code=400, detail=f"Unknown demo role: {role_key}. Available: {list(DEMO_ACCOUNTS.keys())}")

    email, _ = DEMO_ACCOUNTS[clean_role]
    stmt = select(User).where(User.email == email)
    res = await db.execute(stmt)
    user = res.scalar_one_or_none()

    if not user:
        raise HTTPException(status_code=404, detail="Demo user account not found in database. Run seed script.")

    access_token = create_access_token(
        subject=user.id,
        role=user.role.value
    )

    user_dict = {
        "id": str(user.id),
        "email": user.email,
        "full_name": user.full_name,
        "role": user.role.value,
        "is_active": user.is_active,
        "department": user.department,
        "office_location": user.office_location,
        "created_at": user.created_at.isoformat() if user.created_at else None
    }

    return Token(
        access_token=access_token,
        token_type="bearer",
        role=user.role.value,
        user_id=user.id,
        full_name=user.full_name,
        email=user.email,
        user=user_dict
    )

@router.post("/register", response_model=UserOut)
async def register(reg_in: RegisterRequest, db: AsyncSession = Depends(get_db)):
    stmt = select(User).where(User.email == reg_in.email)
    res = await db.execute(stmt)
    existing = res.scalar_one_or_none()
    if existing:
        raise HTTPException(status_code=400, detail="A user with this email already exists")

    new_user = User(
        email=reg_in.email,
        hashed_password=get_password_hash(reg_in.password),
        full_name=reg_in.full_name,
        role=reg_in.role or UserRole.REQUESTER,
        department=reg_in.department,
        office_location=reg_in.office_location,
        is_active=True
    )
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)
    return new_user

@router.get("/me", response_model=UserOut)
async def get_me(current_user: User = Depends(get_current_user)):
    return current_user

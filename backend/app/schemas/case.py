from datetime import datetime
from typing import Optional, List, Any
from pydantic import BaseModel, ConfigDict
from app.models.case import CaseStatus, CasePriority, CaseSeverity
from app.schemas.user import UserOut

class CategoryOut(BaseModel):
    id: int
    name: str
    description: Optional[str] = None
    icon: Optional[str] = None
    sla_response_minutes: int
    sla_resolution_minutes: int

    model_config = ConfigDict(from_attributes=True)

class TeamOut(BaseModel):
    id: int
    name: str
    description: Optional[str] = None
    leader_id: Optional[int] = None

    model_config = ConfigDict(from_attributes=True)

class CaseBase(BaseModel):
    title: str
    description: str
    location: Optional[str] = None
    category_id: Optional[int] = None
    priority: Optional[CasePriority] = CasePriority.MEDIUM
    severity: Optional[CaseSeverity] = CaseSeverity.MODERATE

class CaseCreate(CaseBase):
    pass

class CaseUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    location: Optional[str] = None
    status: Optional[CaseStatus] = None
    priority: Optional[CasePriority] = None
    severity: Optional[CaseSeverity] = None
    category_id: Optional[int] = None
    assigned_team_id: Optional[int] = None
    assigned_operator_id: Optional[int] = None
    root_cause: Optional[str] = None
    ai_summary: Optional[str] = None
    sla_risk_level: Optional[str] = None

class StatusTransitionRequest(BaseModel):
    target_status: CaseStatus
    comment: Optional[str] = None

class AssignCaseRequest(BaseModel):
    assigned_team_id: Optional[int] = None
    assigned_operator_id: Optional[int] = None
    comment: Optional[str] = None

class CaseOut(BaseModel):
    id: int
    case_number: str
    title: str
    description: str
    location: Optional[str] = None
    status: CaseStatus
    priority: CasePriority
    severity: CaseSeverity
    category_id: Optional[int] = None
    requester_id: int
    assigned_team_id: Optional[int] = None
    assigned_operator_id: Optional[int] = None
    parent_case_id: Optional[int] = None
    is_escalated: bool
    sla_due_at: Optional[datetime] = None
    sla_risk_level: str
    ai_summary: Optional[str] = None
    root_cause: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    resolved_at: Optional[datetime] = None
    closed_at: Optional[datetime] = None

    requester: Optional[UserOut] = None
    assigned_operator: Optional[UserOut] = None
    assigned_team: Optional[TeamOut] = None
    category: Optional[CategoryOut] = None

    model_config = ConfigDict(from_attributes=True)

class CaseDetailOut(CaseOut):
    messages_count: int = 0
    tasks_count: int = 0
    attachments_count: int = 0

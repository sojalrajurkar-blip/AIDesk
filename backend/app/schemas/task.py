from datetime import datetime
from typing import Optional, Dict, Any
from pydantic import BaseModel, ConfigDict
from app.models.task import TaskStatus
from app.schemas.user import UserOut

class CaseTaskCreate(BaseModel):
    title: str
    description: Optional[str] = None
    assignee_id: Optional[int] = None
    due_date: Optional[datetime] = None

class CaseTaskUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    status: Optional[TaskStatus] = None
    assignee_id: Optional[int] = None
    due_date: Optional[datetime] = None

class CaseTaskOut(BaseModel):
    id: int
    case_id: int
    assignee_id: Optional[int] = None
    title: str
    description: Optional[str] = None
    status: TaskStatus
    due_date: Optional[datetime] = None
    created_at: datetime
    completed_at: Optional[datetime] = None
    assignee: Optional[UserOut] = None

    model_config = ConfigDict(from_attributes=True)

class InvestigationRecordCreate(BaseModel):
    observations: str
    actions_taken: Optional[str] = None
    diagnostic_steps: Optional[str] = None
    findings: Optional[str] = None
    technical_evidence: Optional[Dict[str, Any]] = None
    follow_up_requirements: Optional[str] = None

class InvestigationRecordOut(BaseModel):
    id: int
    case_id: int
    investigator_id: int
    observations: str
    actions_taken: Optional[str] = None
    diagnostic_steps: Optional[str] = None
    findings: Optional[str] = None
    technical_evidence: Optional[Dict[str, Any]] = None
    follow_up_requirements: Optional[str] = None
    created_at: datetime
    investigator: Optional[UserOut] = None

    model_config = ConfigDict(from_attributes=True)

from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, ConfigDict
from app.schemas.user import UserOut

class CaseResolutionCreate(BaseModel):
    resolution_summary: str
    actions_taken: str
    root_cause_findings: Optional[str] = None
    evidence_attachments: Optional[List[str]] = None
    remaining_issues: Optional[str] = None

class RequesterSignOffRequest(BaseModel):
    confirmed: bool
    feedback: Optional[str] = None

class CaseResolutionOut(BaseModel):
    id: int
    case_id: int
    resolved_by_id: int
    resolution_summary: str
    actions_taken: str
    root_cause_findings: Optional[str] = None
    evidence_attachments: Optional[List[str]] = None
    remaining_issues: Optional[str] = None
    requester_confirmed: Optional[bool] = None
    requester_feedback: Optional[str] = None
    confirmed_at: Optional[datetime] = None
    created_at: datetime
    resolved_by: Optional[UserOut] = None

    model_config = ConfigDict(from_attributes=True)

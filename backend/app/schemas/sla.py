from datetime import datetime
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, ConfigDict
from app.schemas.user import UserOut

class SLAPolicyOut(BaseModel):
    id: int
    name: str
    priority: str
    severity: str
    response_time_minutes: int
    resolution_time_minutes: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

class SLAPolicyCreate(BaseModel):
    name: str
    priority: str
    severity: str
    response_time_minutes: int
    resolution_time_minutes: int

class CaseRiskRecordOut(BaseModel):
    id: int
    case_id: int
    risk_level: str
    reason: str
    risk_factors: Optional[List[str]] = None
    detected_at: datetime

    model_config = ConfigDict(from_attributes=True)

class CaseEscalationCreate(BaseModel):
    reason: str
    new_priority: Optional[str] = None

class CaseEscalationOut(BaseModel):
    id: int
    case_id: int
    escalated_by_id: int
    reason: str
    previous_priority: Optional[str] = None
    new_priority: Optional[str] = None
    created_at: datetime
    resolved_at: Optional[datetime] = None
    resolution_notes: Optional[str] = None
    escalated_by: Optional[UserOut] = None

    model_config = ConfigDict(from_attributes=True)

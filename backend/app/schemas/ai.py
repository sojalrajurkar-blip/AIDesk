from datetime import datetime
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, ConfigDict
from app.schemas.case import CategoryOut, TeamOut

class AITriageRequest(BaseModel):
    title: str
    description: str
    location: Optional[str] = None

class AITriageResponse(BaseModel):
    suggested_category: str
    suggested_category_id: Optional[int] = None
    suggested_priority: str
    suggested_severity: str
    suggested_team: str
    suggested_team_id: Optional[int] = None
    confidence_score: float
    missing_information_detected: bool
    missing_information_questions: List[str] = []
    suggested_next_action: str
    potential_duplicate_detected: bool
    potential_duplicate_case_ids: List[int] = []
    risk_factors: List[str] = []
    recommended_self_fix: Optional[str] = None

class AICaseAnalysisOut(BaseModel):
    id: int
    case_id: int
    suggested_category_id: Optional[int] = None
    suggested_priority: Optional[str] = None
    suggested_severity: Optional[str] = None
    suggested_team_id: Optional[int] = None
    suggested_operator_id: Optional[int] = None
    missing_information_detected: bool
    missing_information_questions: Optional[List[str]] = None
    suggested_next_action: Optional[str] = None
    potential_duplicate_detected: bool
    potential_duplicate_case_ids: Optional[List[int]] = None
    risk_factors: Optional[List[str]] = None
    confidence_score: float
    applied_by_operator: bool
    created_at: datetime
    suggested_category: Optional[CategoryOut] = None
    suggested_team: Optional[TeamOut] = None

    model_config = ConfigDict(from_attributes=True)

class AISummaryResponse(BaseModel):
    case_id: int
    summary: str
    key_findings: List[str] = []
    current_blocker: Optional[str] = None
    recommended_next_step: Optional[str] = None

class AIDraftResponse(BaseModel):
    draft_type: str
    subject: Optional[str] = None
    body: str
    suggested_action: Optional[str] = None

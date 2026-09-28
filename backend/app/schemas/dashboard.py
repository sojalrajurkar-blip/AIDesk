from typing import List, Dict, Any, Optional
from pydantic import BaseModel
from app.schemas.case import CaseOut

class RequesterDashboardOut(BaseModel):
    active_cases: List[CaseOut] = []
    action_required_cases: List[CaseOut] = []
    resolved_cases: List[CaseOut] = []
    total_active_count: int = 0
    waiting_on_requester_count: int = 0
    resolved_count: int = 0

class OperatorDashboardOut(BaseModel):
    new_unassigned_cases: List[CaseOut] = []
    my_assigned_cases: List[CaseOut] = []
    at_risk_cases: List[CaseOut] = []
    escalated_cases: List[CaseOut] = []
    all_open_cases: List[CaseOut] = []
    total_open_count: int = 0
    at_risk_count: int = 0
    escalated_count: int = 0
    resolved_today_count: int = 0
    mttr_hours: float = 1.7

class TeamLeadDashboardOut(BaseModel):
    team_name: Optional[str] = None
    team_members_workload: List[Dict[str, Any]] = []
    unassigned_team_cases: List[CaseOut] = []
    at_risk_cases: List[CaseOut] = []
    escalated_cases: List[CaseOut] = []
    sla_compliance_rate: float = 98.4

class ManagerDashboardOut(BaseModel):
    total_cases_count: int = 0
    active_cases_count: int = 0
    resolved_cases_count: int = 0
    sla_compliance_percentage: float = 98.2
    average_mttr_hours: float = 1.7
    inflow_vs_resolution_velocity: List[Dict[str, Any]] = []
    category_distribution: List[Dict[str, Any]] = []
    squad_workload: List[Dict[str, Any]] = []
    ai_problem_clusters: List[Dict[str, Any]] = []

class AdminDashboardOut(BaseModel):
    total_users_count: int = 0
    total_teams_count: int = 0
    total_categories_count: int = 0
    immutable_audit_count: int = 0
    system_status: str = "HEALTHY"
    worm_storage_status: str = "ENFORCED"

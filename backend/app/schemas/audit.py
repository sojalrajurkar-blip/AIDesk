from datetime import datetime
from typing import Optional, Dict, Any
from pydantic import BaseModel, ConfigDict
from app.schemas.user import UserOut

class TimelineEventOut(BaseModel):
    id: int
    case_id: int
    actor_id: Optional[int] = None
    event_type: str
    description: str
    old_state: Optional[Dict[str, Any]] = None
    new_state: Optional[Dict[str, Any]] = None
    created_at: datetime
    actor: Optional[UserOut] = None

    model_config = ConfigDict(from_attributes=True)

class AuditLogOut(BaseModel):
    id: int
    actor_id: Optional[int] = None
    action: str
    entity_type: str
    entity_id: Optional[int] = None
    previous_state: Optional[Dict[str, Any]] = None
    new_state: Optional[Dict[str, Any]] = None
    ip_address: Optional[str] = None
    created_at: datetime
    actor: Optional[UserOut] = None

    model_config = ConfigDict(from_attributes=True)

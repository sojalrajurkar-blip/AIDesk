from datetime import datetime, timezone
from typing import Optional, List, Dict, Any
from sqlalchemy import String, Text, Float, Boolean, DateTime, ForeignKey, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base

class AICaseAnalysis(Base):
    __tablename__ = "ai_case_analyses"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    case_id: Mapped[int] = mapped_column(ForeignKey("cases.id", ondelete="CASCADE"), nullable=False, index=True)
    
    suggested_category_id: Mapped[Optional[int]] = mapped_column(ForeignKey("categories.id", ondelete="SET NULL"), nullable=True)
    suggested_priority: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    suggested_severity: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    suggested_team_id: Mapped[Optional[int]] = mapped_column(ForeignKey("teams.id", ondelete="SET NULL"), nullable=True)
    suggested_operator_id: Mapped[Optional[int]] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    
    missing_information_detected: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    missing_information_questions: Mapped[Optional[List[str]]] = mapped_column(JSON, nullable=True)
    suggested_next_action: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    
    potential_duplicate_detected: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    potential_duplicate_case_ids: Mapped[Optional[List[int]]] = mapped_column(JSON, nullable=True)
    
    risk_factors: Mapped[Optional[List[str]]] = mapped_column(JSON, nullable=True)
    confidence_score: Mapped[float] = mapped_column(Float, default=0.90, nullable=False)
    raw_ai_response: Mapped[Optional[Dict[str, Any]]] = mapped_column(JSON, nullable=True)
    applied_by_operator: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    case = relationship("Case", back_populates="ai_analyses")
    suggested_category = relationship("Category")
    suggested_team = relationship("Team")

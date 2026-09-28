from datetime import datetime, timezone
from typing import Optional, List
from sqlalchemy import String, Text, Boolean, DateTime, ForeignKey, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base

class CaseResolution(Base):
    __tablename__ = "case_resolutions"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    case_id: Mapped[int] = mapped_column(ForeignKey("cases.id", ondelete="CASCADE"), nullable=False, index=True)
    resolved_by_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    
    resolution_summary: Mapped[str] = mapped_column(Text, nullable=False)
    actions_taken: Mapped[str] = mapped_column(Text, nullable=False)
    root_cause_findings: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    evidence_attachments: Mapped[Optional[List[str]]] = mapped_column(JSON, nullable=True)
    remaining_issues: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    
    # Requester confirmation flow
    requester_confirmed: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    requester_feedback: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    confirmed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    case = relationship("Case", back_populates="resolutions")
    resolved_by = relationship("User", lazy="selectin")

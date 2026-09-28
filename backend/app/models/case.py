import enum
from datetime import datetime, timezone
from typing import Optional, List
from sqlalchemy import String, Text, Integer, Boolean, DateTime, ForeignKey, Enum as SQLEnum, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base

class CaseStatus(str, enum.Enum):
    REPORTED = "REPORTED"
    UNDERSTOOD = "UNDERSTOOD"
    ASSIGNED = "ASSIGNED"
    INVESTIGATING = "INVESTIGATING"
    ACTION_TAKEN = "ACTION_TAKEN"
    RESOLUTION_PROPOSED = "RESOLUTION_PROPOSED"
    CONFIRMED = "CONFIRMED"
    CLOSED = "CLOSED"
    WAITING_FOR_INFORMATION = "WAITING_FOR_INFORMATION"
    ESCALATED = "ESCALATED"
    DUPLICATE = "DUPLICATE"
    REOPENED = "REOPENED"
    CANCELLED = "CANCELLED"

class CasePriority(str, enum.Enum):
    LOW = "LOW"
    MEDIUM = "MEDIUM"
    HIGH = "HIGH"
    CRITICAL = "CRITICAL"

class CaseSeverity(str, enum.Enum):
    MINOR = "MINOR"
    MODERATE = "MODERATE"
    MAJOR = "MAJOR"
    CRITICAL = "CRITICAL"

class CaseSequence(Base):
    __tablename__ = "case_sequences"

    id: Mapped[int] = mapped_column(primary_key=True)
    last_val: Mapped[int] = mapped_column(Integer, default=10480, nullable=False)

class Case(Base):
    __tablename__ = "cases"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    case_number: Mapped[str] = mapped_column(String(30), unique=True, index=True, nullable=False)
    title: Mapped[str] = mapped_column(String(255), index=True, nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    location: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    
    status: Mapped[CaseStatus] = mapped_column(SQLEnum(CaseStatus), default=CaseStatus.REPORTED, nullable=False, index=True)
    priority: Mapped[CasePriority] = mapped_column(SQLEnum(CasePriority), default=CasePriority.MEDIUM, nullable=False, index=True)
    severity: Mapped[CaseSeverity] = mapped_column(SQLEnum(CaseSeverity), default=CaseSeverity.MODERATE, nullable=False, index=True)

    category_id: Mapped[Optional[int]] = mapped_column(ForeignKey("categories.id", ondelete="SET NULL"), nullable=True)
    requester_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    assigned_team_id: Mapped[Optional[int]] = mapped_column(ForeignKey("teams.id", ondelete="SET NULL"), nullable=True, index=True)
    assigned_operator_id: Mapped[Optional[int]] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    
    parent_case_id: Mapped[Optional[int]] = mapped_column(ForeignKey("cases.id", use_alter=True, name="fk_cases_parent_case_id", ondelete="SET NULL"), nullable=True)
    is_escalated: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    sla_due_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    sla_risk_level: Mapped[str] = mapped_column(String(50), default="NORMAL", nullable=False)
    ai_summary: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    root_cause: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False, index=True)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)
    resolved_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    closed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)

    # Relationships with lazy="selectin" for async SQLAlchemy
    requester = relationship("User", back_populates="created_cases", foreign_keys=[requester_id], lazy="selectin")
    assigned_operator = relationship("User", back_populates="assigned_cases", foreign_keys=[assigned_operator_id], lazy="selectin")
    assigned_team = relationship("Team", back_populates="assigned_cases", foreign_keys=[assigned_team_id], lazy="selectin")
    category = relationship("Category", back_populates="cases", lazy="selectin")
    
    messages = relationship("CaseMessage", back_populates="case", cascade="all, delete-orphan", order_by="CaseMessage.created_at", lazy="selectin")
    internal_notes = relationship("InternalNote", back_populates="case", cascade="all, delete-orphan", order_by="InternalNote.created_at", lazy="selectin")
    attachments = relationship("CaseAttachment", back_populates="case", cascade="all, delete-orphan", lazy="selectin")
    tasks = relationship("CaseTask", back_populates="case", cascade="all, delete-orphan", order_by="CaseTask.created_at", lazy="selectin")
    investigation_records = relationship("InvestigationRecord", back_populates="case", cascade="all, delete-orphan", lazy="selectin")
    ai_analyses = relationship("AICaseAnalysis", back_populates="case", cascade="all, delete-orphan", order_by="AICaseAnalysis.created_at.desc()", lazy="selectin")
    resolutions = relationship("CaseResolution", back_populates="case", cascade="all, delete-orphan", lazy="selectin")
    timeline_events = relationship("TimelineEvent", back_populates="case", cascade="all, delete-orphan", order_by="TimelineEvent.created_at", lazy="selectin")
    risk_records = relationship("CaseRiskRecord", back_populates="case", cascade="all, delete-orphan", lazy="selectin")
    escalations = relationship("CaseEscalation", back_populates="case", cascade="all, delete-orphan", lazy="selectin")

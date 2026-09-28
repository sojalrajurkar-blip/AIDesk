from datetime import datetime, timezone
from typing import Optional, List
from sqlalchemy import String, DateTime, ForeignKey, Integer
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base

class Team(Base):
    __tablename__ = "teams"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(100), unique=True, index=True, nullable=False)
    description: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    leader_id: Mapped[Optional[int]] = mapped_column(ForeignKey("users.id", use_alter=True, name="fk_teams_leader_id", ondelete="SET NULL"), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    members = relationship("User", back_populates="team", foreign_keys="User.team_id")
    categories = relationship("Category", back_populates="default_team")
    assigned_cases = relationship("Case", back_populates="assigned_team")

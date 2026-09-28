from datetime import datetime, timedelta, timezone
from typing import Optional, List
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.case import Case, CaseStatus, CasePriority, CaseSeverity
from app.models.sla import SLAPolicy, CaseRiskRecord, CaseEscalation
from app.services.audit_service import audit_service
from app.services.notification_service import notification_service

class SLAService:
    @staticmethod
    async def calculate_due_date(
        db: AsyncSession,
        priority: CasePriority,
        severity: CaseSeverity
    ) -> datetime:
        stmt = select(SLAPolicy).where(
            SLAPolicy.priority == priority.value
        )
        res = await db.execute(stmt)
        policy = res.scalar_one_or_none()

        minutes = 240  # Default 4 hours
        if policy:
            minutes = policy.resolution_time_minutes
        elif priority == CasePriority.CRITICAL:
            minutes = 60
        elif priority == CasePriority.HIGH:
            minutes = 180
        elif priority == CasePriority.MEDIUM:
            minutes = 480
        else:
            minutes = 1440

        return datetime.now(timezone.utc) + timedelta(minutes=minutes)

    @staticmethod
    async def evaluate_case_risk(
        db: AsyncSession,
        case: Case
    ) -> str:
        now = datetime.now(timezone.utc)
        risk_level = "NORMAL"
        risk_reasons = []

        if case.status in [CaseStatus.CLOSED, CaseStatus.CONFIRMED, CaseStatus.CANCELLED]:
            case.sla_risk_level = "NORMAL"
            return "NORMAL"

        # Check due date
        if case.sla_due_at:
            time_left = (case.sla_due_at - now).total_seconds()
            if time_left < 0:
                risk_level = "BREACHED"
                risk_reasons.append("SLA deadline has been exceeded")
            elif time_left < 3600:  # Less than 1 hour remaining
                risk_level = "CRITICAL"
                risk_reasons.append("Less than 60 minutes remaining before SLA breach")
            elif time_left < 7200:  # Less than 2 hours remaining
                risk_level = "WARNING"
                risk_reasons.append("SLA deadline approaching within 2 hours")

        # Inactivity check
        inactivity_seconds = (now - case.updated_at).total_seconds()
        if inactivity_seconds > 7200 and case.status == CaseStatus.REPORTED:
            risk_level = "WARNING" if risk_level == "NORMAL" else risk_level
            risk_reasons.append("Unassigned/unacknowledged for over 2 hours")

        if case.priority == CasePriority.CRITICAL and risk_level == "NORMAL":
            risk_level = "WARNING"
            risk_reasons.append("Critical severity incident requires constant monitoring")

        case.sla_risk_level = risk_level

        if risk_level in ["WARNING", "CRITICAL", "BREACHED"] and risk_reasons:
            risk_rec = CaseRiskRecord(
                case_id=case.id,
                risk_level=risk_level,
                reason="; ".join(risk_reasons),
                risk_factors=risk_reasons,
                detected_at=now
            )
            db.add(risk_rec)

        return risk_level

    @staticmethod
    async def run_periodic_sla_audit(db: AsyncSession):
        stmt = select(Case).where(
            Case.status.not_in([CaseStatus.CLOSED, CaseStatus.CONFIRMED, CaseStatus.CANCELLED])
        )
        res = await db.execute(stmt)
        open_cases = res.scalars().all()
        for c in open_cases:
            await SLAService.evaluate_case_risk(db, c)
        await db.commit()

sla_service = SLAService()

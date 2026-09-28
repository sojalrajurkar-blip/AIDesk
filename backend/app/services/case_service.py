from datetime import datetime, timezone
from typing import Optional, List, Dict, Any
from sqlalchemy import select, update, or_, and_, func
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import EntityNotFoundError, InvalidStateTransitionError, BusinessRuleViolationError
from app.models.case import Case, CaseSequence, CaseStatus, CasePriority, CaseSeverity
from app.models.user import User, UserRole
from app.models.ai_analysis import AICaseAnalysis
from app.models.sla import CaseEscalation
from app.schemas.case import CaseCreate, CaseUpdate
from app.services.audit_service import audit_service
from app.services.notification_service import notification_service
from app.services.sla_service import sla_service
from app.services.ai_service import ai_service

VALID_TRANSITIONS: Dict[CaseStatus, List[CaseStatus]] = {
    CaseStatus.REPORTED: [CaseStatus.UNDERSTOOD, CaseStatus.ASSIGNED, CaseStatus.DUPLICATE, CaseStatus.CANCELLED],
    CaseStatus.UNDERSTOOD: [CaseStatus.ASSIGNED, CaseStatus.INVESTIGATING, CaseStatus.DUPLICATE, CaseStatus.CANCELLED],
    CaseStatus.ASSIGNED: [CaseStatus.INVESTIGATING, CaseStatus.WAITING_FOR_INFORMATION, CaseStatus.ESCALATED, CaseStatus.CANCELLED],
    CaseStatus.INVESTIGATING: [CaseStatus.ACTION_TAKEN, CaseStatus.WAITING_FOR_INFORMATION, CaseStatus.ESCALATED, CaseStatus.RESOLUTION_PROPOSED],
    CaseStatus.WAITING_FOR_INFORMATION: [CaseStatus.INVESTIGATING, CaseStatus.ACTION_TAKEN, CaseStatus.CANCELLED],
    CaseStatus.ACTION_TAKEN: [CaseStatus.RESOLUTION_PROPOSED, CaseStatus.INVESTIGATING],
    CaseStatus.RESOLUTION_PROPOSED: [CaseStatus.CONFIRMED, CaseStatus.REOPENED],
    CaseStatus.CONFIRMED: [CaseStatus.CLOSED],
    CaseStatus.REOPENED: [CaseStatus.INVESTIGATING, CaseStatus.ASSIGNED, CaseStatus.ESCALATED],
    CaseStatus.ESCALATED: [CaseStatus.INVESTIGATING, CaseStatus.ACTION_TAKEN, CaseStatus.RESOLUTION_PROPOSED],
    CaseStatus.DUPLICATE: [CaseStatus.CLOSED],
    CaseStatus.CLOSED: [CaseStatus.REOPENED],
    CaseStatus.CANCELLED: []
}

class CaseService:
    @staticmethod
    async def generate_next_case_number(db: AsyncSession) -> str:
        stmt = select(CaseSequence).with_for_update()
        res = await db.execute(stmt)
        seq = res.scalar_one_or_none()
        
        # Check highest case number in DB
        case_stmt = select(Case.case_number)
        all_cases = (await db.execute(case_stmt)).scalars().all()
        max_num = 10482
        for cn in all_cases:
            if cn.startswith("IT-"):
                try:
                    num = int(cn.split("-")[1])
                    if num > max_num:
                        max_num = num
                except ValueError:
                    pass

        if not seq:
            seq = CaseSequence(id=1, last_val=max_num + 1)
            db.add(seq)
            await db.flush()
        else:
            seq.last_val = max(seq.last_val, max_num) + 1
            await db.flush()
        return f"IT-{seq.last_val}"

    @staticmethod
    async def create_case(
        db: AsyncSession,
        case_in: CaseCreate,
        requester: User
    ) -> Case:
        case_number = await CaseService.generate_next_case_number(db)
        due_at = await sla_service.calculate_due_date(
            db,
            case_in.priority or CasePriority.MEDIUM,
            case_in.severity or CaseSeverity.MODERATE
        )

        new_case = Case(
            case_number=case_number,
            title=case_in.title,
            description=case_in.description,
            location=case_in.location or requester.office_location,
            category_id=case_in.category_id,
            priority=case_in.priority or CasePriority.MEDIUM,
            severity=case_in.severity or CaseSeverity.MODERATE,
            status=CaseStatus.REPORTED,
            requester_id=requester.id,
            sla_due_at=due_at,
            sla_risk_level="NORMAL",
            created_at=datetime.now(timezone.utc)
        )
        db.add(new_case)
        await db.flush()

        # Run AI Triage & attach analysis
        triage = await ai_service.analyze_and_triage(
            db=db,
            title=new_case.title,
            description=new_case.description,
            location=new_case.location
        )
        
        # If category wasn't specified, apply AI category suggestion
        if not new_case.category_id and triage.suggested_category_id:
            new_case.category_id = triage.suggested_category_id
            new_case.assigned_team_id = triage.suggested_team_id

        analysis_record = AICaseAnalysis(
            case_id=new_case.id,
            suggested_category_id=triage.suggested_category_id,
            suggested_priority=triage.suggested_priority,
            suggested_severity=triage.suggested_severity,
            suggested_team_id=triage.suggested_team_id,
            missing_information_detected=triage.missing_information_detected,
            missing_information_questions=triage.missing_information_questions,
            suggested_next_action=triage.suggested_next_action,
            potential_duplicate_detected=triage.potential_duplicate_detected,
            potential_duplicate_case_ids=triage.potential_duplicate_case_ids,
            risk_factors=triage.risk_factors,
            confidence_score=triage.confidence_score,
            applied_by_operator=False,
            created_at=datetime.now(timezone.utc)
        )
        db.add(analysis_record)

        # Log timeline & audit
        await audit_service.log_timeline(
            db=db,
            case_id=new_case.id,
            actor_id=requester.id,
            event_type="CASE_CREATED",
            description=f"Case {case_number} created by {requester.full_name}."
        )
        await audit_service.log_audit(
            db=db,
            actor_id=requester.id,
            action="CREATE_CASE",
            entity_type="CASE",
            entity_id=new_case.id,
            new_state={"case_number": case_number, "title": new_case.title, "priority": new_case.priority.value}
        )

        await db.commit()
        await db.refresh(new_case)
        return new_case

    @staticmethod
    async def get_case_by_id(db: AsyncSession, case_id: int) -> Optional[Case]:
        stmt = select(Case).where(Case.id == case_id).options(
            selectinload(Case.requester),
            selectinload(Case.assigned_operator),
            selectinload(Case.assigned_team),
            selectinload(Case.category),
            selectinload(Case.messages),
            selectinload(Case.tasks),
            selectinload(Case.attachments)
        )
        res = await db.execute(stmt)
        return res.scalar_one_or_none()

    @staticmethod
    async def get_case_by_number(db: AsyncSession, case_number: str) -> Optional[Case]:
        stmt = select(Case).where(Case.case_number == case_number).options(
            selectinload(Case.requester),
            selectinload(Case.assigned_operator),
            selectinload(Case.assigned_team),
            selectinload(Case.category),
            selectinload(Case.messages),
            selectinload(Case.tasks),
            selectinload(Case.attachments)
        )
        res = await db.execute(stmt)
        return res.scalar_one_or_none()

    @staticmethod
    async def list_cases(
        db: AsyncSession,
        current_user: User,
        status: Optional[CaseStatus] = None,
        priority: Optional[CasePriority] = None,
        category_id: Optional[int] = None,
        team_id: Optional[int] = None,
        operator_id: Optional[int] = None,
        search: Optional[str] = None,
        limit: int = 50,
        offset: int = 0
    ) -> List[Case]:
        stmt = select(Case).options(
            selectinload(Case.requester),
            selectinload(Case.assigned_operator),
            selectinload(Case.assigned_team),
            selectinload(Case.category)
        )

        # RBAC scoping: Requesters can only see their own cases
        if current_user.role == UserRole.REQUESTER:
            stmt = stmt.where(Case.requester_id == current_user.id)
        elif current_user.role == UserRole.TEAM_LEAD and current_user.team_id:
            if team_id is None:
                stmt = stmt.where(or_(Case.assigned_team_id == current_user.team_id, Case.assigned_team_id.is_(None)))

        if status:
            stmt = stmt.where(Case.status == status)
        if priority:
            stmt = stmt.where(Case.priority == priority)
        if category_id:
            stmt = stmt.where(Case.category_id == category_id)
        if team_id:
            stmt = stmt.where(Case.assigned_team_id == team_id)
        if operator_id:
            stmt = stmt.where(Case.assigned_operator_id == operator_id)
        if search:
            stmt = stmt.where(
                or_(
                    Case.case_number.ilike(f"%{search}%"),
                    Case.title.ilike(f"%{search}%"),
                    Case.description.ilike(f"%{search}%"),
                    Case.location.ilike(f"%{search}%")
                )
            )

        stmt = stmt.order_by(Case.created_at.desc()).offset(offset).limit(limit)
        res = await db.execute(stmt)
        return list(res.scalars().all())

    @staticmethod
    async def transition_status(
        db: AsyncSession,
        case: Case,
        target_status: CaseStatus,
        actor: User,
        comment: Optional[str] = None
    ) -> Case:
        allowed = VALID_TRANSITIONS.get(case.status, [])
        if target_status not in allowed:
            raise InvalidStateTransitionError(
                current_status=case.status.value,
                target_status=target_status.value,
                detail=f"Allowed transitions from '{case.status.value}' are: {[s.value for s in allowed]}"
            )

        old_status = case.status
        case.status = target_status
        case.updated_at = datetime.now(timezone.utc)

        if target_status == CaseStatus.CLOSED:
            case.closed_at = datetime.now(timezone.utc)

        desc = f"Status changed from {old_status.value} to {target_status.value} by {actor.full_name}."
        if comment:
            desc += f" Note: {comment}"

        await audit_service.log_timeline(
            db=db,
            case_id=case.id,
            actor_id=actor.id,
            event_type="STATUS_CHANGED",
            description=desc,
            old_state={"status": old_status.value},
            new_state={"status": target_status.value}
        )
        await audit_service.log_audit(
            db=db,
            actor_id=actor.id,
            action="TRANSITION_STATUS",
            entity_type="CASE",
            entity_id=case.id,
            previous_state={"status": old_status.value},
            new_state={"status": target_status.value}
        )

        if actor.id != case.requester_id:
            await notification_service.create_notification(
                db=db,
                user_id=case.requester_id,
                case_id=case.id,
                title=f"Case {case.case_number} Status Update",
                message=f"Your case status has updated to {target_status.value}.",
                notification_type="STATUS_UPDATE"
            )

        await db.commit()
        await db.refresh(case)
        return case

    @staticmethod
    async def assign_case(
        db: AsyncSession,
        case: Case,
        actor: User,
        assigned_team_id: Optional[int] = None,
        assigned_operator_id: Optional[int] = None,
        comment: Optional[str] = None
    ) -> Case:
        old_team = case.assigned_team_id
        old_op = case.assigned_operator_id

        if assigned_team_id is not None:
            case.assigned_team_id = assigned_team_id
        if assigned_operator_id is not None:
            case.assigned_operator_id = assigned_operator_id
            if case.status == CaseStatus.REPORTED:
                case.status = CaseStatus.ASSIGNED

        case.updated_at = datetime.now(timezone.utc)

        desc = f"Assignment updated by {actor.full_name}."
        if comment:
            desc += f" Note: {comment}"

        await audit_service.log_timeline(
            db=db,
            case_id=case.id,
            actor_id=actor.id,
            event_type="CASE_ASSIGNED",
            description=desc,
            old_state={"team_id": old_team, "operator_id": old_op},
            new_state={"team_id": case.assigned_team_id, "operator_id": case.assigned_operator_id}
        )
        await audit_service.log_audit(
            db=db,
            actor_id=actor.id,
            action="ASSIGN_CASE",
            entity_type="CASE",
            entity_id=case.id,
            previous_state={"team_id": old_team, "operator_id": old_op},
            new_state={"team_id": case.assigned_team_id, "operator_id": case.assigned_operator_id}
        )

        if case.assigned_operator_id and case.assigned_operator_id != actor.id:
            await notification_service.create_notification(
                db=db,
                user_id=case.assigned_operator_id,
                case_id=case.id,
                title="New Case Assignment",
                message=f"You have been assigned to case {case.case_number}: {case.title}.",
                notification_type="ASSIGNMENT"
            )

        await db.commit()
        await db.refresh(case)
        return case

    @staticmethod
    async def escalate_case(
        db: AsyncSession,
        case: Case,
        actor: User,
        reason: str,
        new_priority: Optional[str] = None
    ) -> CaseEscalation:
        old_priority = case.priority.value
        if new_priority:
            try:
                case.priority = CasePriority(new_priority)
            except ValueError:
                pass

        case.is_escalated = True
        case.status = CaseStatus.ESCALATED
        case.updated_at = datetime.now(timezone.utc)

        escalation = CaseEscalation(
            case_id=case.id,
            escalated_by_id=actor.id,
            reason=reason,
            previous_priority=old_priority,
            new_priority=case.priority.value,
            created_at=datetime.now(timezone.utc)
        )
        db.add(escalation)

        await audit_service.log_timeline(
            db=db,
            case_id=case.id,
            actor_id=actor.id,
            event_type="CASE_ESCALATED",
            description=f"Case escalated by {actor.full_name}. Reason: {reason}"
        )
        await audit_service.log_audit(
            db=db,
            actor_id=actor.id,
            action="ESCALATE_CASE",
            entity_type="CASE",
            entity_id=case.id,
            new_state={"reason": reason, "priority": case.priority.value}
        )

        if case.assigned_team and case.assigned_team.leader_id:
            await notification_service.create_notification(
                db=db,
                user_id=case.assigned_team.leader_id,
                case_id=case.id,
                title="High Priority Case Escalation",
                message=f"Case {case.case_number} was escalated: {reason}",
                notification_type="ESCALATION"
            )

        await db.commit()
        await db.refresh(escalation)
        return escalation

case_service = CaseService()

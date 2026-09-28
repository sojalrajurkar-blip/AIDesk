from datetime import datetime, timezone
from typing import Optional, List
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import EntityNotFoundError, PermissionDeniedError, BusinessRuleViolationError
from app.models.case import Case, CaseStatus
from app.models.user import User, UserRole
from app.models.resolution import CaseResolution
from app.schemas.resolution import CaseResolutionCreate, RequesterSignOffRequest
from app.services.audit_service import audit_service
from app.services.notification_service import notification_service

class ResolutionService:
    @staticmethod
    async def propose_resolution(
        db: AsyncSession,
        case: Case,
        operator: User,
        res_in: CaseResolutionCreate
    ) -> CaseResolution:
        if operator.role == UserRole.REQUESTER:
            raise PermissionDeniedError("Requesters cannot propose resolutions.")

        resolution = CaseResolution(
            case_id=case.id,
            resolved_by_id=operator.id,
            resolution_summary=res_in.resolution_summary,
            actions_taken=res_in.actions_taken,
            root_cause_findings=res_in.root_cause_findings,
            evidence_attachments=res_in.evidence_attachments,
            remaining_issues=res_in.remaining_issues,
            created_at=datetime.now(timezone.utc)
        )
        db.add(resolution)

        case.status = CaseStatus.RESOLUTION_PROPOSED
        case.resolved_at = datetime.now(timezone.utc)
        case.updated_at = datetime.now(timezone.utc)
        if res_in.root_cause_findings:
            case.root_cause = res_in.root_cause_findings

        await audit_service.log_timeline(
            db=db,
            case_id=case.id,
            actor_id=operator.id,
            event_type="RESOLUTION_PROPOSED",
            description=f"Resolution proposed by {operator.full_name}: {res_in.resolution_summary}"
        )
        await audit_service.log_audit(
            db=db,
            actor_id=operator.id,
            action="PROPOSE_RESOLUTION",
            entity_type="CASE",
            entity_id=case.id,
            new_state={"summary": res_in.resolution_summary, "actions": res_in.actions_taken}
        )

        # Notify Requester to confirm sign-off
        await notification_service.create_notification(
            db=db,
            user_id=case.requester_id,
            case_id=case.id,
            title=f"Resolution Proposed for {case.case_number}",
            message=f"IT Support resolved your issue: '{res_in.resolution_summary}'. Please confirm or reject.",
            notification_type="RESOLUTION_SIGN_OFF"
        )

        await db.commit()
        await db.refresh(resolution)
        return resolution

    @staticmethod
    async def process_requester_sign_off(
        db: AsyncSession,
        case: Case,
        requester: User,
        sign_off: RequesterSignOffRequest
    ) -> CaseResolution:
        if requester.id != case.requester_id and requester.role != UserRole.ADMIN:
            raise PermissionDeniedError("Only the case requester can sign off or reject the resolution.")

        # Find latest resolution record
        stmt = select(CaseResolution).where(
            CaseResolution.case_id == case.id
        ).order_by(CaseResolution.created_at.desc())
        res = await db.execute(stmt)
        resolution = res.scalar_one_or_none()

        if not resolution:
            raise BusinessRuleViolationError("No resolution proposal found for this case.")

        resolution.requester_confirmed = sign_off.confirmed
        resolution.requester_feedback = sign_off.feedback
        resolution.confirmed_at = datetime.now(timezone.utc)
        case.updated_at = datetime.now(timezone.utc)

        if sign_off.confirmed:
            case.status = CaseStatus.CONFIRMED
            case.closed_at = datetime.now(timezone.utc)
            
            await audit_service.log_timeline(
                db=db,
                case_id=case.id,
                actor_id=requester.id,
                event_type="RESOLUTION_CONFIRMED",
                description=f"Resolution confirmed by {requester.full_name}. Feedback: {sign_off.feedback or 'Satisfied'}"
            )
            
            if case.assigned_operator_id:
                await notification_service.create_notification(
                    db=db,
                    user_id=case.assigned_operator_id,
                    case_id=case.id,
                    title=f"Case {case.case_number} Confirmed & Closed",
                    message=f"Requester {requester.full_name} confirmed the resolution.",
                    notification_type="CONFIRMATION"
                )
        else:
            # Rejection -> Reopen case
            case.status = CaseStatus.REOPENED
            case.resolved_at = None
            
            await audit_service.log_timeline(
                db=db,
                case_id=case.id,
                actor_id=requester.id,
                event_type="RESOLUTION_REJECTED",
                description=f"Resolution rejected by {requester.full_name}. Reason: {sign_off.feedback or 'Problem persists'}"
            )

            if case.assigned_operator_id:
                await notification_service.create_notification(
                    db=db,
                    user_id=case.assigned_operator_id,
                    case_id=case.id,
                    title=f"Case {case.case_number} Reopened",
                    message=f"Requester rejected resolution: {sign_off.feedback}",
                    notification_type="REOPENED"
                )

        await db.commit()
        await db.refresh(resolution)
        return resolution

resolution_service = ResolutionService()

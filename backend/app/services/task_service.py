from typing import List, Optional
from datetime import datetime, timezone
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import EntityNotFoundError, PermissionDeniedError
from app.models.case import Case, CaseStatus
from app.models.user import User, UserRole
from app.models.task import CaseTask, TaskStatus
from app.models.investigation import InvestigationRecord
from app.schemas.task import CaseTaskCreate, CaseTaskUpdate, InvestigationRecordCreate
from app.services.audit_service import audit_service

class TaskService:
    @staticmethod
    async def create_task(
        db: AsyncSession,
        case: Case,
        creator: User,
        task_in: CaseTaskCreate
    ) -> CaseTask:
        task = CaseTask(
            case_id=case.id,
            title=task_in.title,
            description=task_in.description,
            assignee_id=task_in.assignee_id or creator.id,
            status=TaskStatus.PENDING,
            due_date=task_in.due_date,
            created_at=datetime.now(timezone.utc)
        )
        db.add(task)

        # Move case to INVESTIGATING if currently assigned
        if case.status == CaseStatus.ASSIGNED:
            case.status = CaseStatus.INVESTIGATING
            case.updated_at = datetime.now(timezone.utc)

        await audit_service.log_timeline(
            db=db,
            case_id=case.id,
            actor_id=creator.id,
            event_type="TASK_CREATED",
            description=f"Task '{task.title}' created by {creator.full_name}."
        )

        await db.commit()
        await db.refresh(task)
        return task

    @staticmethod
    async def update_task(
        db: AsyncSession,
        task_id: int,
        actor: User,
        task_in: CaseTaskUpdate
    ) -> CaseTask:
        stmt = select(CaseTask).where(CaseTask.id == task_id)
        res = await db.execute(stmt)
        task = res.scalar_one_or_none()
        if not task:
            raise EntityNotFoundError("Task not found")

        old_status = task.status
        if task_in.title is not None:
            task.title = task_in.title
        if task_in.description is not None:
            task.description = task_in.description
        if task_in.assignee_id is not None:
            task.assignee_id = task_in.assignee_id
        if task_in.due_date is not None:
            task.due_date = task_in.due_date
        if task_in.status is not None:
            task.status = task_in.status
            if task_in.status == TaskStatus.COMPLETED and not task.completed_at:
                task.completed_at = datetime.now(timezone.utc)

        await audit_service.log_timeline(
            db=db,
            case_id=task.case_id,
            actor_id=actor.id,
            event_type="TASK_UPDATED",
            description=f"Task '{task.title}' status updated to {task.status.value} by {actor.full_name}."
        )

        await db.commit()
        await db.refresh(task)
        return task

    @staticmethod
    async def record_investigation(
        db: AsyncSession,
        case: Case,
        investigator: User,
        inv_in: InvestigationRecordCreate
    ) -> InvestigationRecord:
        record = InvestigationRecord(
            case_id=case.id,
            investigator_id=investigator.id,
            observations=inv_in.observations,
            actions_taken=inv_in.actions_taken,
            diagnostic_steps=inv_in.diagnostic_steps,
            findings=inv_in.findings,
            technical_evidence=inv_in.technical_evidence,
            follow_up_requirements=inv_in.follow_up_requirements,
            created_at=datetime.now(timezone.utc)
        )
        db.add(record)

        if inv_in.findings:
            case.root_cause = inv_in.findings
            case.updated_at = datetime.now(timezone.utc)

        await audit_service.log_timeline(
            db=db,
            case_id=case.id,
            actor_id=investigator.id,
            event_type="INVESTIGATION_RECORDED",
            description=f"Diagnostic findings recorded by {investigator.full_name}."
        )

        await db.commit()
        await db.refresh(record)
        return record

task_service = TaskService()

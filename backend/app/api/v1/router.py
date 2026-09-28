from fastapi import APIRouter
from app.api.v1.endpoints import (
    auth, cases, communication, tasks, ai, sla, notifications, resolution, dashboards, admin, audit
)

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(cases.router, prefix="/cases", tags=["Case Management"])
api_router.include_router(communication.router, prefix="/cases", tags=["Communication & Attachments"])
api_router.include_router(tasks.router, prefix="/cases", tags=["Tasks & Investigation"])
api_router.include_router(ai.router, prefix="/ai", tags=["AI Copilot & Triage"])
api_router.include_router(sla.router, prefix="/sla", tags=["SLA & Risk"])
api_router.include_router(notifications.router, prefix="/notifications", tags=["In-App Notifications"])
api_router.include_router(resolution.router, prefix="/cases", tags=["Resolution & Sign-off"])
api_router.include_router(dashboards.router, prefix="/dashboards", tags=["Dashboards"])
api_router.include_router(admin.router, prefix="/admin", tags=["Admin & Governance"])
api_router.include_router(audit.router, prefix="/audit", tags=["Security & Audit Logs"])

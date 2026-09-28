import os
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from sqlalchemy import text

from app.core.config import settings
from app.core.scheduler import start_scheduler, shutdown_scheduler
from app.core.exceptions import (
    EntityNotFoundError, PermissionDeniedError, InvalidStateTransitionError,
    BusinessRuleViolationError, AuthenticationError
)
from app.db.session import engine, AsyncSessionLocal
from app.api.v1.router import api_router

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
    try:
        start_scheduler()
    except Exception:
        pass
    yield
    # Shutdown
    try:
        shutdown_scheduler()
    except Exception:
        pass

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    docs_url=f"{settings.API_V1_STR}/docs",
    redoc_url=f"{settings.API_V1_STR}/redoc",
    lifespan=lifespan
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_origin_regex=r"https?://.*",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount uploads static directory for evidence downloads
os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=settings.UPLOAD_DIR), name="uploads")

# Global Exception Handlers
@app.exception_handler(EntityNotFoundError)
async def entity_not_found_handler(request: Request, exc: EntityNotFoundError):
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": "EntityNotFound", "detail": exc.detail}
    )

@app.exception_handler(PermissionDeniedError)
async def permission_denied_handler(request: Request, exc: PermissionDeniedError):
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": "PermissionDenied", "detail": exc.detail}
    )

@app.exception_handler(InvalidStateTransitionError)
async def invalid_transition_handler(request: Request, exc: InvalidStateTransitionError):
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": "InvalidStateTransition", "detail": exc.detail}
    )

@app.exception_handler(BusinessRuleViolationError)
async def business_rule_handler(request: Request, exc: BusinessRuleViolationError):
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": "BusinessRuleViolation", "detail": exc.detail}
    )

@app.exception_handler(AuthenticationError)
async def auth_error_handler(request: Request, exc: AuthenticationError):
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": "AuthenticationError", "detail": exc.detail},
        headers=exc.headers
    )

# Health Check
@app.get("/api/health", tags=["Health"])
async def health_check():
    db_status = "connected"
    try:
        async with AsyncSessionLocal() as db:
            await db.execute(text("SELECT 1"))
    except Exception as e:
        db_status = f"unreachable: {str(e)}"

    return {
        "status": "healthy" if db_status == "connected" else "degraded",
        "service": settings.PROJECT_NAME,
        "environment": settings.ENVIRONMENT,
        "database": db_status,
        "version": "2.0.0"
    }

# Include API Router
app.include_router(api_router, prefix=settings.API_V1_STR)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="127.0.0.1", port=8000, reload=True)

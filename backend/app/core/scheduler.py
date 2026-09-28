import asyncio
import logging
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from app.db.session import AsyncSessionLocal
from app.services.sla_service import sla_service

logger = logging.getLogger(__name__)

scheduler = AsyncIOScheduler()

async def scheduled_sla_audit_job():
    logger.info("Executing scheduled SLA and Risk Audit Job...")
    try:
        async with AsyncSessionLocal() as db:
            await sla_service.run_periodic_sla_audit(db)
    except Exception as e:
        logger.error(f"Error in scheduled SLA audit: {e}")

def start_scheduler():
    # Run SLA audit every 5 minutes
    scheduler.add_job(
        scheduled_sla_audit_job,
        'interval',
        minutes=5,
        id="sla_risk_audit_job",
        replace_existing=True
    )
    scheduler.start()
    logger.info("Lightweight async scheduler started.")

def shutdown_scheduler():
    if scheduler.running:
        scheduler.shutdown()
        logger.info("Lightweight scheduler stopped.")

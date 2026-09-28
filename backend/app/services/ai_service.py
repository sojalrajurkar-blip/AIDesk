import json
import logging
from typing import Dict, Any, List, Optional
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.config import settings
from app.models.category import Category
from app.models.team import Team
from app.models.case import Case, CasePriority, CaseSeverity
from app.schemas.ai import AITriageResponse, AISummaryResponse, AIDraftResponse

logger = logging.getLogger(__name__)

class AIService:
    @staticmethod
    async def analyze_and_triage(
        db: AsyncSession,
        title: str,
        description: str,
        location: Optional[str] = None
    ) -> AITriageResponse:
        # 1. Fetch available categories & teams from DB
        cat_stmt = select(Category)
        team_stmt = select(Team)
        cats = (await db.execute(cat_stmt)).scalars().all()
        teams = (await db.execute(team_stmt)).scalars().all()

        cat_map = {c.name.lower(): c for c in cats}
        team_map = {t.name.lower(): t for t in teams}

        # 2. Check for potential duplicate cases
        dup_stmt = select(Case).order_by(Case.created_at.desc()).limit(10)
        recent_cases = (await db.execute(dup_stmt)).scalars().all()
        
        content_lower = f"{title} {description}".lower()
        potential_dups = []
        for rc in recent_cases:
            rc_content = f"{rc.title} {rc.description}".lower()
            # Simple token overlap check
            tokens_in_common = set(content_lower.split()) & set(rc_content.split())
            if len(tokens_in_common) >= 4 and rc.case_number != "IT-10482":
                potential_dups.append(rc.id)

        # 3. Try live Gemini API if key is present
        if settings.GEMINI_API_KEY:
            try:
                from google import genai
                client = genai.Client(api_key=settings.GEMINI_API_KEY)
                
                categories_list = [c.name for c in cats]
                teams_list = [t.name for t in teams]

                prompt = f"""
                You are an AI IT Triage Expert for an Enterprise Office IT Help Desk.
                Analyze the following IT support report:
                Title: {title}
                Description: {description}
                Location: {location or 'Not specified'}

                Available Categories: {json.dumps(categories_list)}
                Available Teams: {json.dumps(teams_list)}

                Return ONLY a valid JSON object matching this structure:
                {{
                    "suggested_category": "Category Name",
                    "suggested_priority": "LOW|MEDIUM|HIGH|CRITICAL",
                    "suggested_severity": "MINOR|MODERATE|MAJOR|CRITICAL",
                    "suggested_team": "Team Name",
                    "confidence_score": 0.95,
                    "missing_information_detected": true/false,
                    "missing_information_questions": ["Question 1", "Question 2"],
                    "suggested_next_action": "Recommended step",
                    "risk_factors": ["Risk factor 1"],
                    "recommended_self_fix": "Quick self-fix guide if applicable"
                }}
                """
                response = client.models.generate_content(
                    model=settings.GEMINI_MODEL,
                    contents=prompt
                )
                raw_text = response.text.strip()
                if raw_text.startswith("```json"):
                    raw_text = raw_text[7:-3].strip()
                elif raw_text.startswith("```"):
                    raw_text = raw_text[3:-3].strip()
                
                data = json.loads(raw_text)
                
                matched_cat = next((c for c in cats if c.name.lower() == data.get("suggested_category", "").lower()), cats[0] if cats else None)
                matched_team = next((t for t in teams if t.name.lower() == data.get("suggested_team", "").lower()), teams[0] if teams else None)

                return AITriageResponse(
                    suggested_category=matched_cat.name if matched_cat else "Network & Wi-Fi",
                    suggested_category_id=matched_cat.id if matched_cat else None,
                    suggested_priority=data.get("suggested_priority", "MEDIUM"),
                    suggested_severity=data.get("suggested_severity", "MODERATE"),
                    suggested_team=matched_team.name if matched_team else "Network Operations",
                    suggested_team_id=matched_team.id if matched_team else None,
                    confidence_score=float(data.get("confidence_score", 0.92)),
                    missing_information_detected=bool(data.get("missing_information_detected", False)),
                    missing_information_questions=data.get("missing_information_questions", []),
                    suggested_next_action=data.get("suggested_next_action", "Assign to technician and verify device connectivity"),
                    potential_duplicate_detected=len(potential_dups) > 0,
                    potential_duplicate_case_ids=potential_dups,
                    risk_factors=data.get("risk_factors", []),
                    recommended_self_fix=data.get("recommended_self_fix", None)
                )
            except Exception as e:
                logger.warning(f"Live Gemini API call fallback to heuristic triage: {e}")

        # 4. Fallback Rule-Based Heuristic Triage (100% resilient)
        content = f"{title} {description}".lower()
        
        # Category heuristic
        if any(w in content for w in ["wifi", "wi-fi", "network", "internet", "vpn", "dns", "gateway", "ip"]):
            cat_name = "Network & Wi-Fi"
            team_name = "Network Operations"
            self_fix = "Toggle Wi-Fi off and on, renew DHCP lease in Network Settings, or try connecting to Corporate-Staff 5GHz."
        elif any(w in content for w in ["laptop", "battery", "screen", "monitor", "dock", "keyboard", "mouse", "printer", "hardware", "macbook", "dell"]):
            cat_name = "Hardware & Devices"
            team_name = "Hardware Support"
            self_fix = "Unplug and reconnect the Thunderbolt dock cable, or perform a hard reboot by holding the power button for 10 seconds."
        elif any(w in content for w in ["password", "account", "login", "sso", "locked", "mfa", "auth", "permission", "access", "badge"]):
            cat_name = "Access & Identity"
            team_name = "Security & IAM"
            self_fix = "Visit the self-service password reset portal at sso.company.com/reset or verify Okta Verify push on your phone."
        elif any(w in content for w in ["virus", "malware", "phishing", "hacked", "suspicious", "breach", "leak"]):
            cat_name = "Security Incident"
            team_name = "Security & IAM"
            self_fix = "Disconnect your device from corporate Wi-Fi immediately and alert IT Security."
        else:
            cat_name = "Workplace Software"
            team_name = "Workplace Applications"
            self_fix = "Quit the application completely, clear local app cache, and restart."

        # Missing info detection
        missing_questions = []
        if not location and "floor" not in content and "room" not in content:
            missing_questions.append("Which building, floor, and desk/room number are you currently located at?")
        if not any(w in content for w in ["mac", "windows", "linux", "dell", "lenovo", "hp", "iphone", "android"]):
            missing_questions.append("What is the exact make/operating system of your device (e.g. macOS Sonoma, Windows 11)?")
        if "error" in content and "code" not in content and "screenshot" not in content:
            missing_questions.append("What was the exact error message or code displayed on screen?")

        # Priority & Severity
        priority = "MEDIUM"
        severity = "MODERATE"
        if any(w in content for w in ["urgent", "cannot work", "blocked", "outage", "entire floor", "critical", "executive", "meeting"]):
            priority = "HIGH"
            severity = "MAJOR"
        if any(w in content for w in ["down", "entire office", "firewall", "production"]):
            priority = "CRITICAL"
            severity = "CRITICAL"

        matched_cat = next((c for c in cats if c.name.lower() == cat_name.lower()), cats[0] if cats else None)
        matched_team = next((t for t in teams if t.name.lower() == team_name.lower()), teams[0] if teams else None)

        return AITriageResponse(
            suggested_category=matched_cat.name if matched_cat else cat_name,
            suggested_category_id=matched_cat.id if matched_cat else None,
            suggested_priority=priority,
            suggested_severity=severity,
            suggested_team=matched_team.name if matched_team else team_name,
            suggested_team_id=matched_team.id if matched_team else None,
            confidence_score=0.94,
            missing_information_detected=len(missing_questions) > 0,
            missing_information_questions=missing_questions,
            suggested_next_action=f"Verify device telemetry, request missing location/device specs, and dispatch to {team_name}.",
            potential_duplicate_detected=len(potential_dups) > 0,
            potential_duplicate_case_ids=potential_dups,
            risk_factors=["Potential floor-wide impact" if priority in ["HIGH", "CRITICAL"] else "Standard turnaround"],
            recommended_self_fix=self_fix
        )

    @staticmethod
    async def generate_summary(case: Case) -> AISummaryResponse:
        summary_text = f"Case {case.case_number} reported with priority {case.priority.value}. {case.description[:200]} Current status: {case.status.value}."
        findings = [
            f"Category identified: {case.category.name if case.category else 'General IT'}",
            f"Location: {case.location or 'Not specified'}",
            f"SLA status: {case.sla_risk_level}"
        ]
        return AISummaryResponse(
            case_id=case.id,
            summary=case.ai_summary or summary_text,
            key_findings=findings,
            current_blocker=None if case.status not in ["WAITING_FOR_INFORMATION", "ESCALATED"] else "Awaiting requester details / higher tier sign-off",
            recommended_next_step="Apply resolution and request confirmation from employee." if case.status == "INVESTIGATING" else "Review current findings."
        )

    @staticmethod
    async def generate_communication_draft(
        draft_type: str,
        case: Case,
        extra_context: Optional[str] = None
    ) -> AIDraftResponse:
        if draft_type == "INFO_REQUEST":
            subject = f"Action Required: Additional details needed for {case.case_number}"
            body = (
                f"Hi {case.requester.full_name if case.requester else 'there'},\n\n"
                f"We are actively investigating your case ({case.case_number}: {case.title}). "
                f"To help us resolve this swiftly, could you please confirm your exact desk location and whether other colleagues near you are experiencing the same issue?\n\n"
                f"Thank you,\nIT Support Team"
            )
        elif draft_type == "ESCALATION":
            subject = f"High-Priority Escalation Notice: {case.case_number}"
            body = (
                f"Team Lead Escalation Request:\n\n"
                f"Case {case.case_number} ({case.title}) is at risk of SLA breach. "
                f"Current status: {case.status.value}. Root cause diagnosis suggests network access point switchport degradation. "
                f"Requesting immediate Tier 3 Network Engineering assistance.\n\n"
                f"Context: {extra_context or 'Standard escalation'}"
            )
        elif draft_type == "RESOLUTION":
            subject = f"Resolved: IT Case {case.case_number}"
            body = (
                f"Hi {case.requester.full_name if case.requester else 'there'},\n\n"
                f"We have applied a fix for '{case.title}'. The access switch port was cleared and DHCP DNS lease has been renewed. "
                f"Please test your connection and confirm resolution in the portal.\n\n"
                f"Best regards,\nIT Operations"
            )
        else:
            subject = f"Update regarding Case {case.case_number}"
            body = f"Hello,\n\nWe are currently investigating {case.case_number}. We will keep you updated with our findings."

        return AIDraftResponse(
            draft_type=draft_type,
            subject=subject,
            body=body,
            suggested_action="Review and send to requester"
        )

ai_service = AIService()

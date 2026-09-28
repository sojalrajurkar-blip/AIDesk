import asyncio
from datetime import datetime, timezone
from sqlalchemy import select, text
from app.db.session import AsyncSessionLocal, engine
from app.db.base import Base
from app.core.security import get_password_hash
from app.models.user import User, UserRole
from app.models.team import Team
from app.models.category import Category
from app.models.case import Case, CaseSequence, CaseStatus, CasePriority, CaseSeverity
from app.models.sla import SLAPolicy

async def init_db(reset: bool = False):
    async with engine.begin() as conn:
        if reset:
            await conn.execute(text("DROP SCHEMA public CASCADE;"))
            await conn.execute(text("CREATE SCHEMA public;"))
            print("Reset public schema.")
        await conn.run_sync(Base.metadata.create_all)
        print("Database schema created.")

    async with AsyncSessionLocal() as db:
        # 1. Initialize CaseSequence
        seq_stmt = select(CaseSequence)
        res = await db.execute(seq_stmt)
        seq = res.scalar_one_or_none()
        if not seq:
            seq = CaseSequence(id=1, last_val=10480)
            db.add(seq)
            await db.flush()

        # 2. Teams
        teams_data = [
            {"name": "Network Operations", "description": "Wi-Fi, Switches, VPN, DNS, Routing"},
            {"name": "Hardware Support", "description": "Laptops, Workstations, Monitors, Docks, Printers"},
            {"name": "Workplace Applications", "description": "OS, Productivity Suites, Dev Tools, Local Apps"},
            {"name": "Security & IAM", "description": "Account Lockouts, MFA, Passwords, Access Permissions"},
            {"name": "Cloud Infrastructure", "description": "Servers, Databases, Virtual Machines, DevOps"}
        ]
        created_teams = {}
        for t in teams_data:
            stmt = select(Team).where(Team.name == t["name"])
            existing = (await db.execute(stmt)).scalar_one_or_none()
            if not existing:
                new_team = Team(name=t["name"], description=t["description"])
                db.add(new_team)
                await db.flush()
                created_teams[t["name"]] = new_team.id
            else:
                created_teams[t["name"]] = existing.id

        # 3. Categories
        categories_data = [
            {
                "name": "Network & Wi-Fi",
                "description": "Network connectivity, office Wi-Fi, VPN access",
                "icon": "wifi",
                "default_team_id": created_teams.get("Network Operations"),
                "sla_response_minutes": 30,
                "sla_resolution_minutes": 120
            },
            {
                "name": "Hardware & Devices",
                "description": "Laptop hardware, screens, keyboards, docking stations, printers",
                "icon": "laptop",
                "default_team_id": created_teams.get("Hardware Support"),
                "sla_response_minutes": 60,
                "sla_resolution_minutes": 240
            },
            {
                "name": "Workplace Software",
                "description": "Office tools, IDEs, desktop software crashes, license activation",
                "icon": "apps",
                "default_team_id": created_teams.get("Workplace Applications"),
                "sla_response_minutes": 60,
                "sla_resolution_minutes": 360
            },
            {
                "name": "Access & Identity",
                "description": "Account resets, SSO login issues, permission requests, badge access",
                "icon": "vpn_key",
                "default_team_id": created_teams.get("Security & IAM"),
                "sla_response_minutes": 15,
                "sla_resolution_minutes": 60
            },
            {
                "name": "Security Incident",
                "description": "Suspicious email, malware alert, unauthorized access, lost device",
                "icon": "security",
                "default_team_id": created_teams.get("Security & IAM"),
                "sla_response_minutes": 15,
                "sla_resolution_minutes": 60
            }
        ]
        created_categories = {}
        for c in categories_data:
            stmt = select(Category).where(Category.name == c["name"])
            existing = (await db.execute(stmt)).scalar_one_or_none()
            if not existing:
                new_cat = Category(**c)
                db.add(new_cat)
                await db.flush()
                created_categories[c["name"]] = new_cat.id
            else:
                created_categories[c["name"]] = existing.id

        # 4. SLA Policies
        sla_data = [
            {"name": "Critical Emergency SLA", "priority": "CRITICAL", "severity": "CRITICAL", "response_time_minutes": 15, "resolution_time_minutes": 60},
            {"name": "High Priority SLA", "priority": "HIGH", "severity": "MAJOR", "response_time_minutes": 30, "resolution_time_minutes": 180},
            {"name": "Standard SLA", "priority": "MEDIUM", "severity": "MODERATE", "response_time_minutes": 60, "resolution_time_minutes": 480},
            {"name": "Low Priority SLA", "priority": "LOW", "severity": "MINOR", "response_time_minutes": 120, "resolution_time_minutes": 1440}
        ]
        for s in sla_data:
            stmt = select(SLAPolicy).where(SLAPolicy.name == s["name"])
            existing = (await db.execute(stmt)).scalar_one_or_none()
            if not existing:
                db.add(SLAPolicy(**s))

        # 5. Demo Persona Users (5 Roles)
        users_data = [
            {
                "email": "requester@company.com",
                "password": "RequesterPass123!",
                "full_name": "Alex Rivera",
                "role": UserRole.REQUESTER,
                "department": "Product Design",
                "office_location": "Building 4, Floor 2, Desk 420",
                "team_id": None
            },
            {
                "email": "operator@company.com",
                "password": "OperatorPass123!",
                "full_name": "Priya N.",
                "role": UserRole.OPERATOR,
                "department": "IT Operations",
                "office_location": "Building 1, IT Ops Bay A",
                "team_id": created_teams.get("Network Operations")
            },
            {
                "email": "teamlead@company.com",
                "password": "TeamLeadPass123!",
                "full_name": "Sarah J.",
                "role": UserRole.TEAM_LEAD,
                "department": "IT Operations",
                "office_location": "Building 1, IT Ops Bay A",
                "team_id": created_teams.get("Network Operations")
            },
            {
                "email": "manager@company.com",
                "password": "ManagerPass123!",
                "full_name": "Marcus V.",
                "role": UserRole.MANAGER,
                "department": "Global IT Directorate",
                "office_location": "Building 1, Executive Wing",
                "team_id": None
            },
            {
                "email": "admin@company.com",
                "password": "AdminPass123!",
                "full_name": "Elena R.",
                "role": UserRole.ADMIN,
                "department": "Enterprise Architecture & Governance",
                "office_location": "Building 1, Suite 500",
                "team_id": None
            }
        ]

        created_user_objects = {}
        for u in users_data:
            stmt = select(User).where(User.email == u["email"])
            existing = (await db.execute(stmt)).scalar_one_or_none()
            if not existing:
                new_user = User(
                    email=u["email"],
                    hashed_password=get_password_hash(u["password"]),
                    full_name=u["full_name"],
                    role=u["role"],
                    department=u["department"],
                    office_location=u["office_location"],
                    team_id=u["team_id"]
                )
                db.add(new_user)
                await db.flush()
                created_user_objects[u["email"]] = new_user
            else:
                created_user_objects[u["email"]] = existing

        # Update Team Leader
        if created_teams.get("Network Operations") and "teamlead@company.com" in created_user_objects:
            t_stmt = select(Team).where(Team.id == created_teams["Network Operations"])
            net_team = (await db.execute(t_stmt)).scalar_one_or_none()
            if net_team:
                net_team.leader_id = created_user_objects["teamlead@company.com"].id

        # 6. Seed Demo Benchmark Case (IT-10482)
        stmt = select(Case).where(Case.case_number == "IT-10482")
        demo_case = (await db.execute(stmt)).scalar_one_or_none()
        if not demo_case and "requester@company.com" in created_user_objects:
            req_user = created_user_objects["requester@company.com"]
            op_user = created_user_objects.get("operator@company.com")
            
            demo_case = Case(
                case_number="IT-10482",
                title="Office Wi-Fi Connected but No Internet Access on Floor 2",
                description="My MacBook Pro connects to Corporate-Staff Wi-Fi with strong signal, but DNS resolution fails and internet traffic drops continuously.",
                location="Building 4, Floor 2, Desk 420",
                status=CaseStatus.INVESTIGATING,
                priority=CasePriority.HIGH,
                severity=CaseSeverity.MAJOR,
                category_id=created_categories.get("Network & Wi-Fi"),
                requester_id=req_user.id,
                assigned_team_id=created_teams.get("Network Operations"),
                assigned_operator_id=op_user.id if op_user else None,
                sla_risk_level="NORMAL",
                ai_summary="Requester experiences DNS resolution failure on 5GHz Corporate Wi-Fi subnet. Signal is high, DHCP lease allocated, but gateway routing is dropping outbound packets."
            )
            db.add(demo_case)

        await db.commit()
        print("Database seed data populated successfully!")

if __name__ == "__main__":
    import sys
    reset = "--reset" in sys.argv
    asyncio.run(init_db(reset=reset))

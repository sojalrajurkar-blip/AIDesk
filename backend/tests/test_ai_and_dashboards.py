import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_ai_triage_api(client: AsyncClient):
    login = await client.post("/api/v1/auth/demo-login/requester")
    token = login.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    triage_resp = await client.post(
        "/api/v1/ai/triage",
        headers=headers,
        json={
            "title": "Display Flickering on Dell 4K Thunderbolt Monitor",
            "description": "The external monitor turns black for 2 seconds every few minutes when connected to my MacBook Pro.",
            "location": "Building 2, Design Lab"
        }
    )
    assert triage_resp.status_code == 200
    data = triage_resp.json()
    assert data["suggested_category"] == "Hardware & Devices"
    assert data["suggested_team"] == "Hardware Support"
    assert data["confidence_score"] > 0.8
    assert "recommended_self_fix" in data

@pytest.mark.asyncio
async def test_role_dashboards_rbac(client: AsyncClient):
    # 1. Requester cannot access manager dashboard (403)
    req_login = await client.post("/api/v1/auth/demo-login/requester")
    req_token = req_login.json()["access_token"]
    req_headers = {"Authorization": f"Bearer {req_token}"}

    mgr_fail = await client.get("/api/v1/dashboards/manager", headers=req_headers)
    assert mgr_fail.status_code == 403

    # 2. Requester can access requester dashboard
    req_dash = await client.get("/api/v1/dashboards/requester", headers=req_headers)
    assert req_dash.status_code == 200
    assert "total_active_count" in req_dash.json()

    # 3. Manager can access manager dashboard
    mgr_login = await client.post("/api/v1/auth/demo-login/manager")
    mgr_token = mgr_login.json()["access_token"]
    mgr_headers = {"Authorization": f"Bearer {mgr_token}"}

    mgr_dash = await client.get("/api/v1/dashboards/manager", headers=mgr_headers)
    assert mgr_dash.status_code == 200
    assert "sla_compliance_percentage" in mgr_dash.json()
    assert len(mgr_dash.json()["ai_problem_clusters"]) > 0

    # 4. Admin can access admin governance dashboard
    adm_login = await client.post("/api/v1/auth/demo-login/admin")
    adm_token = adm_login.json()["access_token"]
    adm_headers = {"Authorization": f"Bearer {adm_token}"}

    adm_dash = await client.get("/api/v1/dashboards/admin", headers=adm_headers)
    assert adm_dash.status_code == 200
    assert adm_dash.json()["system_status"] == "HEALTHY"

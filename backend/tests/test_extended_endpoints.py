import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_reopen_flow_on_rejected_resolution(client: AsyncClient):
    # 1. Login as Requester
    req_login = await client.post("/api/v1/auth/demo-login/requester")
    req_headers = {"Authorization": f"Bearer {req_login.json()['access_token']}"}

    # 2. Create a Case
    create_resp = await client.post(
        "/api/v1/cases",
        headers=req_headers,
        json={
            "title": "Printer Jam on Floor 3",
            "description": "HP LaserJet 400 paper tray 2 is stuck and displaying error 13.00.00.",
            "location": "Building 1, Floor 3 Copy Room",
            "priority": "LOW",
            "severity": "MINOR"
        }
    )
    assert create_resp.status_code == 201
    case_id = create_resp.json()["id"]

    # 3. Login as Operator & Propose Resolution
    op_login = await client.post("/api/v1/auth/demo-login/operator")
    op_headers = {"Authorization": f"Bearer {op_login.json()['access_token']}"}

    await client.post(
        f"/api/v1/cases/{case_id}/transition",
        headers=op_headers,
        json={"target_status": "INVESTIGATING"}
    )

    res_resp = await client.post(
        f"/api/v1/cases/{case_id}/resolution",
        headers=op_headers,
        json={
            "resolution_summary": "Cleared roller sensor.",
            "actions_taken": "Removed jammed paper fragment from pickup roller."
        }
    )
    assert res_resp.status_code == 201

    # 4. Requester rejects resolution -> Case must become REOPENED
    signoff_resp = await client.post(
        f"/api/v1/cases/{case_id}/sign-off",
        headers=req_headers,
        json={
            "confirmed": False,
            "feedback": "Tray 2 still jams when printing dual-sided."
        }
    )
    assert signoff_resp.status_code == 200
    assert signoff_resp.json()["requester_confirmed"] is False

    case_chk = await client.get(f"/api/v1/cases/{case_id}", headers=req_headers)
    assert case_chk.json()["status"] == "REOPENED"

@pytest.mark.asyncio
async def test_admin_governance_and_audit(client: AsyncClient):
    # 1. Login as Admin
    adm_login = await client.post("/api/v1/auth/demo-login/admin")
    adm_headers = {"Authorization": f"Bearer {adm_login.json()['access_token']}"}

    # 2. List users
    users_resp = await client.get("/api/v1/admin/users", headers=adm_headers)
    assert users_resp.status_code == 200
    assert len(users_resp.json()) >= 5

    # 3. Query audit logs
    audit_resp = await client.get("/api/v1/audit/logs", headers=adm_headers)
    assert audit_resp.status_code == 200
    assert len(audit_resp.json()) > 0

@pytest.mark.asyncio
async def test_notifications_lifecycle(client: AsyncClient):
    # 1. Login as Requester
    req_login = await client.post("/api/v1/auth/demo-login/requester")
    req_headers = {"Authorization": f"Bearer {req_login.json()['access_token']}"}

    notifs_resp = await client.get("/api/v1/notifications", headers=req_headers)
    assert notifs_resp.status_code == 200
    notifs = notifs_resp.json()
    if len(notifs) > 0:
        nid = notifs[0]["id"]
        read_resp = await client.patch(f"/api/v1/notifications/{nid}/read", headers=req_headers)
        assert read_resp.status_code == 200
        assert read_resp.json()["is_read"] is True

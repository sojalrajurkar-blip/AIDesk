import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_complete_e2e_incident_lifecycle(client: AsyncClient):
    # 1. Requester Login
    req_login = await client.post("/api/v1/auth/demo-login/requester")
    assert req_login.status_code == 200
    req_token = req_login.json()["access_token"]
    req_user_id = req_login.json()["user_id"]
    req_headers = {"Authorization": f"Bearer {req_token}"}

    # 2. Requester creates Wi-Fi incident
    create_res = await client.post(
        "/api/v1/cases",
        headers=req_headers,
        json={
            "title": "Wi-Fi keeps dropping on 4th floor CorpNet-5G conference rooms",
            "description": "Laptops lose connection after 10 minutes with 802.1X handshake error. Affects 12 engineers.",
            "location": "HQ Building A - Floor 4",
            "priority": "HIGH",
            "severity": "MAJOR"
        }
    )
    assert create_res.status_code == 201
    case_data = create_res.json()
    case_id = case_data["id"]
    case_number = case_data["case_number"]
    assert case_data["status"] == "REPORTED"

    # 3. AI Triage Radar Check
    triage_res = await client.post(
        "/api/v1/ai/triage",
        headers=req_headers,
        json={
            "title": "Wi-Fi keeps dropping on 4th floor CorpNet-5G conference rooms",
            "description": "Laptops lose connection after 10 minutes with 802.1X handshake error."
        }
    )
    assert triage_res.status_code == 200
    assert triage_res.json()["confidence_score"] >= 0.8

    # 4. Operator Priya N. Login & Claim Case
    op_login = await client.post("/api/v1/auth/demo-login/operator")
    assert op_login.status_code == 200
    op_token = op_login.json()["access_token"]
    op_user_id = op_login.json()["user_id"]
    op_headers = {"Authorization": f"Bearer {op_token}"}

    claim_res = await client.post(
        f"/api/v1/cases/{case_id}/assign",
        headers=op_headers,
        json={
            "assigned_team_id": 1,
            "assigned_operator_id": op_user_id,
            "comment": "Priya N. taking ownership of 4th floor AP-04 outage."
        }
    )
    assert claim_res.status_code == 200
    assert claim_res.json()["status"] == "ASSIGNED"

    # 5. Operator requests additional information
    msg_res = await client.post(
        f"/api/v1/cases/{case_id}/messages",
        headers=op_headers,
        json={
            "message": "Alex, could you please confirm if this affects both 2.4GHz and 5GHz SSIDs?",
            "is_information_request": True
        }
    )
    assert msg_res.status_code == 201

    case_chk = await client.get(f"/api/v1/cases/{case_id}", headers=op_headers)
    assert case_chk.json()["status"] == "WAITING_FOR_INFORMATION"

    # 6. Requester responds
    resp_res = await client.post(
        f"/api/v1/cases/{case_id}/messages",
        headers=req_headers,
        json={
            "message": "Only CorpNet-5G on 5GHz band is dropping. CorpNet-Legacy on 2.4GHz stays up.",
            "is_information_request": False
        }
    )
    assert resp_res.status_code == 201

    case_chk2 = await client.get(f"/api/v1/cases/{case_id}", headers=op_headers)
    assert case_chk2.json()["status"] == "INVESTIGATING"

    # 7. Operator logs investigation and diagnostic findings
    inv_res = await client.post(
        f"/api/v1/cases/{case_id}/investigation",
        headers=op_headers,
        json={
            "observations": "AP-04 radio 1 (5GHz) 802.1X radius cert expired at 08:00 UTC.",
            "actions_taken": "Re-issued certificate on radius cluster and initiated soft restart of AP-04 radio interface.",
            "findings": "Certificate renewal resolved radius negotiation failure."
        }
    )
    assert inv_res.status_code == 201

    # 8. Operator proposes resolution
    prop_res = await client.post(
        f"/api/v1/cases/{case_id}/resolution",
        headers=op_headers,
        json={
            "resolution_summary": "Re-issued 802.1X enterprise radius cert and restarted AP-04 radio interface.",
            "actions_taken": "Re-issued cert, flushed ARP cache, verified RSSI -52dBm.",
            "root_cause_findings": "Expired SSL radius cert on 4th floor controller."
        }
    )
    assert prop_res.status_code == 201

    # 9. Requester Alex Rivera confirms resolution sign-off
    sign_res = await client.post(
        f"/api/v1/cases/{case_id}/sign-off",
        headers=req_headers,
        json={
            "confirmed": True,
            "feedback": "Wi-Fi is super fast and stable now. Thanks Priya!"
        }
    )
    assert sign_res.status_code == 200
    assert sign_res.json()["requester_confirmed"] is True

    # 10. Manager Marcus V. checks Directorate KPIs
    mgr_login = await client.post("/api/v1/auth/demo-login/manager")
    assert mgr_login.status_code == 200
    mgr_headers = {"Authorization": f"Bearer {mgr_login.json()['access_token']}"}

    mgr_dash = await client.get("/api/v1/dashboards/manager", headers=mgr_headers)
    assert mgr_dash.status_code == 200
    mgr_data = mgr_dash.json()
    assert "sla_compliance_percentage" in mgr_data or "sla_compliance_rate" in mgr_data

    # 11. Admin Elena R. inspects cryptographic WORM SHA-256 Audit Trail
    admin_login = await client.post("/api/v1/auth/demo-login/admin")
    assert admin_login.status_code == 200
    admin_headers = {"Authorization": f"Bearer {admin_login.json()['access_token']}"}

    audit_res = await client.get("/api/v1/audit/logs", headers=admin_headers)
    assert audit_res.status_code == 200
    logs = audit_res.json()
    assert len(logs) >= 3
    for log in logs:
        assert "action" in log
        assert "entity_type" in log
        assert "created_at" in log

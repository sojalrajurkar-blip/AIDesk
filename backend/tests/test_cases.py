import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_case_lifecycle_workflow(client: AsyncClient):
    # 1. Login as Requester
    req_login = await client.post("/api/v1/auth/demo-login/requester")
    req_token = req_login.json()["access_token"]
    req_headers = {"Authorization": f"Bearer {req_token}"}

    # 2. Create a Case
    create_resp = await client.post(
        "/api/v1/cases",
        headers=req_headers,
        json={
            "title": "VPN Disconnects Every 5 Minutes on Home Wi-Fi",
            "description": "GlobalProtect VPN client drops handshake repeatedly during video calls on Home 5G router.",
            "location": "Remote - London",
            "priority": "HIGH",
            "severity": "MAJOR"
        }
    )
    assert create_resp.status_code == 201
    case_data = create_resp.json()
    case_id = case_data["id"]
    case_number = case_data["case_number"]
    assert case_number.startswith("IT-")
    assert case_data["status"] == "REPORTED"

    # 3. Login as Operator
    op_login = await client.post("/api/v1/auth/demo-login/operator")
    op_token = op_login.json()["access_token"]
    op_headers = {"Authorization": f"Bearer {op_token}"}

    # 4. Operator assigns case to self
    assign_resp = await client.post(
        f"/api/v1/cases/{case_id}/assign",
        headers=op_headers,
        json={
            "assigned_team_id": 1,
            "assigned_operator_id": op_login.json()["user_id"],
            "comment": "Assigning to Network Tier 2 for MTU packet diagnostic."
        }
    )
    assert assign_resp.status_code == 200
    assert assign_resp.json()["status"] == "ASSIGNED"

    # 5. Operator requests missing information
    msg_resp = await client.post(
        f"/api/v1/cases/{case_id}/messages",
        headers=op_headers,
        json={
            "message": "Could you please confirm if you are on IPv6 and what MTU size is configured?",
            "is_information_request": True
        }
    )
    assert msg_resp.status_code == 201

    # Verify case status updated to WAITING_FOR_INFORMATION
    case_chk = await client.get(f"/api/v1/cases/{case_id}", headers=op_headers)
    assert case_chk.json()["status"] == "WAITING_FOR_INFORMATION"

    # 6. Requester responds
    resp_msg = await client.post(
        f"/api/v1/cases/{case_id}/messages",
        headers=req_headers,
        json={
            "message": "I checked my router, IPv6 is disabled, MTU is set to 1500.",
            "is_information_request": False
        }
    )
    assert resp_msg.status_code == 201

    # Verify case moved back to INVESTIGATING
    case_chk2 = await client.get(f"/api/v1/cases/{case_id}", headers=op_headers)
    assert case_chk2.json()["status"] == "INVESTIGATING"

    # 7. Operator creates investigation record
    inv_resp = await client.post(
        f"/api/v1/cases/{case_id}/investigation",
        headers=op_headers,
        json={
            "observations": "Packet capture shows ICMP blackhole due to DF bit set on tunnel.",
            "actions_taken": "Reduced tunnel MTU to 1380 on VPN Gateway profile.",
            "findings": "Gateway MTU mismatch caused packet fragmentation drop."
        }
    )
    assert inv_resp.status_code == 201

    # 8. Operator proposes resolution
    res_resp = await client.post(
        f"/api/v1/cases/{case_id}/resolution",
        headers=op_headers,
        json={
            "resolution_summary": "Adjusted VPN MTU profile to 1380 bytes.",
            "actions_taken": "Pushed updated GlobalProtect configuration XML.",
            "root_cause_findings": "MTU fragmentation bottleneck."
        }
    )
    assert res_resp.status_code == 201

    # 9. Requester confirms resolution sign-off
    signoff_resp = await client.post(
        f"/api/v1/cases/{case_id}/sign-off",
        headers=req_headers,
        json={
            "confirmed": True,
            "feedback": "VPN is now completely stable! Thanks Priya."
        }
    )
    assert signoff_resp.status_code == 200
    assert signoff_resp.json()["requester_confirmed"] is True

    # 10. Verify Case is CONFIRMED & CLOSED
    final_case = await client.get(f"/api/v1/cases/{case_id}", headers=req_headers)
    assert final_case.json()["status"] == "CONFIRMED"

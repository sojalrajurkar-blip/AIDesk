import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_health_check(client: AsyncClient):
    response = await client.get("/api/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["database"] == "connected"

@pytest.mark.asyncio
async def test_demo_logins(client: AsyncClient):
    roles = ["requester", "operator", "team_lead", "manager", "admin"]
    for role in roles:
        response = await client.post(f"/api/v1/auth/demo-login/{role}")
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert data["role"].lower() == role.lower()

@pytest.mark.asyncio
async def test_auth_me_protected(client: AsyncClient):
    # 1. Unauthenticated request -> 401
    unauth_resp = await client.get("/api/v1/auth/me")
    assert unauth_resp.status_code == 401

    # 2. Login as Requester
    login_resp = await client.post("/api/v1/auth/demo-login/requester")
    token = login_resp.json()["access_token"]

    # 3. Authenticated request -> 200
    me_resp = await client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert me_resp.status_code == 200
    assert me_resp.json()["email"] == "requester@company.com"

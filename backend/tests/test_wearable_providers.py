"""Smoke test for public wearable providers list."""
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_providers_list():
    r = client.get("/api/v1/wearables/providers")
    assert r.status_code == 200
    data = r.json()
    assert isinstance(data, list)
    ids = {x["id"] for x in data}
    assert "fitbit" in ids
    assert "apple_healthkit" in ids

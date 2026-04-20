import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


class TestHealth:
    def test_health_returns_operational(self):
        r = client.get("/health")
        assert r.status_code == 200
        body = r.json()
        assert body["status"] == "operational"
        assert "timestamp" in body


class TestTelemetry:
    VALID_PAYLOAD = {
        "satellite_id": "SAT-01",
        "timestamp": "2024-01-01T00:00:00Z",
        "altitude_km": 550.0,
        "battery_pct": 85.0,
        "signal_strength_dbm": -70.0,
    }

    def test_accepts_valid_telemetry(self):
        r = client.post("/telemetry", json=self.VALID_PAYLOAD)
        assert r.status_code == 200
        body = r.json()
        assert body["status"] == "accepted"
        assert body["satellite_id"] == "SAT-01"

    def test_low_battery_still_accepted(self):
        payload = {**self.VALID_PAYLOAD, "battery_pct": 5.0}
        r = client.post("/telemetry", json=payload)
        assert r.status_code == 200
        assert r.json()["status"] == "accepted"

    def test_missing_field_rejected(self):
        r = client.post("/telemetry", json={"satellite_id": "SAT-01"})
        assert r.status_code == 422


class TestCommand:
    def test_valid_command_dispatched(self):
        r = client.post("/command", json={
            "satellite_id": "SAT-01",
            "command_type": "SAFE_MODE",
            "parameters": {},
        })
        assert r.status_code == 200
        body = r.json()
        assert body["status"] == "dispatched"
        assert body["command"] == "SAFE_MODE"

    @pytest.mark.parametrize("cmd", ["REBOOT", "ADJUST_ORBIT", "DEPLOY_ANTENNA", "SAFE_MODE"])
    def test_all_allowed_commands_accepted(self, cmd):
        r = client.post("/command", json={
            "satellite_id": "SAT-01",
            "command_type": cmd,
            "parameters": {},
        })
        assert r.status_code == 200

    def test_unknown_command_rejected(self):
        r = client.post("/command", json={
            "satellite_id": "SAT-01",
            "command_type": "SELF_DESTRUCT",
            "parameters": {},
        })
        assert r.status_code == 400

    def test_missing_command_type_rejected(self):
        r = client.post("/command", json={"satellite_id": "SAT-01"})
        assert r.status_code == 422

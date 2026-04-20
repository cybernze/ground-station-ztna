from fastapi import FastAPI, HTTPException, Request
from pydantic import BaseModel
from datetime import datetime, timezone
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("ground-station")

app = FastAPI(
    title="Ground Station Control API",
    description="Simulated telecommand reception endpoint — Zero Trust demo",
    version="1.0.0"
)


class TelemetryData(BaseModel):
    satellite_id: str
    timestamp: str
    altitude_km: float
    battery_pct: float
    signal_strength_dbm: float


class Command(BaseModel):
    satellite_id: str
    command_type: str
    parameters: dict = {}


@app.get("/health")
def health_check():
    return {"status": "operational", "timestamp": datetime.now(timezone.utc).isoformat()}


@app.post("/telemetry")
def receive_telemetry(data: TelemetryData, request: Request):
    logger.info(f"[TELEMETRY] Received from satellite {data.satellite_id} | "
                f"Alt: {data.altitude_km}km | Battery: {data.battery_pct}%")

    if data.battery_pct < 10.0:
        logger.warning(f"[ALERT] Low battery on {data.satellite_id}: {data.battery_pct}%")

    return {
        "status": "accepted",
        "satellite_id": data.satellite_id,
        "received_at": datetime.now(timezone.utc).isoformat(),
        "message": "Telemetry logged successfully"
    }


@app.post("/command")
def send_command(cmd: Command, request: Request):
    ALLOWED_COMMANDS = {"REBOOT", "ADJUST_ORBIT", "DEPLOY_ANTENNA", "SAFE_MODE"}

    if cmd.command_type not in ALLOWED_COMMANDS:
        logger.warning(f"[REJECTED] Unknown command: {cmd.command_type}")
        raise HTTPException(status_code=400, detail=f"Command '{cmd.command_type}' not authorized")

    logger.info(f"[COMMAND] Dispatching {cmd.command_type} to {cmd.satellite_id} | "
                f"Params: {cmd.parameters}")

    return {
        "status": "dispatched",
        "satellite_id": cmd.satellite_id,
        "command": cmd.command_type,
        "dispatched_at": datetime.now(timezone.utc).isoformat(),
        "message": f"Command {cmd.command_type} queued for uplink"
    }

import os
import sys
import json
import uuid
import logging
from datetime import datetime, timedelta, timezone
from typing import List, Optional, Dict, Any

from fastapi import FastAPI, HTTPException, Request, Response, Query, Header
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr
from passlib.context import CryptContext
from jose import jwt

# Setup logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
logger = logging.getLogger("oniq-server")

app = FastAPI(
    title="OniQ Unified Local Backend",
    version="1.0.0",
    description="Unified local backend serving Auth, OniQ Storage Monitoring, and mock AI services for OniQ mobile application.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuration & Persistent JSON storage
DATA_DIR = os.path.dirname(os.path.abspath(__file__))
DB_FILE = os.path.join(DATA_DIR, "oniq_local_db.json")
JWT_SECRET = "oniq-jwt-secret-key-2026"
JWT_ALGORITHM = "HS256"
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# In-memory + persistent cache
_db_data: Dict[str, Any] = {
    "users": {},
    "batches": {},
    "telemetry": {},
    "alerts": []
}


def _load_db():
    global _db_data
    if os.path.exists(DB_FILE):
        try:
            with open(DB_FILE, "r", encoding="utf-8") as f:
                _db_data = json.load(f)
            logger.info(f"Loaded database from {DB_FILE} ({len(_db_data.get('users', {}))} users, {len(_db_data.get('batches', {}))} batches)")
        except Exception as e:
            logger.error(f"Error loading {DB_FILE}: {e}")


def _save_db():
    try:
        with open(DB_FILE, "w", encoding="utf-8") as f:
            json.dump(_db_data, f, indent=2, ensure_ascii=False)
    except Exception as e:
        logger.error(f"Error saving {DB_FILE}: {e}")


_load_db()


def create_token(data: dict) -> str:
    to_encode = data.copy()
    to_encode["exp"] = datetime.now(timezone.utc) + timedelta(days=30)
    return jwt.encode(to_encode, JWT_SECRET, algorithm=JWT_ALGORITHM)


# ── Health ──────────────────────────────────────────────────────────────────

@app.get("/health")
@app.get("/api/v1/health")
async def health():
    return {
        "status": "ok",
        "service": "oniq-unified-server",
        "version": "1.0.0",
        "users_count": len(_db_data.get("users", {})),
        "batches_count": len(_db_data.get("batches", {})),
    }


# ── Auth Models & Endpoints ─────────────────────────────────────────────────

class RegisterRequest(BaseModel):
    name: str
    email: str
    phone: str
    password: str
    user_type: str = "Farmer"
    username: str
    language_preference: str = "en"


class LoginRequest(BaseModel):
    email: str
    password: str
    user_type: str = "Farmer"


class ChangePasswordRequest(BaseModel):
    email: str
    old_password: str
    new_password: str


class ResetPasswordRequest(BaseModel):
    email: str
    code: str
    new_password: str


@app.post("/api/v1/auth/register")
@app.post("/register")
async def register(req: RegisterRequest):
    email_key = req.email.lower().strip()
    users = _db_data["users"]

    if email_key in users:
        raise HTTPException(status_code=400, detail="Email already registered")

    for u in users.values():
        if u.get("username", "").lower() == req.username.lower():
            raise HTTPException(status_code=400, detail="Username already taken")

    user_doc = {
        "name": req.name.strip(),
        "email": email_key,
        "phone": req.phone.strip(),
        "password": pwd_context.hash(req.password),
        "user_type": req.user_type,
        "username": req.username.strip(),
        "language_preference": req.language_preference,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "is_active": True,
    }
    users[email_key] = user_doc
    _save_db()
    logger.info(f"Registered new user: {email_key} ({req.name}) as {req.user_type}")

    return {
        "success": True,
        "message": "Account successfully created.",
    }


@app.post("/api/v1/auth/login")
@app.post("/login")
async def login(req: LoginRequest):
    email_key = req.email.lower().strip()
    users = _db_data["users"]

    user = users.get(email_key)
    if not user:
        raise HTTPException(status_code=401, detail="No account found. Please create an account.")

    if not user.get("is_active", True):
        raise HTTPException(status_code=403, detail="Your account has been deactivated")

    # Match user type if provided
    if req.user_type and user.get("user_type") != req.user_type:
        raise HTTPException(
            status_code=401,
            detail=f"This email is registered as {user.get('user_type')}, not {req.user_type}."
        )

    if not pwd_context.verify(req.password, user["password"]):
        raise HTTPException(status_code=401, detail="Invalid password")

    token = create_token({
        "email": user["email"],
        "user_type": user["user_type"],
        "name": user["name"],
    })

    logger.info(f"User logged in: {email_key}")
    return {
        "success": True,
        "token": token,
        "user": {
            "name": user["name"],
            "email": user["email"],
            "phone": user["phone"],
            "user_type": user["user_type"],
            "username": user["username"],
            "language_preference": user.get("language_preference", "en"),
        },
    }


@app.get("/api/v1/auth/profile/{email}")
@app.get("/profile/{email}")
async def get_profile(email: str):
    email_key = email.lower().strip()
    user = _db_data["users"].get(email_key)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    return {
        "success": True,
        "user": {
            "name": user["name"],
            "email": user["email"],
            "phone": user["phone"],
            "user_type": user["user_type"],
            "username": user["username"],
            "language_preference": user.get("language_preference", "en"),
            "created_at": user.get("created_at"),
        },
    }


@app.get("/api/v1/auth/users")
@app.get("/users")
async def list_users():
    sanitized = [
        {k: v for k, v in u.items() if k != "password"}
        for u in _db_data["users"].values()
    ]
    return {"success": True, "users": sanitized}


@app.post("/api/v1/auth/users/{email}/toggle-status")
async def toggle_user_status(email: str):
    email_key = email.lower().strip()
    user = _db_data["users"].get(email_key)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user["is_active"] = not user.get("is_active", True)
    _save_db()
    return {"success": True, "is_active": user["is_active"], "message": f"User status changed"}


@app.post("/api/v1/auth/change-password")
async def change_password(req: ChangePasswordRequest):
    email_key = req.email.lower().strip()
    user = _db_data["users"].get(email_key)
    if not user:
        raise HTTPException(status_code=404, detail="No account found with this email")
    if not pwd_context.verify(req.old_password, user["password"]):
        raise HTTPException(status_code=401, detail="Old password is incorrect")
    user["password"] = pwd_context.hash(req.new_password)
    _save_db()
    return {"success": True, "message": "Password changed successfully."}


@app.post("/api/v1/auth/forgot-password/{email}")
async def forgot_password(email: str):
    return {"success": True, "message": "Verification code has been sent."}


@app.post("/api/v1/auth/reset-password")
async def reset_password(req: ResetPasswordRequest):
    email_key = req.email.lower().strip()
    user = _db_data["users"].get(email_key)
    if not user:
        raise HTTPException(status_code=404, detail="No account found")
    user["password"] = pwd_context.hash(req.new_password)
    _save_db()
    return {"success": True, "message": "Password successfully reset."}


# ── OniQ Storage Monitoring & AI Decision Support ────────────────────────────

# Import rules engine & models from storage-service
sys.path.insert(0, os.path.join(DATA_DIR, "storage-service"))
try:
    from app.rules_engine import evaluate_sensor_telemetry
    from app.advisor import generate_storage_advisory
    from app.models import (
        StorageBatchCreate,
        StorageBatchResponse,
        SensorReading,
        TelemetryBatch,
        RiskAssessment,
        StorageAdvisoryResponse,
    )
except Exception as e:
    logger.warning(f"Could not import storage-service models directly ({e}). Using inline logic.")
    evaluate_sensor_telemetry = None


class BatchCreateInput(BaseModel):
    user_email: str
    name: str
    structure_type: str = "Traditional Chawl (Naturally Ventilated)"
    variety: str = "Garwa (Rabi)"
    quantity_quintals: float = 50.0
    start_date: Optional[str] = None
    location: str = "Nashik, Maharashtra"
    device_id: str = "esp32-node-01"
    notes: Optional[str] = ""


def _generate_synthetic_telemetry(device_id: str, batch_id: str) -> List[Dict[str, Any]]:
    import random
    import math

    readings = []
    now = datetime.now(timezone.utc)

    # Generate 24 hourly readings showing realistic diurnal cycle in Indian chawl
    for i in range(24, 0, -1):
        dt = now - timedelta(hours=i)
        hour = dt.hour
        # Diurnal temperature curve: low at 5 AM (~23°C), peak at 3 PM (~31°C)
        temp_cycle = 27.0 + 4.0 * math.sin((hour - 9) * math.pi / 12) + random.uniform(-0.4, 0.4)
        # Relative humidity inverse of temp: high at dawn (~72%), low in afternoon (~58%)
        rh_cycle = 65.0 - 7.0 * math.sin((hour - 9) * math.pi / 12) + random.uniform(-1.0, 1.0)
        # MQ-135 normal baseline (550-700)
        mq135 = 620.0 + random.uniform(-30, 40)
        # MQ-136 normal safe level (300-420)
        mq136 = 360.0 + random.uniform(-20, 30)

        readings.append({
            "device_id": device_id,
            "batch_id": batch_id,
            "timestamp": dt.isoformat(),
            "temperature": round(temp_cycle, 1),
            "humidity": round(rh_cycle, 1),
            "mq135_raw": round(mq135, 0),
            "mq135_ppm": round(mq135 * 0.05, 1),
            "mq136_raw": round(mq136, 0),
            "mq136_ppm": round(mq136 * 0.02, 2),
            "battery_pct": 94.0,
            "rssi": -65,
        })
    return readings


@app.post("/api/v1/storage/batches")
@app.post("/batches")
async def create_storage_batch(batch_in: BatchCreateInput):
    batch_id = str(uuid.uuid4())[:8]
    now_iso = datetime.now(timezone.utc).isoformat()

    synth_history = _generate_synthetic_telemetry(batch_in.device_id, batch_id)
    latest_reading = synth_history[-1]

    if evaluate_sensor_telemetry:
        risk = evaluate_sensor_telemetry(latest_reading).model_dump()
    else:
        risk = {
            "risk_score": 18.5,
            "risk_level": "Low",
            "status_color": "green",
            "temperature_status": f"Optimal ({latest_reading['temperature']}°C)",
            "humidity_status": f"Optimal ({latest_reading['humidity']}% RH)",
            "air_quality_status": "Good / Normal Baseline",
            "sulfur_gas_status": "Safe / Undetected",
            "primary_concern": "Optimal storage environment. Regular ventilation maintained.",
            "recommendations": ["Maintain continuous cross-ventilation through bottom and side louvers."],
            "evaluated_at": now_iso,
        }

    doc = {
        "id": batch_id,
        "user_email": batch_in.user_email.lower().strip(),
        "name": batch_in.name,
        "structure_type": batch_in.structure_type,
        "variety": batch_in.variety,
        "quantity_quintals": batch_in.quantity_quintals,
        "start_date": batch_in.start_date or now_iso[:10],
        "location": batch_in.location,
        "device_id": batch_in.device_id,
        "notes": batch_in.notes or "",
        "is_active": True,
        "created_at": now_iso,
        "latest_reading": latest_reading,
        "latest_risk": risk,
    }

    _db_data["batches"][batch_id] = doc
    _db_data["telemetry"][batch_id] = synth_history
    _save_db()

    logger.info(f"Created OniQ batch: {batch_id} - '{batch_in.name}' for {batch_in.user_email}")
    return doc


@app.get("/api/v1/storage/batches")
@app.get("/batches")
async def list_storage_batches(user_email: Optional[str] = Query(None)):
    email_key = user_email.lower().strip() if user_email else None
    results = []
    for b in _db_data["batches"].values():
        if email_key and b.get("user_email") != email_key:
            continue
        results.append(b)
    # Sort newest first
    results.sort(key=lambda x: x.get("created_at", ""), reverse=True)
    return results


@app.get("/api/v1/storage/batches/{batch_id}")
@app.get("/batches/{batch_id}")
async def get_storage_batch(batch_id: str):
    b = _db_data["batches"].get(batch_id)
    if not b:
        raise HTTPException(status_code=404, detail="Batch not found")
    return b


@app.get("/api/v1/storage/batches/{batch_id}/current")
async def get_storage_batch_current(batch_id: str):
    batch = _db_data["batches"].get(batch_id)
    if not batch:
        raise HTTPException(status_code=404, detail="Batch not found")

    history = _db_data["telemetry"].get(batch_id, [])
    if not history:
        history = _generate_synthetic_telemetry(batch["device_id"], batch_id)
        _db_data["telemetry"][batch_id] = history
        _save_db()

    latest_reading = history[-1]
    if evaluate_sensor_telemetry:
        risk = evaluate_sensor_telemetry(latest_reading).model_dump()
    else:
        risk = batch.get("latest_risk") or {
            "risk_score": 15.0,
            "risk_level": "Low",
            "status_color": "green",
            "temperature_status": "Optimal",
            "humidity_status": "Optimal",
            "air_quality_status": "Good",
            "sulfur_gas_status": "Safe",
            "primary_concern": "Optimal storage environment",
            "recommendations": ["Maintain current ventilation"],
            "evaluated_at": datetime.now(timezone.utc).isoformat(),
        }

    batch["latest_reading"] = latest_reading
    batch["latest_risk"] = risk

    return {
        "batch": batch,
        "reading": latest_reading,
        "risk": risk,
        "risk_assessment": risk,
    }


@app.get("/api/v1/storage/batches/{batch_id}/history")
async def get_storage_batch_history(batch_id: str, limit: int = Query(50)):
    history = _db_data["telemetry"].get(batch_id, [])
    if not history:
        batch = _db_data["batches"].get(batch_id)
        dev_id = batch["device_id"] if batch else "esp32-node-01"
        history = _generate_synthetic_telemetry(dev_id, batch_id)
        _db_data["telemetry"][batch_id] = history
        _save_db()
    slice_data = history[-limit:]
    return {"readings": slice_data, "count": len(slice_data)}



@app.get("/api/v1/storage/batches/{batch_id}/advisory")
async def get_storage_batch_advisory(batch_id: str):
    batch = _db_data["batches"].get(batch_id)
    if not batch:
        raise HTTPException(status_code=404, detail="Batch not found")

    history = _db_data["telemetry"].get(batch_id, [])
    latest_reading = history[-1] if history else {
        "temperature": 27.5, "humidity": 66.0, "mq135_raw": 610.0, "mq136_raw": 340.0
    }

    if evaluate_sensor_telemetry:
        risk = evaluate_sensor_telemetry(latest_reading).model_dump()
    else:
        risk = {"risk_score": 16.0, "risk_level": "Low", "status_color": "green", "primary_concern": "Optimal"}

    now_iso = datetime.now(timezone.utc).isoformat()
    return {
        "batch_id": batch_id,
        "batch_name": batch["name"],
        "variety": batch["variety"],
        "structure_type": batch["structure_type"],
        "summary": (
            f"Storage conditions in {batch['name']} are currently {risk['risk_level'].upper()} risk. "
            f"Temperature is {latest_reading.get('temperature', 27)}°C and Relative Humidity is {latest_reading.get('humidity', 65)}%. "
            "Natural bulb dormancy is preserved with zero detectable rot gases."
        ),
        "recommended_actions": [
            "Ensure bottom and side louvers remain open during morning hours for air exchange.",
            "Inspect central stack depth to maintain 4 to 5 feet height limit to prevent heat pockets.",
            "Re-check sensor readings in the afternoon during peak ambient temperature."
        ],
        "estimated_safe_days_remaining": 110,
        "suggested_market_timing": "Bulb quality remains prime. Safe to hold for favorable mandi market rates over next 8-12 weeks.",
        "ai_model_version": "OniQ-Agronomic-Engine-v1.0 (ICAR-DOGR calibrated)",
        "generated_at": now_iso,
    }


@app.post("/api/v1/storage/telemetry")
async def ingest_storage_telemetry(batch_data: Dict[str, Any]):
    """Receives IoT telemetry batches from ESP32 or Raspberry Pi gateway."""
    device_id = batch_data.get("device_id", "unknown")
    readings = batch_data.get("readings", [])
    logger.info(f"Ingested {len(readings)} readings from device '{device_id}'")

    for b_id, b in _db_data["batches"].items():
        if b.get("device_id") == device_id:
            if b_id not in _db_data["telemetry"]:
                _db_data["telemetry"][b_id] = []
            _db_data["telemetry"][b_id].extend(readings)
            if readings:
                latest = readings[-1]
                b["latest_reading"] = latest
                if evaluate_sensor_telemetry:
                    b["latest_risk"] = evaluate_sensor_telemetry(latest).model_dump()
            _save_db()

    return {"success": True, "count": len(readings), "message": "Telemetry processed"}


@app.get("/api/v1/storage/alerts/{email}")
async def get_storage_alerts(email: str):
    return {"alerts": []}


# ── Diagnosis / Treatment / Analytics / LLM Mock fallbacks ──────────────────

@app.post("/api/v1/diagnosis/save")
async def save_diagnosis(req: Request):
    return {"success": True, "message": "Diagnosis saved"}


@app.post("/api/v1/analytics/log")
async def log_analytics(req: Request):
    return {"success": True, "message": "Analytics logged"}


@app.get("/api/v1/diagnosis/history/{email}")
async def diagnosis_history(email: str):
    return {"success": True, "history": []}


@app.get("/api/v1/analytics/summary/{email}")
async def analytics_summary(email: str):
    return {"total_scans": 0, "healthy_count": 0, "disease_count": 0}


@app.get("/api/v1/analytics/timeseries/{email}")
async def analytics_timeseries(email: str, days: int = 30):
    return {"data": []}



@app.post("/api/v1/feedback")
async def feedback(req: Request):
    return {"success": True, "message": "Thank you for your feedback!"}



if __name__ == "__main__":
    import uvicorn
    logger.info("Starting OniQ Unified Backend Server on 0.0.0.0:8000...")
    uvicorn.run(app, host="0.0.0.0", port=8000)

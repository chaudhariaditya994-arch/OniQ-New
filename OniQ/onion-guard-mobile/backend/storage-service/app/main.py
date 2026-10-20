import os
import uuid
import logging
from datetime import datetime, timezone
from typing import List, Optional, Dict, Any
from fastapi import FastAPI, HTTPException, Header, Query
from fastapi.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient

from app.models import (
    StorageBatchCreate,
    StorageBatchResponse,
    SensorReading,
    TelemetryBatch,
    RiskAssessment,
    StorageAlert,
    StorageAdvisoryResponse,
)
from app.rules_engine import evaluate_sensor_telemetry
from app.advisor import generate_storage_advisory

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("oniq-storage-service")

app = FastAPI(
    title="OniQ Storage Monitoring & Decision-Support Service",
    version="1.0.0",
    description="Backend microservice for IoT sensor telemetry, agronomic risk calculation, and storage advice.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

MONGODB_URI = os.getenv("MONGODB_URI", "mongodb://localhost:27017")
DATABASE_NAME = os.getenv("DATABASE_NAME", "oniq_storage")
GATEWAY_API_KEY = os.getenv("GATEWAY_API_KEY", "oniq-gateway-secret-key")

# Database client setup
_mongo_client: Optional[AsyncIOMotorClient] = None
_db = None
_use_memory_fallback = False

# In-memory store for instant local testing when MongoDB is not running
_mem_batches: Dict[str, Dict[str, Any]] = {}
_mem_telemetry: List[Dict[str, Any]] = []
_mem_alerts: List[Dict[str, Any]] = []


def get_db():
    global _mongo_client, _db, _use_memory_fallback
    if _db is not None or _use_memory_fallback:
        return _db
    try:
        _mongo_client = AsyncIOMotorClient(MONGODB_URI, serverSelectionTimeoutMS=2000)
        _db = _mongo_client[DATABASE_NAME]
        logger.info(f"Connected to MongoDB at {MONGODB_URI} (db: {DATABASE_NAME})")
    except Exception as e:
        logger.warning(f"MongoDB not reachable ({e}). Falling back to in-memory store for testing.")
        _use_memory_fallback = True
        _db = None
    return _db


@app.get("/health")
async def health():
    db = get_db()
    status = "connected" if db is not None else "in-memory-fallback"
    return {
        "status": "ok",
        "service": "oniq-storage-service",
        "database": status,
        "active_batches_count": len(_mem_batches) if _use_memory_fallback else None,
    }


# ── Storage Batch Management ──────────────────────────────────────────────────

@app.post("/batches", response_model=StorageBatchResponse)
async def create_batch(batch_in: StorageBatchCreate):
    db = get_db()
    batch_id = str(uuid.uuid4())[:8]
    now_iso = datetime.now(timezone.utc).isoformat()

    doc = {
        "id": batch_id,
        "_id": batch_id,
        "user_email": batch_in.user_email.lower(),
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
        "latest_reading": None,
        "latest_risk": None,
    }

    if db is not None:
        try:
            await db["batches"].insert_one(doc)
        except Exception:
            _mem_batches[batch_id] = doc
    else:
        _mem_batches[batch_id] = doc

    return StorageBatchResponse(**doc)


@app.get("/batches", response_model=List[StorageBatchResponse])
async def list_batches(user_email: Optional[str] = Query(None)):
    db = get_db()
    results = []
    if db is not None:
        try:
            query = {}
            if user_email:
                query["user_email"] = user_email.lower()
            cursor = db["batches"].find(query).sort("created_at", -1)
            raw = await cursor.to_list(length=100)
            for r in raw:
                r["id"] = str(r.get("id", r.get("_id")))
                results.append(StorageBatchResponse(**r))
            return results
        except Exception:
            pass

    # In-memory fallback
    for b in _mem_batches.values():
        if user_email and b["user_email"] != user_email.lower():
            continue
        results.append(StorageBatchResponse(**b))
    return results


@app.get("/batches/{batch_id}", response_model=StorageBatchResponse)
async def get_batch(batch_id: str):
    db = get_db()
    if db is not None:
        try:
            doc = await db["batches"].find_one({"$or": [{"id": batch_id}, {"_id": batch_id}]})
            if doc:
                doc["id"] = str(doc.get("id", doc.get("_id")))
                return StorageBatchResponse(**doc)
        except Exception:
            pass

    if batch_id in _mem_batches:
        return StorageBatchResponse(**_mem_batches[batch_id])

    raise HTTPException(status_code=404, detail=f"Storage batch '{batch_id}' not found")


@app.delete("/batches/{batch_id}")
async def delete_batch(batch_id: str):
    db = get_db()
    if db is not None:
        try:
            res = await db["batches"].delete_one({"$or": [{"id": batch_id}, {"_id": batch_id}]})
            if res.deleted_count > 0:
                return {"success": True, "message": f"Batch '{batch_id}' removed"}
        except Exception:
            pass

    if batch_id in _mem_batches:
        del _mem_batches[batch_id]
        return {"success": True, "message": f"Batch '{batch_id}' removed"}

    raise HTTPException(status_code=404, detail="Batch not found")


# ── Telemetry Ingestion API ───────────────────────────────────────────────────

@app.post("/telemetry")
async def ingest_telemetry(payload: Dict[str, Any], x_gateway_key: Optional[str] = Header(None)):
    # Support both single reading and batch ingestion
    readings_to_process: List[Dict[str, Any]] = []

    if "readings" in payload and isinstance(payload["readings"], list):
        for r in payload["readings"]:
            readings_to_process.append(r)
    else:
        readings_to_process.append(payload)

    db = get_db()
    processed_count = 0
    latest_risk_result = None

    for item in readings_to_process:
        device_id = str(item.get("device_id", "default-node"))
        explicit_batch_id = item.get("batch_id")
        now_iso = item.get("timestamp") or datetime.now(timezone.utc).isoformat()

        # Find matching batch
        target_batch = None
        if explicit_batch_id:
            if db is not None:
                try:
                    target_batch = await db["batches"].find_one({"$or": [{"id": explicit_batch_id}, {"_id": explicit_batch_id}]})
                except Exception:
                    pass
            if not target_batch and explicit_batch_id in _mem_batches:
                target_batch = _mem_batches[explicit_batch_id]
        else:
            # Look up by device_id
            if db is not None:
                try:
                    target_batch = await db["batches"].find_one({"device_id": device_id, "is_active": True})
                except Exception:
                    pass
            if not target_batch:
                for b in _mem_batches.values():
                    if b.get("device_id") == device_id and b.get("is_active"):
                        target_batch = b
                        break

        batch_id = str(target_batch.get("id", target_batch.get("_id"))) if target_batch else "unassigned"
        batch_name = str(target_batch.get("name", "Unassigned Lot")) if target_batch else "Unassigned Lot"
        user_email = str(target_batch.get("user_email", "admin@oniq.io")) if target_batch else "admin@oniq.io"

        # Calculate agronomic risk
        risk = evaluate_sensor_telemetry(item)
        latest_risk_result = risk.model_dump()

        record = {
            "device_id": device_id,
            "batch_id": batch_id,
            "timestamp": now_iso,
            "temperature": float(item.get("temperature", 28.0)),
            "humidity": float(item.get("humidity", 65.0)),
            "mq135_raw": float(item.get("mq135_raw", 600.0)),
            "mq135_ppm": item.get("mq135_ppm"),
            "mq136_raw": float(item.get("mq136_raw", 350.0)),
            "mq136_ppm": item.get("mq136_ppm"),
            "battery_pct": item.get("battery_pct"),
            "rssi": item.get("rssi"),
            "risk_score": risk.risk_score,
            "risk_level": risk.risk_level,
        }

        # Store telemetry
        if db is not None:
            try:
                await db["sensor_telemetry"].insert_one(record)
                if target_batch:
                    await db["batches"].update_one(
                        {"$or": [{"id": batch_id}, {"_id": batch_id}]},
                        {"$set": {"latest_reading": record, "latest_risk": latest_risk_result}}
                    )
            except Exception:
                _mem_telemetry.append(record)
        else:
            _mem_telemetry.append(record)
            if target_batch and batch_id in _mem_batches:
                _mem_batches[batch_id]["latest_reading"] = record
                _mem_batches[batch_id]["latest_risk"] = latest_risk_result

        # Auto-create alert if condition is dangerous
        if risk.risk_level in ["High", "Critical"]:
            alert_doc = {
                "id": str(uuid.uuid4())[:8],
                "batch_id": batch_id,
                "batch_name": batch_name,
                "user_email": user_email,
                "severity": "critical" if risk.risk_level == "Critical" else "warning",
                "title": f"Spoilage Alert: {risk.risk_level} Risk in {batch_name}",
                "message": risk.primary_concern,
                "timestamp": now_iso,
                "is_resolved": False,
            }
            if db is not None:
                try:
                    await db["storage_alerts"].insert_one(alert_doc)
                except Exception:
                    _mem_alerts.append(alert_doc)
            else:
                _mem_alerts.append(alert_doc)

        processed_count += 1

    return {
        "success": True,
        "processed_records": processed_count,
        "latest_risk": latest_risk_result,
    }


# ── Batch Telemetry Query & Analytics ─────────────────────────────────────────

@app.get("/batches/{batch_id}/current")
async def get_current_status(batch_id: str):
    batch = await get_batch(batch_id)
    latest = batch.latest_reading
    if not latest:
        # Default nominal reading if no sensor data received yet
        latest = {
            "device_id": batch.device_id,
            "batch_id": batch_id,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "temperature": 27.5,
            "humidity": 66.0,
            "mq135_raw": 650.0,
            "mq136_raw": 380.0,
            "risk_score": 12.0,
            "risk_level": "Low",
        }

    risk = evaluate_sensor_telemetry(latest)

    return {
        "success": True,
        "batch": batch,
        "reading": latest,
        "risk_assessment": risk,
    }


@app.get("/batches/{batch_id}/history")
async def get_batch_history(batch_id: str, limit: int = Query(50, ge=1, le=500)):
    db = get_db()
    readings = []

    if db is not None:
        try:
            cursor = db["sensor_telemetry"].find(
                {"batch_id": batch_id},
                {"_id": 0}
            ).sort("timestamp", -1).limit(limit)
            readings = await cursor.to_list(length=limit)
            readings.reverse()  # Chronological order
            return {"success": True, "batch_id": batch_id, "readings": readings}
        except Exception:
            pass

    # In-memory history
    for r in _mem_telemetry:
        if r.get("batch_id") == batch_id:
            readings.append(r)
    readings = readings[-limit:]

    return {"success": True, "batch_id": batch_id, "readings": readings}


@app.get("/batches/{batch_id}/advisory", response_model=StorageAdvisoryResponse)
async def get_batch_advisory(batch_id: str):
    batch_res = await get_batch(batch_id)
    batch_dict = batch_res.model_dump()
    latest = batch_dict.get("latest_reading") or {
        "temperature": 28.0,
        "humidity": 67.0,
        "mq135_raw": 700.0,
        "mq136_raw": 420.0,
    }
    risk = evaluate_sensor_telemetry(latest)
    advisory = await generate_storage_advisory(batch_dict, latest, risk)
    return advisory


# ── Alerts API ────────────────────────────────────────────────────────────────

@app.get("/alerts/{user_email}")
async def get_user_alerts(user_email: str):
    db = get_db()
    alerts = []
    if db is not None:
        try:
            cursor = db["storage_alerts"].find(
                {"user_email": user_email.lower(), "is_resolved": False},
                {"_id": 0}
            ).sort("timestamp", -1).limit(30)
            alerts = await cursor.to_list(length=30)
            return {"success": True, "alerts": alerts}
        except Exception:
            pass

    for a in _mem_alerts:
        if a.get("user_email") == user_email.lower() and not a.get("is_resolved"):
            alerts.append(a)

    return {"success": True, "alerts": alerts}


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8005))
    uvicorn.run("app.main:app", host="0.0.0.0", port=port, reload=True)

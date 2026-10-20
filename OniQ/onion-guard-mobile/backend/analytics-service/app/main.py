import os
from datetime import datetime, timedelta, timezone
from fastapi import FastAPI, HTTPException
from motor.motor_asyncio import AsyncIOMotorClient
from pydantic import BaseModel
from typing import Optional

app = FastAPI(title="OnionGuard Analytics Service", version="1.0.0")

MONGODB_URI = os.getenv("MONGODB_URI", "mongodb://localhost:27017")
DATABASE_NAME = os.getenv("DATABASE_NAME", "onionguard_analytics")

client = AsyncIOMotorClient(MONGODB_URI)
db = client[DATABASE_NAME]
events_collection = db["diagnosis_events"]


class DiagnosisEvent(BaseModel):
    email: str
    disease: str
    confidence: float
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    region: Optional[str] = None


@app.get("/health")
async def health():
    return {"status": "ok", "service": "analytics-service"}


@app.post("/log")
async def log_event(event: DiagnosisEvent):
    doc = event.model_dump()
    doc["timestamp"] = datetime.now(timezone.utc).isoformat()

    await events_collection.insert_one(doc)
    return {"success": True, "message": "Event logged"}


@app.get("/summary/{email}")
async def get_summary(email: str):
    pipeline = [
        {"$match": {"email": email}},
        {"$group": {
            "_id": "$disease",
            "count": {"$sum": 1},
            "avg_confidence": {"$avg": "$confidence"},
            "last_scan": {"$max": "$timestamp"},
        }},
        {"$sort": {"count": -1}},
    ]
    results = await events_collection.aggregate(pipeline).to_list(length=20)

    total_scans = sum(r["count"] for r in results)
    disease_distribution = {
        r["_id"]: {
            "count": r["count"],
            "avg_confidence": round(r["avg_confidence"], 2),
            "last_scan": r["last_scan"],
        }
        for r in results
    }

    healthy_count = disease_distribution.get("Healthy", {}).get("count", 0)
    disease_count = total_scans - healthy_count

    return {
        "success": True,
        "summary": {
            "total_scans": total_scans,
            "healthy_count": healthy_count,
            "disease_count": disease_count,
            "disease_distribution": disease_distribution,
        },
    }


@app.get("/regional")
async def regional_stats():
    pipeline = [
        {"$match": {"region": {"$ne": None}}},
        {"$group": {
            "_id": {"region": "$region", "disease": "$disease"},
            "count": {"$sum": 1},
        }},
        {"$sort": {"count": -1}},
    ]
    results = await events_collection.aggregate(pipeline).to_list(length=100)

    regional = {}
    for r in results:
        region = r["_id"]["region"]
        disease = r["_id"]["disease"]
        if region not in regional:
            regional[region] = {}
        regional[region][disease] = r["count"]

    return {"success": True, "regional_stats": regional}


@app.get("/recent/{email}")
async def recent_activity(email: str):
    cursor = events_collection.find(
        {"email": email}, {"_id": 0}
    ).sort("timestamp", -1).limit(20)
    events = await cursor.to_list(length=20)
    return {"success": True, "events": events}


@app.get("/summary-all")
async def get_all_summary():
    pipeline = [
        {"$group": {
            "_id": "$disease",
            "count": {"$sum": 1},
            "avg_confidence": {"$avg": "$confidence"},
        }},
        {"$sort": {"count": -1}},
    ]
    results = await events_collection.aggregate(pipeline).to_list(length=20)
    total_scans = sum(r["count"] for r in results)
    disease_distribution = {
        r["_id"]: {"count": r["count"], "avg_confidence": round(r["avg_confidence"], 2)}
        for r in results
    }
    healthy_count = disease_distribution.get("Healthy", {}).get("count", 0)

    # Get unique user count
    unique_users = await events_collection.distinct("email")

    return {
        "success": True,
        "summary": {
            "total_scans": total_scans,
            "total_users": len(unique_users),
            "healthy_count": healthy_count,
            "disease_count": total_scans - healthy_count,
            "disease_distribution": disease_distribution,
        },
    }


@app.get("/all-scans")
async def all_scans():
    cursor = events_collection.find({}, {"_id": 0}).sort("timestamp", -1).limit(100)
    events = await cursor.to_list(length=100)
    return {"success": True, "events": events}


@app.get("/timeseries/{email}")
async def get_timeseries(email: str, days: int = 30):
    """Returns daily scan buckets, weekday pattern, and recent scans for the user.
    Used by the analytics page to render charts. days clamped to [1, 365]."""
    days = max(1, min(365, days))

    cutoff = (datetime.now(timezone.utc) - timedelta(days=days)).isoformat()
    cursor = events_collection.find(
        {"email": email, "timestamp": {"$gte": cutoff}},
        {"_id": 0, "disease": 1, "confidence": 1, "timestamp": 1},
    ).sort("timestamp", -1)
    events = await cursor.to_list(length=None)

    today = datetime.now(timezone.utc).date()
    buckets: dict[str, dict] = {}
    for i in range(days):
        d = today - timedelta(days=days - 1 - i)
        buckets[d.isoformat()] = {
            "date": d.isoformat(),
            "healthy": 0,
            "diseased": 0,
            "total": 0,
        }

    weekday_names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    weekday_counts = {n: 0 for n in weekday_names}

    recent = []
    for ev in events:
        ts_str = ev.get("timestamp", "")
        try:
            ts = datetime.fromisoformat(ts_str.replace("Z", "+00:00"))
        except (ValueError, AttributeError):
            continue

        date_key = ts.date().isoformat()
        is_healthy = ev.get("disease") == "Healthy"

        if date_key in buckets:
            if is_healthy:
                buckets[date_key]["healthy"] += 1
            else:
                buckets[date_key]["diseased"] += 1
            buckets[date_key]["total"] += 1

        weekday_counts[weekday_names[ts.weekday()]] += 1

        if len(recent) < 5:
            recent.append({
                "disease": ev.get("disease"),
                "confidence": ev.get("confidence"),
                "timestamp": ts_str,
            })

    return {
        "success": True,
        "days": days,
        "daily": list(buckets.values()),
        "weekday_pattern": weekday_counts,
        "recent": recent,
    }


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8004))
    uvicorn.run(app, host="0.0.0.0", port=port)

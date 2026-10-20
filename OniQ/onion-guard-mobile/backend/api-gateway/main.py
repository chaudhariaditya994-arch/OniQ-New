import os
import httpx
from fastapi import FastAPI, Request, Response, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
import io

app = FastAPI(title="OnionGuard API Gateway", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

AUTH_URL = os.getenv("AUTH_SERVICE_URL", "http://localhost:8001")
DIAGNOSIS_URL = os.getenv("DIAGNOSIS_SERVICE_URL", "http://localhost:8002")
TREATMENT_URL = os.getenv("TREATMENT_SERVICE_URL", "http://localhost:8003")
ANALYTICS_URL = os.getenv("ANALYTICS_SERVICE_URL", "http://localhost:8004")
STORAGE_URL = os.getenv("STORAGE_SERVICE_URL", "http://localhost:8005")


@app.get("/health")
async def health():
    return {"status": "ok", "service": "api-gateway"}


# ── Auth Service Proxy ───────────────────────────────────────────────────────

@app.post("/api/v1/auth/register")
async def register(request: Request):
    body = await request.json()
    async with httpx.AsyncClient() as client:
        resp = await client.post(f"{AUTH_URL}/register", json=body, timeout=15)
    return Response(content=resp.content, status_code=resp.status_code,
                    media_type="application/json")


@app.post("/api/v1/auth/login")
async def login(request: Request):
    body = await request.json()
    async with httpx.AsyncClient() as client:
        resp = await client.post(f"{AUTH_URL}/login", json=body, timeout=15)
    return Response(content=resp.content, status_code=resp.status_code,
                    media_type="application/json")


@app.get("/api/v1/auth/profile/{email}")
async def get_profile(email: str):
    async with httpx.AsyncClient() as client:
        resp = await client.get(f"{AUTH_URL}/profile/{email}", timeout=10)
    return Response(content=resp.content, status_code=resp.status_code,
                    media_type="application/json")


@app.post("/api/v1/auth/change-password")
async def change_password(request: Request):
    body = await request.json()
    async with httpx.AsyncClient() as client:
        resp = await client.post(f"{AUTH_URL}/change-password", json=body, timeout=15)
    return Response(content=resp.content, status_code=resp.status_code,
                    media_type="application/json")


@app.get("/api/v1/auth/users")
async def list_users():
    async with httpx.AsyncClient() as client:
        resp = await client.get(f"{AUTH_URL}/users", timeout=10)
    return Response(content=resp.content, status_code=resp.status_code,
                    media_type="application/json")


@app.post("/api/v1/auth/users/{email}/toggle-status")
async def toggle_user_status(email: str):
    async with httpx.AsyncClient() as client:
        resp = await client.post(f"{AUTH_URL}/users/{email}/toggle-status", timeout=10)
    return Response(content=resp.content, status_code=resp.status_code,
                    media_type="application/json")


@app.post("/api/v1/auth/forgot-password/{email}")
async def forgot_password(email: str):
    async with httpx.AsyncClient() as client:
        resp = await client.post(f"{AUTH_URL}/forgot-password/{email}", timeout=20)
    return Response(content=resp.content, status_code=resp.status_code,
                    media_type="application/json")


@app.post("/api/v1/auth/reset-password")
async def reset_password(request: Request):
    body = await request.json()
    async with httpx.AsyncClient() as client:
        resp = await client.post(f"{AUTH_URL}/reset-password", json=body, timeout=15)
    return Response(content=resp.content, status_code=resp.status_code,
                    media_type="application/json")


@app.post("/api/v1/feedback")
async def submit_feedback(request: Request):
    body = await request.json()
    async with httpx.AsyncClient() as client:
        resp = await client.post(f"{AUTH_URL}/feedback", json=body, timeout=20)
    return Response(content=resp.content, status_code=resp.status_code,
                    media_type="application/json")


# ── Diagnosis Service Proxy ──────────────────────────────────────────────────

@app.post("/api/v1/diagnosis/predict")
async def predict(file: UploadFile = File(...)):
    file_bytes = await file.read()
    async with httpx.AsyncClient() as client:
        resp = await client.post(
            f"{DIAGNOSIS_URL}/predict",
            files={"file": (file.filename, file_bytes, file.content_type)},
            timeout=30,
        )
    return Response(content=resp.content, status_code=resp.status_code,
                    media_type="application/json")


@app.post("/api/v1/diagnosis/save")
async def save_diagnosis(request: Request):
    body = await request.json()
    async with httpx.AsyncClient() as client:
        resp = await client.post(f"{DIAGNOSIS_URL}/save", json=body, timeout=15)
    return Response(content=resp.content, status_code=resp.status_code,
                    media_type="application/json")


@app.get("/api/v1/diagnosis/history/{email}")
async def diagnosis_history(email: str):
    async with httpx.AsyncClient() as client:
        resp = await client.get(f"{DIAGNOSIS_URL}/history/{email}", timeout=10)
    return Response(content=resp.content, status_code=resp.status_code,
                    media_type="application/json")


# ── LLM Proxy (routes to diagnosis-service so keys stay server-side) ─────────

@app.post("/api/v1/llm/freshness")
async def llm_freshness(file: UploadFile = File(...)):
    file_bytes = await file.read()
    async with httpx.AsyncClient() as client:
        resp = await client.post(
            f"{DIAGNOSIS_URL}/llm/freshness",
            files={"file": (file.filename, file_bytes, file.content_type)},
            timeout=90,
        )
    return Response(content=resp.content, status_code=resp.status_code,
                    media_type="application/json")


@app.post("/api/v1/llm/translate")
async def llm_translate(request: Request):
    body = await request.json()
    async with httpx.AsyncClient() as client:
        resp = await client.post(f"{DIAGNOSIS_URL}/llm/translate", json=body, timeout=60)
    return Response(content=resp.content, status_code=resp.status_code,
                    media_type="application/json")


@app.post("/api/v1/llm/identify-object")
async def llm_identify_object(file: UploadFile = File(...)):
    file_bytes = await file.read()
    async with httpx.AsyncClient() as client:
        resp = await client.post(
            f"{DIAGNOSIS_URL}/llm/identify-object",
            files={"file": (file.filename, file_bytes, file.content_type)},
            timeout=45,
        )
    return Response(content=resp.content, status_code=resp.status_code,
                    media_type="application/json")


# ── Review Proxy (routes to diagnosis-service) ───────────────────────────────

@app.post("/api/v1/reviews")
async def create_review(
    file: UploadFile = File(...),
    user_email: str = Form(...),
    user_role: str = Form(...),
    corrected_label: str = Form(...),
    original_prediction: str = Form(""),
    original_confidence: float = Form(0.0),
    comment: str = Form(""),
):
    file_bytes = await file.read()
    async with httpx.AsyncClient() as client:
        resp = await client.post(
            f"{DIAGNOSIS_URL}/reviews",
            files={"file": (file.filename, file_bytes, file.content_type)},
            data={
                "user_email": user_email,
                "user_role": user_role,
                "corrected_label": corrected_label,
                "original_prediction": original_prediction,
                "original_confidence": str(original_confidence),
                "comment": comment,
            },
            timeout=30,
        )
    return Response(content=resp.content, status_code=resp.status_code,
                    media_type="application/json")


@app.get("/api/v1/reviews")
async def list_all_reviews(requester_role: str = ""):
    async with httpx.AsyncClient() as client:
        resp = await client.get(
            f"{DIAGNOSIS_URL}/reviews",
            params={"requester_role": requester_role},
            timeout=15,
        )
    return Response(content=resp.content, status_code=resp.status_code,
                    media_type="application/json")


@app.get("/api/v1/reviews/by-user/{email}")
async def list_reviews_by_user(email: str):
    async with httpx.AsyncClient() as client:
        resp = await client.get(f"{DIAGNOSIS_URL}/reviews/by-user/{email}", timeout=15)
    return Response(content=resp.content, status_code=resp.status_code,
                    media_type="application/json")


@app.get("/api/v1/reviews/export.zip")
async def export_reviews_zip(requester_role: str = ""):
    async with httpx.AsyncClient(timeout=120) as client:
        resp = await client.get(
            f"{DIAGNOSIS_URL}/reviews/export.zip",
            params={"requester_role": requester_role},
        )
    if resp.status_code != 200:
        return Response(content=resp.content, status_code=resp.status_code,
                        media_type="application/json")
    return Response(
        content=resp.content,
        status_code=200,
        media_type="application/zip",
        headers={
            "Content-Disposition": resp.headers.get(
                "Content-Disposition", 'attachment; filename="reviews-export.zip"'
            ),
        },
    )


@app.get("/api/v1/reviews/{review_id}")
async def get_review(review_id: str, requester_email: str = "", requester_role: str = ""):
    async with httpx.AsyncClient() as client:
        resp = await client.get(
            f"{DIAGNOSIS_URL}/reviews/{review_id}",
            params={"requester_email": requester_email, "requester_role": requester_role},
            timeout=15,
        )
    return Response(content=resp.content, status_code=resp.status_code,
                    media_type="application/json")


@app.patch("/api/v1/reviews/{review_id}")
async def update_review(review_id: str, request: Request):
    body = await request.json()
    async with httpx.AsyncClient() as client:
        resp = await client.patch(f"{DIAGNOSIS_URL}/reviews/{review_id}", json=body, timeout=15)
    return Response(content=resp.content, status_code=resp.status_code,
                    media_type="application/json")


@app.delete("/api/v1/reviews/{review_id}")
async def delete_review(review_id: str, requester_email: str = "", requester_role: str = ""):
    async with httpx.AsyncClient() as client:
        resp = await client.delete(
            f"{DIAGNOSIS_URL}/reviews/{review_id}",
            params={"requester_email": requester_email, "requester_role": requester_role},
            timeout=15,
        )
    return Response(content=resp.content, status_code=resp.status_code,
                    media_type="application/json")


# ── Treatment Service Proxy ──────────────────────────────────────────────────

@app.get("/api/v1/treatment/{disease_name}")
async def get_treatment(disease_name: str):
    async with httpx.AsyncClient() as client:
        resp = await client.get(f"{TREATMENT_URL}/treatment/{disease_name}", timeout=10)
    return Response(content=resp.content, status_code=resp.status_code,
                    media_type="application/json")


@app.get("/api/v1/treatment/{disease_name}/voice/{language}")
async def get_voice(disease_name: str, language: str):
    async with httpx.AsyncClient() as client:
        resp = await client.get(
            f"{TREATMENT_URL}/treatment/{disease_name}/voice/{language}", timeout=30
        )
    if resp.headers.get("content-type", "").startswith("audio"):
        return StreamingResponse(io.BytesIO(resp.content), media_type="audio/mpeg")
    return Response(content=resp.content, status_code=resp.status_code,
                    media_type="application/json")


# ── Analytics Service Proxy ──────────────────────────────────────────────────

@app.post("/api/v1/analytics/log")
async def log_event(request: Request):
    body = await request.json()
    async with httpx.AsyncClient() as client:
        resp = await client.post(f"{ANALYTICS_URL}/log", json=body, timeout=10)
    return Response(content=resp.content, status_code=resp.status_code,
                    media_type="application/json")


@app.get("/api/v1/analytics/summary/{email}")
async def analytics_summary(email: str):
    async with httpx.AsyncClient() as client:
        resp = await client.get(f"{ANALYTICS_URL}/summary/{email}", timeout=10)
    return Response(content=resp.content, status_code=resp.status_code,
                    media_type="application/json")


@app.get("/api/v1/analytics/regional")
async def regional_analytics():
    async with httpx.AsyncClient() as client:
        resp = await client.get(f"{ANALYTICS_URL}/regional", timeout=10)
    return Response(content=resp.content, status_code=resp.status_code,
                    media_type="application/json")


@app.get("/api/v1/analytics/summary-all")
async def all_analytics_summary():
    async with httpx.AsyncClient() as client:
        resp = await client.get(f"{ANALYTICS_URL}/summary-all", timeout=10)
    return Response(content=resp.content, status_code=resp.status_code,
                    media_type="application/json")


@app.get("/api/v1/analytics/all-scans")
async def all_scans():
    async with httpx.AsyncClient() as client:
        resp = await client.get(f"{ANALYTICS_URL}/all-scans", timeout=10)
    return Response(content=resp.content, status_code=resp.status_code,
                    media_type="application/json")


@app.get("/api/v1/analytics/timeseries/{email}")
async def analytics_timeseries(email: str, days: int = 30):
    async with httpx.AsyncClient() as client:
        resp = await client.get(
            f"{ANALYTICS_URL}/timeseries/{email}",
            params={"days": days},
            timeout=15,
        )
    return Response(content=resp.content, status_code=resp.status_code,
                    media_type="application/json")


# ── OniQ Storage Service Proxy ───────────────────────────────────────────────

@app.post("/api/v1/storage/telemetry")
async def ingest_storage_telemetry(request: Request):
    body = await request.json()
    headers = {}
    if "x-gateway-key" in request.headers:
        headers["x-gateway-key"] = request.headers["x-gateway-key"]
    async with httpx.AsyncClient() as client:
        resp = await client.post(f"{STORAGE_URL}/telemetry", json=body, headers=headers, timeout=15)
    return Response(content=resp.content, status_code=resp.status_code, media_type="application/json")


@app.post("/api/v1/storage/batches")
async def create_storage_batch(request: Request):
    body = await request.json()
    async with httpx.AsyncClient() as client:
        resp = await client.post(f"{STORAGE_URL}/batches", json=body, timeout=15)
    return Response(content=resp.content, status_code=resp.status_code, media_type="application/json")


@app.get("/api/v1/storage/batches")
async def list_storage_batches(user_email: str = ""):
    async with httpx.AsyncClient() as client:
        resp = await client.get(f"{STORAGE_URL}/batches", params={"user_email": user_email} if user_email else {}, timeout=15)
    return Response(content=resp.content, status_code=resp.status_code, media_type="application/json")


@app.get("/api/v1/storage/batches/{batch_id}")
async def get_storage_batch(batch_id: str):
    async with httpx.AsyncClient() as client:
        resp = await client.get(f"{STORAGE_URL}/batches/{batch_id}", timeout=15)
    return Response(content=resp.content, status_code=resp.status_code, media_type="application/json")


@app.delete("/api/v1/storage/batches/{batch_id}")
async def delete_storage_batch(batch_id: str):
    async with httpx.AsyncClient() as client:
        resp = await client.delete(f"{STORAGE_URL}/batches/{batch_id}", timeout=15)
    return Response(content=resp.content, status_code=resp.status_code, media_type="application/json")


@app.get("/api/v1/storage/batches/{batch_id}/current")
async def get_storage_current_status(batch_id: str):
    async with httpx.AsyncClient() as client:
        resp = await client.get(f"{STORAGE_URL}/batches/{batch_id}/current", timeout=15)
    return Response(content=resp.content, status_code=resp.status_code, media_type="application/json")


@app.get("/api/v1/storage/batches/{batch_id}/history")
async def get_storage_history(batch_id: str, limit: int = 50):
    async with httpx.AsyncClient() as client:
        resp = await client.get(f"{STORAGE_URL}/batches/{batch_id}/history", params={"limit": limit}, timeout=15)
    return Response(content=resp.content, status_code=resp.status_code, media_type="application/json")


@app.get("/api/v1/storage/batches/{batch_id}/advisory")
async def get_storage_advisory(batch_id: str):
    async with httpx.AsyncClient() as client:
        resp = await client.get(f"{STORAGE_URL}/batches/{batch_id}/advisory", timeout=30)
    return Response(content=resp.content, status_code=resp.status_code, media_type="application/json")


@app.get("/api/v1/storage/alerts/{user_email}")
async def get_storage_alerts(user_email: str):
    async with httpx.AsyncClient() as client:
        resp = await client.get(f"{STORAGE_URL}/alerts/{user_email}", timeout=15)
    return Response(content=resp.content, status_code=resp.status_code, media_type="application/json")

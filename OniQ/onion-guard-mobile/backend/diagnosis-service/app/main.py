import os
import io
import json
import re
import base64
import numpy as np
import httpx
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional
from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from motor.motor_asyncio import AsyncIOMotorClient
from bson import ObjectId
from bson.errors import InvalidId
from pydantic import BaseModel
from PIL import Image

app = FastAPI(title="OnionGuard Diagnosis Service", version="1.0.0")

MONGODB_URI = os.getenv("MONGODB_URI", "mongodb://localhost:27017")
DATABASE_NAME = os.getenv("DATABASE_NAME", "onionguard_diagnosis")
MODEL_PATH = os.getenv("MODEL_PATH", str(Path(__file__).parent.parent / "models" / "onion_model.tflite"))

client = AsyncIOMotorClient(MONGODB_URI)
db = client[DATABASE_NAME]
diagnoses_collection = db["diagnoses"]
reviews_collection = db["reviews"]

CLASS_NAMES = ["Alternaria", "Bulb_Blight", "Caterpillar", "Fusarium", "Healthy", "Virosis"]
IMG_SIZE = 224

# Lazy-load interpreter
_interpreter = None


def get_interpreter():
    global _interpreter
    if _interpreter is None:
        try:
            import tflite_runtime.interpreter as tflite
            _interpreter = tflite.Interpreter(model_path=MODEL_PATH)
        except ImportError:
            import tensorflow as tf
            _interpreter = tf.lite.Interpreter(model_path=MODEL_PATH)
        _interpreter.allocate_tensors()
    return _interpreter


def preprocess_image(image_bytes: bytes) -> np.ndarray:
    img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    img = img.resize((IMG_SIZE, IMG_SIZE))
    img_array = np.array(img, dtype=np.float32)
    img_array = img_array / 127.5 - 1.0  # Normalize to [-1, 1]
    return np.expand_dims(img_array, axis=0)


def predict(image_bytes: bytes) -> dict:
    interpreter = get_interpreter()
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    img_input = preprocess_image(image_bytes)
    interpreter.set_tensor(input_details[0]["index"], img_input)
    interpreter.invoke()
    output = interpreter.get_tensor(output_details[0]["index"])

    pred_idx = int(np.argmax(output[0]))
    confidence = float(output[0][pred_idx])

    return {
        "class_name": CLASS_NAMES[pred_idx],
        "confidence": round(confidence * 100, 2),
        "all_predictions": {
            name: round(float(output[0][i]) * 100, 2)
            for i, name in enumerate(CLASS_NAMES)
        },
    }


async def read_image_upload(file: UploadFile) -> bytes:
    """Read an UploadFile and verify the bytes are actually an image.

    Accepts the upload if EITHER:
      - the declared content-type starts with `image/`, OR
      - PIL can decode the bytes as an image (covers clients that upload as
        `application/octet-stream` because they didn't set the multipart
        content-type — e.g. Flutter `MultipartFile.fromPath` defaults).

    Raises HTTPException(400) if both checks fail.
    """
    image_bytes = await file.read()
    if file.content_type and file.content_type.startswith("image/"):
        return image_bytes
    try:
        Image.open(io.BytesIO(image_bytes)).verify()
        return image_bytes
    except Exception:
        raise HTTPException(status_code=400, detail="File must be an image")


@app.get("/health")
async def health():
    return {"status": "ok", "service": "diagnosis-service"}


@app.post("/predict")
async def predict_disease(file: UploadFile = File(...)):
    image_bytes = await read_image_upload(file)

    try:
        result = predict(image_bytes)
    except FileNotFoundError:
        raise HTTPException(
            status_code=503,
            detail="Model file not found. Place onion_model.tflite in the models/ directory."
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")

    return {"success": True, **result}


@app.post("/predict-and-save")
async def predict_and_save(file: UploadFile = File(...), email: str = ""):
    image_bytes = await read_image_upload(file)
    result = predict(image_bytes)

    diagnosis_doc = {
        "email": email,
        "disease": result["class_name"],
        "confidence": result["confidence"],
        "all_predictions": result["all_predictions"],
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
    await diagnoses_collection.insert_one(diagnosis_doc)

    return {"success": True, **result}


class SaveDiagnosisRequest(BaseModel):
    email: str
    disease: str
    confidence: float
    all_predictions: dict = {}


@app.post("/save")
async def save_diagnosis(req: SaveDiagnosisRequest):
    doc = {
        "email": req.email,
        "disease": req.disease,
        "confidence": req.confidence,
        "all_predictions": req.all_predictions,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
    await diagnoses_collection.insert_one(doc)
    return {"success": True, "message": "Diagnosis saved"}


@app.get("/history/{email}")
async def get_history(email: str):
    cursor = diagnoses_collection.find(
        {"email": email},
        {"_id": 0}
    ).sort("timestamp", -1).limit(50)

    history = await cursor.to_list(length=50)
    return {"success": True, "history": history}


# ── LLM Proxy (keys never leave the server) ─────────────────────────────────

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY", "")
OPENROUTER_BASE_URL = os.getenv("OPENROUTER_BASE_URL", "https://openrouter.ai/api/v1")
DEFAULT_LLM_MODEL = os.getenv("DEFAULT_LLM_MODEL", "anthropic/claude-3-haiku")

FRESHNESS_PROMPT = (
    'Analyze this onion image and determine its freshness level. '
    'Respond ONLY in this exact JSON format, nothing else: '
    '{"freshness": "Fresh" or "Almost Spoilt" or "Rotten", '
    '"confidence": 0-100, '
    '"description": "brief explanation of visual signs", '
    '"tips": "storage or usage recommendation"}'
)

LANG_NAMES = {
    "en": "English",
    "tw": "Twi (Akan)",
    "dg": "Dagbani",
    "ee": "Ewe",
    "ha": "Hausa",
    "ku": "Kusaal",
    "gu": "Gurene (Frafra)",
    "mp": "Mampruli",
    "fr": "French",
}


def _parse_gemini_json(candidates: list) -> dict:
    if not candidates:
        raise HTTPException(status_code=502, detail="Empty Gemini response")
    parts = candidates[0].get("content", {}).get("parts", [])
    full_text = "".join(p.get("text", "") for p in parts if isinstance(p, dict))
    full_text = re.sub(r"```json\s*", "", full_text)
    full_text = re.sub(r"```\s*", "", full_text).strip()
    try:
        return json.loads(full_text)
    except json.JSONDecodeError:
        match = re.search(r"\{[\s\S]*\}", full_text)
        if not match:
            raise HTTPException(status_code=502, detail="Could not parse Gemini response")
        return json.loads(match.group(0))


@app.post("/llm/freshness")
async def llm_freshness(file: UploadFile = File(...)):
    if not GEMINI_API_KEY:
        raise HTTPException(status_code=503, detail="Gemini API key not configured")
    image_bytes = await read_image_upload(file)
    mime_type = "image/png" if (file.filename or "").lower().endswith(".png") else "image/jpeg"
    b64 = base64.b64encode(image_bytes).decode("ascii")

    url = (
        "https://generativelanguage.googleapis.com/v1beta/models/"
        f"gemini-2.5-flash:generateContent?key={GEMINI_API_KEY}"
    )
    payload = {
        "contents": [
            {
                "parts": [
                    {"text": FRESHNESS_PROMPT},
                    {"inline_data": {"mime_type": mime_type, "data": b64}},
                ]
            }
        ],
        "generationConfig": {
            "maxOutputTokens": 1024,
            "responseMimeType": "application/json",
        },
    }

    async with httpx.AsyncClient(timeout=60) as client:
        resp = await client.post(url, json=payload)

    if resp.status_code != 200:
        raise HTTPException(status_code=502, detail=f"Gemini API failed: {resp.status_code}")

    return _parse_gemini_json(resp.json().get("candidates", []))


IDENTIFY_PROMPT = (
    "Look at this image and identify the primary object. "
    "Respond ONLY in this exact JSON format, nothing else: "
    '{"detected_object": "common name of the object '
    "(e.g. 'Onion', 'Red onion', 'Tomato', 'Garlic bulb', 'Hand', 'Plant leaf')"
    '", "is_onion": true if the primary object is clearly an onion bulb or onion plant else false, '
    '"confidence": 0-100}'
)


@app.post("/llm/identify-object")
async def llm_identify_object(file: UploadFile = File(...)):
    """Pre-check used by the app before sending images to disease/freshness scans.
    Returns: {detected_object, is_onion, confidence}"""
    if not GEMINI_API_KEY:
        raise HTTPException(status_code=503, detail="Gemini API key not configured")
    image_bytes = await read_image_upload(file)
    mime_type = "image/png" if (file.filename or "").lower().endswith(".png") else "image/jpeg"
    b64 = base64.b64encode(image_bytes).decode("ascii")

    url = (
        "https://generativelanguage.googleapis.com/v1beta/models/"
        f"gemini-2.5-flash:generateContent?key={GEMINI_API_KEY}"
    )
    payload = {
        "contents": [{"parts": [
            {"text": IDENTIFY_PROMPT},
            {"inline_data": {"mime_type": mime_type, "data": b64}},
        ]}],
        "generationConfig": {
            "maxOutputTokens": 256,
            "responseMimeType": "application/json",
        },
    }

    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(url, json=payload)

    if resp.status_code != 200:
        raise HTTPException(status_code=502, detail=f"Gemini API failed: {resp.status_code}")

    return _parse_gemini_json(resp.json().get("candidates", []))


class TranslateRequest(BaseModel):
    text: str
    target_language: str


@app.post("/llm/translate")
async def llm_translate(req: TranslateRequest):
    if req.target_language == "en":
        return {"translated_text": req.text}
    if not OPENROUTER_API_KEY:
        raise HTTPException(status_code=503, detail="OpenRouter API key not configured")

    lang_name = LANG_NAMES.get(req.target_language, "English")
    payload = {
        "model": DEFAULT_LLM_MODEL,
        "messages": [
            {
                "role": "user",
                "content": (
                    f"Translate the following text to {lang_name}. "
                    f"Return ONLY the translated text, nothing else:\n\n{req.text}"
                ),
            }
        ],
        "max_tokens": 1000,
    }

    async with httpx.AsyncClient(timeout=60) as client:
        resp = await client.post(
            f"{OPENROUTER_BASE_URL}/chat/completions",
            headers={
                "Authorization": f"Bearer {OPENROUTER_API_KEY}",
                "Content-Type": "application/json",
            },
            json=payload,
        )

    if resp.status_code != 200:
        raise HTTPException(status_code=502, detail=f"Translation failed: {resp.status_code}")

    data = resp.json()
    try:
        translated = data["choices"][0]["message"]["content"].strip()
    except (KeyError, IndexError, AttributeError):
        raise HTTPException(status_code=502, detail="Malformed OpenRouter response")
    return {"translated_text": translated}


# ── Review / Correction CRUD ────────────────────────────────────────────────
# Stores expert-or-farmer-submitted corrections with the image and a comment.
# Image is base64'd into the document so each review is self-contained
# and the data is exportable as a future training set.
#
# Auth model: matches the rest of the service — role is taken from the
# requesting client. Frontend gates the UI; backend enforces ownership +
# role checks on read/update/delete. Tighten when JWT middleware is added.

VALID_LABELS = set(CLASS_NAMES) | {"Not_Onion", "Unsure"}
# Roles that may read individual reviews owned by other users (per-review access).
ELEVATED_ROLES = {"admin", "extension officer", "extension_officer", "extension"}
# Listing the entire queue and exporting it is admin-only.
ADMIN_ROLES = {"admin"}


def _normalize_role(role: str) -> str:
    return (role or "").strip().lower()


def _is_elevated(role: str) -> bool:
    return _normalize_role(role) in ELEVATED_ROLES


def _is_admin(role: str) -> bool:
    return _normalize_role(role) in ADMIN_ROLES


def _mime_to_ext(mime: str) -> str:
    return {
        "image/jpeg": "jpg",
        "image/jpg": "jpg",
        "image/png": "png",
        "image/webp": "webp",
        "image/gif": "gif",
    }.get((mime or "").lower(), "jpg")


def _serialize_review(doc: dict, include_image: bool = True) -> dict:
    out = {
        "id": str(doc["_id"]),
        "user_email": doc.get("user_email", ""),
        "user_role": doc.get("user_role", ""),
        "original_prediction": doc.get("original_prediction", ""),
        "original_confidence": doc.get("original_confidence", 0.0),
        "corrected_label": doc.get("corrected_label", ""),
        "comment": doc.get("comment", ""),
        "status": doc.get("status", "pending"),
        "image_mime": doc.get("image_mime", "image/jpeg"),
        "created_at": doc.get("created_at", ""),
        "updated_at": doc.get("updated_at", ""),
    }
    if include_image and doc.get("image_b64"):
        out["image_b64"] = doc["image_b64"]
    return out


def _parse_object_id(raw: str) -> ObjectId:
    try:
        return ObjectId(raw)
    except (InvalidId, TypeError):
        raise HTTPException(status_code=400, detail="Invalid review id")


@app.post("/reviews")
async def create_review(
    file: UploadFile = File(...),
    user_email: str = Form(...),
    user_role: str = Form(...),
    corrected_label: str = Form(...),
    original_prediction: str = Form(""),
    original_confidence: float = Form(0.0),
    comment: str = Form(""),
):
    if corrected_label not in VALID_LABELS:
        raise HTTPException(
            status_code=400,
            detail=f"corrected_label must be one of: {sorted(VALID_LABELS)}",
        )
    image_bytes = await read_image_upload(file)
    mime = file.content_type if (file.content_type or "").startswith("image/") else "image/jpeg"
    now = datetime.now(timezone.utc).isoformat()

    doc = {
        "user_email": user_email,
        "user_role": user_role,
        "original_prediction": original_prediction,
        "original_confidence": float(original_confidence),
        "corrected_label": corrected_label,
        "comment": comment,
        "status": "pending",
        "image_b64": base64.b64encode(image_bytes).decode("ascii"),
        "image_mime": mime,
        "created_at": now,
        "updated_at": now,
    }
    result = await reviews_collection.insert_one(doc)
    doc["_id"] = result.inserted_id
    return {"success": True, "review": _serialize_review(doc, include_image=False)}


@app.get("/reviews/by-user/{email}")
async def list_reviews_by_user(email: str):
    cursor = reviews_collection.find({"user_email": email}).sort("created_at", -1).limit(200)
    docs = await cursor.to_list(length=200)
    return {
        "success": True,
        "reviews": [_serialize_review(d, include_image=False) for d in docs],
    }


@app.get("/reviews")
async def list_all_reviews(requester_role: str = ""):
    if not _is_admin(requester_role):
        raise HTTPException(status_code=403, detail="Only admin can list all reviews")
    cursor = reviews_collection.find({}).sort("created_at", -1).limit(500)
    docs = await cursor.to_list(length=500)
    return {
        "success": True,
        "reviews": [_serialize_review(d, include_image=False) for d in docs],
    }


@app.get("/reviews/export.zip")
async def export_reviews_zip(requester_role: str = ""):
    """Admin-only ZIP export. Bundle:
        reviews.csv         (one row per review, references image_path)
        images/<id>.<ext>   (decoded image bytes)
    """
    import csv as _csv
    import zipfile as _zip

    if not _is_admin(requester_role):
        raise HTTPException(status_code=403, detail="Only admin can export reviews")

    cursor = reviews_collection.find({}).sort("created_at", -1)
    docs = await cursor.to_list(length=None)

    csv_buf = io.StringIO()
    writer = _csv.writer(csv_buf)
    writer.writerow([
        "id", "image_path", "user_email", "user_role",
        "original_prediction", "original_confidence",
        "corrected_label", "comment", "status",
        "created_at", "updated_at",
    ])

    zip_buf = io.BytesIO()
    with _zip.ZipFile(zip_buf, "w", _zip.ZIP_DEFLATED) as zf:
        for d in docs:
            rid = str(d["_id"])
            ext = _mime_to_ext(d.get("image_mime", "image/jpeg"))
            image_path = f"images/{rid}.{ext}"
            writer.writerow([
                rid,
                image_path,
                d.get("user_email", ""),
                d.get("user_role", ""),
                d.get("original_prediction", ""),
                d.get("original_confidence", ""),
                d.get("corrected_label", ""),
                d.get("comment", ""),
                d.get("status", ""),
                d.get("created_at", ""),
                d.get("updated_at", ""),
            ])
            b64 = d.get("image_b64")
            if b64:
                try:
                    zf.writestr(image_path, base64.b64decode(b64))
                except Exception:
                    pass
        zf.writestr("reviews.csv", csv_buf.getvalue())

    zip_buf.seek(0)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%d-%H%M%S")
    from fastapi.responses import StreamingResponse
    return StreamingResponse(
        iter([zip_buf.getvalue()]),
        media_type="application/zip",
        headers={
            "Content-Disposition": f'attachment; filename="reviews-export-{stamp}.zip"',
        },
    )


@app.get("/reviews/{review_id}")
async def get_review(review_id: str, requester_email: str = "", requester_role: str = ""):
    oid = _parse_object_id(review_id)
    doc = await reviews_collection.find_one({"_id": oid})
    if not doc:
        raise HTTPException(status_code=404, detail="Review not found")
    if doc.get("user_email") != requester_email and not _is_elevated(requester_role):
        raise HTTPException(status_code=403, detail="Not authorized to view this review")
    return {"success": True, "review": _serialize_review(doc, include_image=True)}


class UpdateReviewRequest(BaseModel):
    requester_email: str
    requester_role: str = ""
    corrected_label: Optional[str] = None
    comment: Optional[str] = None
    status: Optional[str] = None


@app.patch("/reviews/{review_id}")
async def update_review(review_id: str, req: UpdateReviewRequest):
    oid = _parse_object_id(review_id)
    doc = await reviews_collection.find_one({"_id": oid})
    if not doc:
        raise HTTPException(status_code=404, detail="Review not found")
    is_owner = doc.get("user_email") == req.requester_email
    is_admin = _normalize_role(req.requester_role) == "admin"
    if not (is_owner or is_admin):
        raise HTTPException(status_code=403, detail="Not authorized to edit this review")

    updates: dict = {}
    if req.corrected_label is not None:
        if req.corrected_label not in VALID_LABELS:
            raise HTTPException(
                status_code=400,
                detail=f"corrected_label must be one of: {sorted(VALID_LABELS)}",
            )
        updates["corrected_label"] = req.corrected_label
    if req.comment is not None:
        updates["comment"] = req.comment
    if req.status is not None:
        if not is_admin and not _is_elevated(req.requester_role):
            raise HTTPException(status_code=403, detail="Only admin/extension officer can change status")
        updates["status"] = req.status
    if not updates:
        return {"success": True, "message": "No changes"}

    updates["updated_at"] = datetime.now(timezone.utc).isoformat()
    await reviews_collection.update_one({"_id": oid}, {"$set": updates})
    new_doc = await reviews_collection.find_one({"_id": oid})
    return {"success": True, "review": _serialize_review(new_doc, include_image=False)}


@app.delete("/reviews/{review_id}")
async def delete_review(review_id: str, requester_email: str = "", requester_role: str = ""):
    oid = _parse_object_id(review_id)
    doc = await reviews_collection.find_one({"_id": oid})
    if not doc:
        raise HTTPException(status_code=404, detail="Review not found")
    is_owner = doc.get("user_email") == requester_email
    is_admin = _normalize_role(requester_role) == "admin"
    if not (is_owner or is_admin):
        raise HTTPException(status_code=403, detail="Not authorized to delete this review")
    await reviews_collection.delete_one({"_id": oid})
    return {"success": True, "deleted_id": review_id}


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8002))
    uvicorn.run(app, host="0.0.0.0", port=port)

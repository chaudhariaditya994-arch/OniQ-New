import os
import secrets
import logging
from datetime import datetime, timedelta, timezone
from fastapi import FastAPI, HTTPException
from motor.motor_asyncio import AsyncIOMotorClient
from pydantic import BaseModel, EmailStr
from passlib.context import CryptContext
from jose import jwt

from app.email_helper import send_reset_email, send_feedback_email, CODE_EXPIRY_MINUTES

logger = logging.getLogger("auth-service")
logging.basicConfig(level=logging.INFO)

app = FastAPI(title="OnionGuard Auth Service", version="1.0.0")

MONGODB_URI = os.getenv("MONGODB_URI", "mongodb://localhost:27017")
DATABASE_NAME = os.getenv("DATABASE_NAME", "onionguard_auth")
JWT_SECRET = os.getenv("JWT_SECRET", "onionguard-secret-change-in-production")
JWT_ALGORITHM = "HS256"

client = AsyncIOMotorClient(MONGODB_URI)
db = client[DATABASE_NAME]
users_collection = db["users"]
reset_codes_collection = db["password_reset_codes"]

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


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


def create_token(data: dict) -> str:
    return jwt.encode(data, JWT_SECRET, algorithm=JWT_ALGORITHM)


@app.get("/health")
async def health():
    return {"status": "ok", "service": "auth-service"}


@app.post("/register")
async def register(req: RegisterRequest):
    existing = await users_collection.find_one({"email": req.email.lower()})
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")

    existing_username = await users_collection.find_one({"username": req.username})
    if existing_username:
        raise HTTPException(status_code=400, detail="Username already taken")

    if req.user_type == "Admin":
        existing_admin = await users_collection.find_one({"user_type": "Admin"})
        if existing_admin:
            raise HTTPException(status_code=400, detail="An admin account already exists. Only one admin is allowed.")

    user_doc = {
        "name": req.name,
        "email": req.email.lower(),
        "phone": req.phone,
        "password": pwd_context.hash(req.password),
        "user_type": req.user_type,
        "username": req.username,
        "language_preference": req.language_preference,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "is_active": True,
    }
    await users_collection.insert_one(user_doc)

    return {
        "success": True,
        "message": "Account successfully created.",
    }


@app.post("/login")
async def login(req: LoginRequest):
    user = await users_collection.find_one({"email": req.email.lower()})
    if not user:
        raise HTTPException(status_code=401, detail="No account found. Please create an account.")

    if not user.get("is_active", True):
        raise HTTPException(status_code=403, detail="Your account has been deactivated")

    if user["user_type"] != req.user_type:
        raise HTTPException(
            status_code=401,
            detail=f"This email is not registered as {req.user_type}. You are registered as {user['user_type']}."
        )

    if not pwd_context.verify(req.password, user["password"]):
        raise HTTPException(status_code=401, detail="Invalid password")

    token = create_token({
        "email": user["email"],
        "user_type": user["user_type"],
        "name": user["name"],
    })

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


@app.get("/profile/{email}")
async def get_profile(email: str):
    user = await users_collection.find_one({"email": email.lower()})
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


@app.get("/users")
async def list_users():
    cursor = users_collection.find({}, {"_id": 0, "password": 0})
    users = await cursor.to_list(length=500)
    return {"success": True, "users": users}


@app.post("/users/{email}/toggle-status")
async def toggle_user_status(email: str):
    user = await users_collection.find_one({"email": email.lower()})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    new_status = not user.get("is_active", True)
    await users_collection.update_one(
        {"email": email.lower()},
        {"$set": {"is_active": new_status}}
    )
    return {"success": True, "is_active": new_status, "message": f"User {'activated' if new_status else 'deactivated'}"}


class ChangePasswordRequest(BaseModel):
    email: str
    old_password: str
    new_password: str


@app.post("/change-password")
async def change_password(req: ChangePasswordRequest):
    user = await users_collection.find_one({"email": req.email.lower()})
    if not user:
        raise HTTPException(status_code=404, detail="No account found with this email")

    if not pwd_context.verify(req.old_password, user["password"]):
        raise HTTPException(status_code=401, detail="Old password is incorrect")

    new_hash = pwd_context.hash(req.new_password)
    await users_collection.update_one(
        {"email": req.email.lower()},
        {"$set": {"password": new_hash}}
    )

    return {
        "success": True,
        "message": "Password changed successfully.",
    }


@app.post("/forgot-password/{email}")
async def forgot_password(email: str):
    """
    Always returns success regardless of whether the email exists.
    This prevents account enumeration. If a real user matches, an email is sent
    with a 6-digit code valid for CODE_EXPIRY_MINUTES.
    """
    normalized = email.lower().strip()
    user = await users_collection.find_one({"email": normalized})
    if user:
        await reset_codes_collection.update_many(
            {"email": normalized, "used": False},
            {"$set": {"used": True, "invalidated_at": datetime.now(timezone.utc).isoformat()}},
        )

        code = f"{secrets.randbelow(1_000_000):06d}"
        now = datetime.now(timezone.utc)
        await reset_codes_collection.insert_one({
            "email": normalized,
            "code": code,
            "created_at": now.isoformat(),
            "expires_at": (now + timedelta(minutes=CODE_EXPIRY_MINUTES)).isoformat(),
            "used": False,
        })

        try:
            send_reset_email(normalized, code)
        except Exception as e:
            logger.error("Failed to send reset email to %s: %s", normalized, e)

    return {
        "success": True,
        "message": "If an account exists for that email, a verification code has been sent.",
    }


class ResetPasswordRequest(BaseModel):
    email: str
    code: str
    new_password: str


@app.post("/reset-password")
async def reset_password(req: ResetPasswordRequest):
    normalized = req.email.lower().strip()
    code = req.code.strip()

    if len(req.new_password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters")

    record = await reset_codes_collection.find_one({
        "email": normalized,
        "code": code,
        "used": False,
    })
    if not record:
        raise HTTPException(status_code=400, detail="Invalid or expired code")

    if datetime.fromisoformat(record["expires_at"]) < datetime.now(timezone.utc):
        raise HTTPException(status_code=400, detail="Invalid or expired code")

    user = await users_collection.find_one({"email": normalized})
    if not user:
        raise HTTPException(status_code=400, detail="Invalid or expired code")

    new_hash = pwd_context.hash(req.new_password)
    await users_collection.update_one(
        {"email": normalized},
        {"$set": {"password": new_hash}},
    )
    await reset_codes_collection.update_one(
        {"_id": record["_id"]},
        {"$set": {"used": True, "used_at": datetime.now(timezone.utc).isoformat()}},
    )

    return {"success": True, "message": "Password reset successfully. You can now log in."}


class FeedbackRequest(BaseModel):
    name: str
    email: str
    subject: str
    message: str


@app.post("/feedback")
async def submit_feedback(req: FeedbackRequest):
    if not req.message.strip():
        raise HTTPException(status_code=400, detail="Message cannot be empty")
    if len(req.message) > 5000:
        raise HTTPException(status_code=400, detail="Message too long (5000 char max)")
    try:
        send_feedback_email(
            user_name=req.name.strip() or "Anonymous user",
            user_email=req.email.strip().lower(),
            subject=req.subject.strip() or "(no subject)",
            message=req.message.strip(),
        )
    except Exception as e:
        logger.error("Failed to send feedback email: %s", e)
        raise HTTPException(status_code=502, detail="Could not send feedback. Please try again later.")
    return {"success": True, "message": "Thanks for the feedback — we'll review it shortly."}


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8001))
    uvicorn.run(app, host="0.0.0.0", port=port)

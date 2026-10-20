import os
from dotenv import load_dotenv

load_dotenv()


def get_env(key: str, default: str = "") -> str:
    return os.getenv(key, default)


MONGODB_URI = get_env("MONGODB_URI", "mongodb://localhost:27017")
JWT_SECRET = get_env("JWT_SECRET", "onionguard-secret-change-in-production")
JWT_ALGORITHM = "HS256"
JWT_EXPIRATION_MINUTES = 1440  # 24 hours

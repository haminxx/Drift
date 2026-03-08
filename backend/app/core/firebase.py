"""
Firebase Admin initialization for the backend.
Works for both Render (env var) and local Windows dev (firebase-key.json file).

Priority:
  1. FIREBASE_CREDENTIALS_JSON (Render: paste full JSON contents of service account key)
  2. GOOGLE_APPLICATION_CREDENTIALS_JSON (same, alternative name)
  3. Local file firebase-key.json in backend root or current working directory (Windows dev)
"""

import os
import json
from typing import Optional

_firebase_initialized = False


def _get_credential_dict() -> Optional[dict]:
    """Load credential dict from env or local file. Returns None if not configured."""
    # 1. Render / production: env var with full JSON
    for env_name in ("FIREBASE_CREDENTIALS_JSON", "GOOGLE_APPLICATION_CREDENTIALS_JSON"):
        json_str = os.environ.get(env_name)
        if json_str and json_str.strip():
            try:
                return json.loads(json_str)
            except json.JSONDecodeError:
                continue
    # 2. Local: firebase-key.json (backend root or cwd)
    for base_dir in (os.getcwd(), os.path.dirname(os.path.dirname(os.path.abspath(__file__)))):
        path = os.path.join(base_dir, "firebase-key.json")
        if os.path.isfile(path):
            try:
                with open(path, "r", encoding="utf-8") as f:
                    return json.load(f)
            except (OSError, json.JSONDecodeError):
                continue
    return None


def init_firebase_if_configured() -> bool:
    """
    Initialize Firebase Admin SDK from FIREBASE_CREDENTIALS_JSON, GOOGLE_APPLICATION_CREDENTIALS_JSON,
    or local firebase-key.json. Returns True if initialized, False otherwise.
    """
    global _firebase_initialized
    if _firebase_initialized:
        return True
    cred_dict = _get_credential_dict()
    if not cred_dict:
        return False
    try:
        import firebase_admin
        from firebase_admin import credentials
    except ImportError:
        return False
    try:
        cred = credentials.Certificate(cred_dict)
        firebase_admin.initialize_app(cred)
        _firebase_initialized = True
        return True
    except Exception:
        return False


def get_firebase_app():
    """Return the Firebase app if initialized; otherwise None."""
    if not _firebase_initialized:
        return None
    import firebase_admin
    return firebase_admin.get_app()

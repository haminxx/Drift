"""Encrypt / decrypt OAuth token payloads at rest using Fernet."""

from __future__ import annotations

import json
import os
from typing import Any, Optional

from app.core import config


def _fernet():
    from cryptography.fernet import Fernet

    key = config.TOKEN_ENCRYPTION_KEY.strip()
    if not key:
        # Dev fallback: derive a deterministic key from a weak secret (NOT for production).
        weak = os.environ.get("DRIFT_DEV_TOKEN_SALT", "drift-dev-only-unsafe")
        import hashlib
        import base64

        digest = hashlib.sha256(weak.encode()).digest()
        key = base64.urlsafe_b64encode(digest).decode()
    return Fernet(key.encode() if isinstance(key, str) else key)


def encrypt_json(payload: dict[str, Any]) -> str:
    """Return url-safe base64 ciphertext string for Firestore."""
    raw = json.dumps(payload, separators=(",", ":")).encode()
    return _fernet().encrypt(raw).decode()


def decrypt_json(ciphertext: str) -> dict[str, Any]:
    raw = _fernet().decrypt(ciphertext.encode())
    return json.loads(raw.decode())


def encryption_configured() -> bool:
    return bool(config.TOKEN_ENCRYPTION_KEY.strip())

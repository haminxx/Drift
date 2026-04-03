"""Persist encrypted wearable OAuth tokens under users/{uid}/wearable_connections/{provider}."""

from __future__ import annotations

from datetime import datetime
from typing import Optional

from app.core.firebase import init_firebase_if_configured
from app.core.token_vault import decrypt_json, encrypt_json
from app.models.wearable_schema import WearableTokenRecord


def _db():
    if not init_firebase_if_configured():
        return None
    from firebase_admin import firestore

    return firestore.client()


def save_tokens(uid: str, record: WearableTokenRecord) -> bool:
    """Encrypt and upsert token bundle for a provider."""
    db = _db()
    if not db:
        return False
    payload = {
        "access_token": record.access_token,
        "refresh_token": record.refresh_token,
        "expires_at_epoch": record.expires_at_epoch,
        "scope": record.scope,
    }
    enc = encrypt_json(payload)
    ref = (
        db.collection("users")
        .document(uid)
        .collection("wearable_connections")
        .document(record.provider)
    )
    ref.set(
        {
            "provider": record.provider,
            "tokenCiphertext": enc,
            "updatedAt": datetime.utcnow(),
        },
        merge=True,
    )
    return True


def load_tokens(uid: str, provider: str) -> Optional[WearableTokenRecord]:
    db = _db()
    if not db:
        return None
    snap = (
        db.collection("users")
        .document(uid)
        .collection("wearable_connections")
        .document(provider)
        .get()
    )
    if not snap.exists:
        return None
    data = snap.to_dict() or {}
    ct = data.get("tokenCiphertext")
    if not ct:
        return None
    try:
        inner = decrypt_json(ct)
    except Exception:
        return None
    return WearableTokenRecord(
        provider=provider,
        access_token=inner.get("access_token", ""),
        refresh_token=inner.get("refresh_token"),
        expires_at_epoch=inner.get("expires_at_epoch"),
        scope=inner.get("scope"),
    )


def delete_connection(uid: str, provider: str) -> bool:
    db = _db()
    if not db:
        return False
    db.collection("users").document(uid).collection("wearable_connections").document(provider).delete()
    return True

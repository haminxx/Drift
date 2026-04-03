"""Short-lived OAuth state (CSRF): Firestore when available, else in-memory for single-worker dev."""

from __future__ import annotations

import time
from datetime import datetime, timedelta, timezone
from typing import Optional, Tuple

from app.core.firebase import init_firebase_if_configured

_memory: dict[str, Tuple[str, str, float]] = {}


def _db():
    if not init_firebase_if_configured():
        return None
    from firebase_admin import firestore

    return firestore.client()


def save_oauth_state(state: str, uid: str, provider: str, ttl_minutes: int = 15) -> bool:
    db = _db()
    if db:
        exp = datetime.now(timezone.utc) + timedelta(minutes=ttl_minutes)
        db.collection("oauth_pending").document(state).set(
            {"uid": uid, "provider": provider, "expiresAt": exp}
        )
        return True
    _memory[state] = (uid, provider, time.time() + ttl_minutes * 60)
    return True


def pop_oauth_state(state: str) -> Optional[Tuple[str, str]]:
    """Return (uid, provider) if valid, and remove."""
    db = _db()
    if db:
        ref = db.collection("oauth_pending").document(state)
        snap = ref.get()
        if not snap.exists:
            return None
        data = snap.to_dict() or {}
        exp = data.get("expiresAt")
        if exp is not None:
            now = datetime.now(timezone.utc)
            if hasattr(exp, "timestamp"):
                if exp.tzinfo is None:
                    exp = exp.replace(tzinfo=timezone.utc)
            if exp < now:
                ref.delete()
                return None
        uid = data.get("uid")
        provider = data.get("provider")
        ref.delete()
        if not uid or not provider:
            return None
        return (uid, provider)

    raw = _memory.pop(state, None)
    if not raw:
        return None
    uid, provider, exp_epoch = raw
    if time.time() > exp_epoch:
        return None
    return (uid, provider)

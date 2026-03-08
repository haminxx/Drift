"""
Firestore helpers for users and summaries.
Collections: users/{uid}, users/{uid}/summaries/{summaryId}.
Backend uses Firebase Admin SDK; ensure GOOGLE_APPLICATION_CREDENTIALS_JSON is set on Render.
"""

from datetime import datetime
from typing import Any, Optional

from app.core.firebase import init_firebase_if_configured


def _get_firestore():
    """Return Firestore client if Firebase is initialized."""
    if not init_firebase_if_configured():
        return None
    from firebase_admin import firestore
    return firestore.client()


def set_user_profile(uid: str, email: Optional[str] = None, display_name: Optional[str] = None, **fields) -> bool:
    """Create or update users/{uid} document."""
    db = _get_firestore()
    if not db:
        return False
    doc = db.collection("users").document(uid)
    data: dict[str, Any] = {"updatedAt": datetime.utcnow(), **fields}
    if email is not None:
        data["email"] = email
    if display_name is not None:
        data["displayName"] = display_name
    doc.set(data, merge=True)
    return True


def save_summary(
    uid: str,
    summary_id: str,
    date: str,
    flow_percent: float,
    drift_percent: float,
    avg_hrv: Optional[float] = None,
    intervention_count: int = 0,
    **extra: Any,
) -> bool:
    """Write a daily/session summary to users/{uid}/summaries/{summaryId}."""
    db = _get_firestore()
    if not db:
        return False
    ref = db.collection("users").document(uid).collection("summaries").document(summary_id)
    ref.set({
        "date": date,
        "flowPercent": flow_percent,
        "driftPercent": drift_percent,
        "avgHRV": avg_hrv,
        "interventionCount": intervention_count,
        "createdAt": datetime.utcnow(),
        **extra,
    }, merge=True)
    return True


def get_user_summaries(uid: str, limit: int = 30) -> list[dict]:
    """Read recent summaries for a user (for charts)."""
    db = _get_firestore()
    if not db:
        return []
    ref = db.collection("users").document(uid).collection("summaries")
    docs = ref.order_by("createdAt", direction="DESCENDING").limit(limit).stream()
    return [{"id": d.id, **d.to_dict()} for d in docs]

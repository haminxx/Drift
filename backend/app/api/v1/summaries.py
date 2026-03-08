"""Summaries API: GET /api/v1/summaries (requires Firebase Auth)."""
from fastapi import APIRouter, Depends
from app.core.auth import require_firebase_token
from app.core.firestore_helpers import get_user_summaries

router = APIRouter(prefix="/summaries", tags=["summaries"])


@router.get("")
def get_summaries(
    limit: int = 30,
    uid: str = Depends(require_firebase_token),
) -> list:
    """
    Return recent flow summaries for the authenticated user (for charts).
    Requires Authorization: Bearer <Firebase ID token>.
    """
    return get_user_summaries(uid, limit=limit)

"""
Verify Firebase ID token from Authorization: Bearer <token>.
Use as a FastAPI dependency for protected routes. Optional: endpoints work without auth if token missing.
"""

from typing import Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

_security = HTTPBearer(auto_error=False)


def verify_firebase_token(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(_security),
) -> Optional[str]:
    """
    If Authorization Bearer token is present, verify it with Firebase Admin and return uid.
    If no token or Firebase not configured, return None (caller can treat as anonymous).
    """
    from app.core.firebase import init_firebase_if_configured

    if not credentials or not credentials.credentials:
        return None
    if not init_firebase_if_configured():
        return None
    try:
        import firebase_admin.auth
        decoded = firebase_admin.auth.verify_id_token(credentials.credentials)
        return decoded.get("uid")
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        )


def require_firebase_token(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(_security),
) -> str:
    """
    Require a valid Firebase ID token; return uid or raise 401.
    Use for routes that must be authenticated.
    """
    uid = verify_firebase_token(credentials)
    if uid is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authorization required",
        )
    return uid

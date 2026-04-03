"""Multi-brand wearable OAuth: authorize URL + code exchange (Fitbit, Garmin)."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status

from app.core import config
from app.core.auth import require_firebase_token
from app.core.oauth_state import pop_oauth_state, save_oauth_state
from app.core.wearable_store import save_tokens
from app.models.wearable_schema import (
    AuthorizeUrlResponse,
    OAuthExchangeRequest,
    OAuthExchangeResponse,
    ProviderInfo,
    WearableAuthType,
)
from app.services.wearable.fitbit_oauth import FitbitOAuthProvider, generate_state
from app.services.wearable.garmin_oauth import GarminOAuthProvider

router = APIRouter(prefix="/wearables", tags=["wearables"])

_fitbit = FitbitOAuthProvider()
_garmin = GarminOAuthProvider()


@router.get("/providers", response_model=list[ProviderInfo])
def list_providers() -> list[ProviderInfo]:
    """Public: which OAuth providers are server-configured (no secrets exposed)."""
    return [
        ProviderInfo(
            id="apple_healthkit",
            display_name="Apple Watch / Apple Health",
            auth_type=WearableAuthType.NONE,
            configured=True,
            notes="On-device HealthKit; no OAuth. Configure capabilities in Xcode.",
        ),
        ProviderInfo(
            id=_fitbit.provider_id,
            display_name=_fitbit.display_name,
            auth_type=WearableAuthType.OAUTH2,
            configured=_fitbit.is_configured(),
            notes="Register redirect URI to match FITBIT_REDIRECT_URI (e.g. drift://oauth/callback).",
        ),
        ProviderInfo(
            id=_garmin.provider_id,
            display_name=_garmin.display_name,
            auth_type=WearableAuthType.OAUTH2,
            configured=_garmin.is_configured(),
            notes="Requires Garmin Connect Developer Program approval and env URLs.",
        ),
        ProviderInfo(
            id="google_fit",
            display_name="Google Fit / Health Connect",
            auth_type=WearableAuthType.OAUTH2,
            configured=False,
            notes="Use Android Health Connect or Google Fit API; not wired in this backend yet.",
        ),
        ProviderInfo(
            id="samsung",
            display_name="Samsung Health",
            auth_type=WearableAuthType.OAUTH2,
            configured=False,
            notes="Program-specific; partner approval may be required.",
        ),
    ]


@router.get("/oauth/fitbit/authorize-url", response_model=AuthorizeUrlResponse)
def fitbit_authorize_url(uid: str = Depends(require_firebase_token)) -> AuthorizeUrlResponse:
    if not _fitbit.is_configured():
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Fitbit OAuth not configured on server",
        )
    state = generate_state()
    redirect = config.FITBIT_REDIRECT_URI
    save_oauth_state(state, uid, "fitbit")
    url = _fitbit.build_authorize_url(state=state, redirect_uri=redirect)
    return AuthorizeUrlResponse(url=url, state=state, redirect_uri=redirect, provider="fitbit")


@router.post("/oauth/fitbit/exchange", response_model=OAuthExchangeResponse)
async def fitbit_exchange(
    body: OAuthExchangeRequest,
    uid: str = Depends(require_firebase_token),
) -> OAuthExchangeResponse:
    if not body.state:
        raise HTTPException(status_code=400, detail="state is required")
    popped = pop_oauth_state(body.state)
    if not popped or popped[0] != uid or popped[1] != "fitbit":
        raise HTTPException(status_code=400, detail="invalid or expired OAuth state")
    redirect = body.redirect_uri or config.FITBIT_REDIRECT_URI
    try:
        record = await _fitbit.exchange_code(code=body.code, redirect_uri=redirect)
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Fitbit token exchange failed: {e!s}") from e
    if not save_tokens(uid, record):
        raise HTTPException(
            status_code=503,
            detail="Could not persist tokens (Firebase / Firestore not configured)",
        )
    return OAuthExchangeResponse(ok=True, provider="fitbit", message="connected")


@router.get("/oauth/garmin/authorize-url", response_model=AuthorizeUrlResponse)
def garmin_authorize_url(uid: str = Depends(require_firebase_token)) -> AuthorizeUrlResponse:
    if not _garmin.is_configured():
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Garmin OAuth not configured on server",
        )
    state = generate_state()
    redirect = config.GARMIN_REDIRECT_URI
    save_oauth_state(state, uid, "garmin")
    url = _garmin.build_authorize_url(state=state, redirect_uri=redirect)
    return AuthorizeUrlResponse(url=url, state=state, redirect_uri=redirect, provider="garmin")


@router.post("/oauth/garmin/exchange", response_model=OAuthExchangeResponse)
async def garmin_exchange(
    body: OAuthExchangeRequest,
    uid: str = Depends(require_firebase_token),
) -> OAuthExchangeResponse:
    if not body.state:
        raise HTTPException(status_code=400, detail="state is required")
    popped = pop_oauth_state(body.state)
    if not popped or popped[0] != uid or popped[1] != "garmin":
        raise HTTPException(status_code=400, detail="invalid or expired OAuth state")
    redirect = body.redirect_uri or config.GARMIN_REDIRECT_URI
    try:
        record = await _garmin.exchange_code(code=body.code, redirect_uri=redirect)
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Garmin token exchange failed: {e!s}") from e
    if not save_tokens(uid, record):
        raise HTTPException(
            status_code=503,
            detail="Could not persist tokens (Firebase / Firestore not configured)",
        )
    return OAuthExchangeResponse(ok=True, provider="garmin", message="connected")

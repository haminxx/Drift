"""Pydantic models for multi-brand wearable OAuth and token records."""

from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


class WearableProviderId(str, Enum):
    """Supported cloud / OAuth providers (distinct from on-device HealthKit)."""

    FITBIT = "fitbit"
    GARMIN = "garmin"
    GOOGLE_FIT = "google_fit"
    SAMSUNG = "samsung"
    APPLE_HEALTHKIT = "apple_healthkit"  # informational only; no OAuth


class WearableAuthType(str, Enum):
    OAUTH2 = "oauth2"
    NONE = "none"  # HealthKit, local only


class ProviderInfo(BaseModel):
    id: str
    display_name: str
    auth_type: WearableAuthType
    configured: bool = Field(description="Server has client credentials for OAuth exchange")
    notes: Optional[str] = None


class AuthorizeUrlResponse(BaseModel):
    url: str
    state: str
    redirect_uri: str
    provider: str


class OAuthExchangeRequest(BaseModel):
    code: str
    state: Optional[str] = None
    redirect_uri: Optional[str] = None


class OAuthExchangeResponse(BaseModel):
    ok: bool
    provider: str
    message: str = "connected"


class WearableTokenRecord(BaseModel):
    """Decrypted in-memory representation; stored encrypted in Firestore."""

    provider: str
    access_token: str
    refresh_token: Optional[str] = None
    expires_at_epoch: Optional[float] = None
    scope: Optional[str] = None

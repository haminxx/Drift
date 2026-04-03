"""Fitbit Web API OAuth2 (authorization code)."""

from __future__ import annotations

import base64
import secrets
import urllib.parse
from typing import Optional

import httpx

from app.core import config
from app.models.wearable_schema import WearableTokenRecord


FITBIT_AUTHORIZE = "https://www.fitbit.com/oauth2/authorize"
FITBIT_TOKEN = "https://api.fitbit.com/oauth2/token"
# HRV + heart rate read scopes (adjust in Fitbit app registration if needed)
DEFAULT_FITBIT_SCOPE = "heartrate respiratory_rate oxygen_saturation sleep activity profile"


class FitbitOAuthProvider:
    provider_id = "fitbit"
    display_name = "Fitbit"

    def is_configured(self) -> bool:
        return bool(config.FITBIT_CLIENT_ID and config.FITBIT_CLIENT_SECRET)

    def build_authorize_url(self, *, state: str, redirect_uri: str) -> str:
        cid = config.FITBIT_CLIENT_ID
        params = {
            "response_type": "code",
            "client_id": cid,
            "redirect_uri": redirect_uri,
            "scope": DEFAULT_FITBIT_SCOPE.strip(),
            "state": state,
            "expires_in": "604800",
        }
        q = urllib.parse.urlencode(params)
        return f"{FITBIT_AUTHORIZE}?{q}"

    async def exchange_code(self, *, code: str, redirect_uri: str) -> WearableTokenRecord:
        if not self.is_configured():
            raise RuntimeError("Fitbit OAuth is not configured (missing FITBIT_CLIENT_ID / FITBIT_CLIENT_SECRET)")

        cid = config.FITBIT_CLIENT_ID
        secret = config.FITBIT_CLIENT_SECRET
        basic = base64.b64encode(f"{cid}:{secret}".encode()).decode()

        data = urllib.parse.urlencode(
            {
                "client_id": cid,
                "grant_type": "authorization_code",
                "redirect_uri": redirect_uri,
                "code": code,
            }
        )

        headers = {
            "Authorization": f"Basic {basic}",
            "Content-Type": "application/x-www-form-urlencoded",
        }

        async with httpx.AsyncClient(timeout=30.0) as client:
            resp = await client.post(FITBIT_TOKEN, content=data, headers=headers)
            resp.raise_for_status()
            payload = resp.json()

        access = payload.get("access_token", "")
        refresh = payload.get("refresh_token")
        expires_in = payload.get("expires_in")
        scope = payload.get("scope")
        expires_at: Optional[float] = None
        if expires_in is not None:
            import time

            expires_at = time.time() + float(expires_in)

        return WearableTokenRecord(
            provider=self.provider_id,
            access_token=access,
            refresh_token=refresh,
            expires_at_epoch=expires_at,
            scope=scope,
        )


def generate_state() -> str:
    return secrets.token_urlsafe(32)

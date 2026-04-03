"""Garmin Connect Health API OAuth2 — endpoints vary by program; driven from env."""

from __future__ import annotations

import base64
import urllib.parse
from typing import Optional

import httpx

from app.core import config
from app.models.wearable_schema import WearableTokenRecord


class GarminOAuthProvider:
    provider_id = "garmin"
    display_name = "Garmin"

    def is_configured(self) -> bool:
        return bool(
            config.GARMIN_CLIENT_ID
            and config.GARMIN_CLIENT_SECRET
            and config.GARMIN_AUTHORIZATION_URL
            and config.GARMIN_TOKEN_URL
        )

    def build_authorize_url(self, *, state: str, redirect_uri: str) -> str:
        cid = config.GARMIN_CLIENT_ID
        params = {
            "response_type": "code",
            "client_id": cid,
            "redirect_uri": redirect_uri,
            "state": state,
        }
        if config.GARMIN_OAUTH_SCOPE:
            params["scope"] = config.GARMIN_OAUTH_SCOPE
        q = urllib.parse.urlencode(params)
        return f"{config.GARMIN_AUTHORIZATION_URL}?{q}"

    async def exchange_code(self, *, code: str, redirect_uri: str) -> WearableTokenRecord:
        if not self.is_configured():
            raise RuntimeError(
                "Garmin OAuth is not configured. Set GARMIN_CLIENT_ID, GARMIN_CLIENT_SECRET, "
                "GARMIN_AUTHORIZATION_URL, GARMIN_TOKEN_URL after Garmin Connect Developer approval."
            )

        cid = config.GARMIN_CLIENT_ID
        secret = config.GARMIN_CLIENT_SECRET
        basic = base64.b64encode(f"{cid}:{secret}".encode()).decode()

        data = urllib.parse.urlencode(
            {
                "grant_type": "authorization_code",
                "code": code,
                "redirect_uri": redirect_uri,
            }
        )

        headers = {
            "Authorization": f"Basic {basic}",
            "Content-Type": "application/x-www-form-urlencoded",
        }

        async with httpx.AsyncClient(timeout=30.0) as client:
            resp = await client.post(config.GARMIN_TOKEN_URL, content=data, headers=headers)
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

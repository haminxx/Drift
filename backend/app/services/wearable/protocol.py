"""Abstract wearable provider contract (OAuth2 cloud APIs vs HealthKit on-device)."""

from typing import Protocol, runtime_checkable

from app.models.wearable_schema import WearableTokenRecord


@runtime_checkable
class OAuthWearableProvider(Protocol):
    """Fitbit / Garmin-style OAuth2 authorization code flow."""

    provider_id: str
    display_name: str

    def is_configured(self) -> bool:
        """True if client credentials are present for token exchange."""
        ...

    def build_authorize_url(self, *, state: str, redirect_uri: str) -> str:
        """Full URL to open in ASWebAuthenticationSession / browser."""
        ...

    async def exchange_code(self, *, code: str, redirect_uri: str) -> WearableTokenRecord:
        """Trade authorization code for tokens; used by POST .../exchange."""
        ...

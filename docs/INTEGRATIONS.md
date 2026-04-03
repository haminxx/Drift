# Wearable integrations (Apple, Fitbit, Garmin, Google, Samsung)

Drift uses **two patterns**:

1. **On-device (Apple Watch / Apple Health)** — [HealthKit](https://developer.apple.com/documentation/healthkit) on iOS and watchOS. No vendor API key. Enable the HealthKit capability and usage strings in Xcode (see [ENTITLEMENTS.md](ENTITLEMENTS.md)). Garmin data can still reach the app via **Garmin Connect → Apple Health → HealthKit** without OAuth.

2. **Cloud OAuth (Fitbit, Garmin Connect API)** — Optional linking of a user account to third-party REST APIs. The backend stores **per-user** access/refresh tokens encrypted at rest (`TOKEN_ENCRYPTION_KEY`). Client secrets stay on the server (`FITBIT_CLIENT_SECRET`, `GARMIN_CLIENT_SECRET`).

Google Fit / Health Connect and Samsung Health are **not** implemented as OAuth adapters in this repo yet; the backend lists them in `GET /api/v1/wearables/providers` with `configured: false` until you add adapters.

---

## Backend environment variables

| Variable | Purpose |
|----------|---------|
| `FITBIT_CLIENT_ID` | Fitbit app OAuth client ID |
| `FITBIT_CLIENT_SECRET` | Fitbit client secret (server only) |
| `FITBIT_REDIRECT_URI` | Must match Fitbit app registration and iOS URL scheme callback (default `drift://oauth/callback`) |
| `GARMIN_CLIENT_ID` | After Garmin Connect Developer approval |
| `GARMIN_CLIENT_SECRET` | Garmin client secret |
| `GARMIN_AUTHORIZATION_URL` | Garmin OAuth authorize endpoint |
| `GARMIN_TOKEN_URL` | Garmin OAuth token endpoint |
| `GARMIN_OAUTH_SCOPE` | Space-separated scopes (if required) |
| `GARMIN_REDIRECT_URI` | Default `drift://oauth/garmin/callback` |
| `TOKEN_ENCRYPTION_KEY` | Fernet key (`python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"`) |

---

## API routes

- `GET /api/v1/wearables/providers` — Public list of providers and whether OAuth is server-configured.
- `GET /api/v1/wearables/oauth/fitbit/authorize-url` — Requires `Authorization: Bearer` Firebase ID token; returns Fitbit authorize URL and OAuth `state`.
- `POST /api/v1/wearables/oauth/fitbit/exchange` — JSON `{ "code", "state", "redirect_uri" }`; exchanges code and stores encrypted tokens under `users/{uid}/wearable_connections/fitbit`.
- Same pattern for `/oauth/garmin/authorize-url` and `/oauth/garmin/exchange`.

---

## iOS

- **URL scheme** `drift` is registered in `Info.plist` for OAuth redirects.
- **Lock** tab: **Connect Fitbit** / **Connect Garmin** opens `ASWebAuthenticationSession` (`WearableOAuthCoordinator.swift`) and completes the code exchange via `APIClient` (requires Firebase sign-in for Bearer token).

---

## Official developer registration links

| Brand | What you obtain | Official entry points |
|-------|------------------|------------------------|
| Apple Watch / HealthKit | App ID + HealthKit capability (no API key) | [HealthKit](https://developer.apple.com/documentation/healthkit), [Setting up HealthKit](https://developer.apple.com/documentation/HealthKit/setting-up-healthkit) |
| Fitbit | OAuth 2.0 client ID + secret | [Web API getting started](https://dev.fitbit.com/build/reference/web-api/developer-guide/getting-started), [Register / manage apps](https://dev.fitbit.com/apps) |
| Garmin | Garmin Connect Developer Program (approval) | [Health API](https://developer.garmin.com/gc-developer-program/health-api/), [Access request](https://www.garmin.com/en-US/forms/GarminConnectDeveloperAccess/), [Portal](https://healthapi.garmin.com/tools/) (after approval) |
| Samsung | Program-specific | [Samsung Developer — Health](https://developer.samsung.com/health) |
| Google (Android / Pixel) | Health Connect on-device | [Health Connect](https://developer.android.com/health-and-fitness/health-connect) |
| Google (cloud) | Google Fit API (OAuth) | [Google Fit API](https://developers.google.com/fit) |

---

## Security notes

- Do **not** embed Fitbit/Garmin client secrets in the iOS app.
- Use **HTTPS** for production backends; register redirect URIs exactly as configured.
- OAuth `state` is tracked in Firestore (`oauth_pending`) when Firebase is configured; otherwise an in-memory store is used for single-worker development only.

# Drift — System Overview

This document describes how the Drift app and backend work together.

---

## What the app does

Drift is an **ADHD cognitive-assistance app** that:

1. **Collects HRV** (heart rate variability) from an Apple Watch or from Garmin via Apple Health.
2. **Sends HRV to a Python backend**, which decides if you’re “in flow” (focused) or “drifting” (stressed/distracted).
3. **If you’re drifting:** shows a Time-Sensitive notification (“Entertainment apps will lock in 5 minutes”) and starts a 5-minute timer.
4. **If the timer ends and you’re still not in flow:** applies a **Screen Time–style shield** to selected distracting apps (Family Controls).
5. **When you’re back in flow:** removes the shield so you can use those apps again.

Optional: **Firebase** for login, user profile, and saved flow summaries/charts.

---

## High-level architecture

```
[Apple Watch] ──WatchConnectivity──► [iPhone]
[Garmin → Health] ──HealthKit────────► [iPhone] ──HTTP POST──► [Render: FastAPI]
                                                                     │
                                                                     ▼
                                                            Flow state logic
                                                            (baseline HRV, is_in_flow)
                                                                     │
[iPhone] ◄── JSON response ──────────────────────────────────────────┘
    │
    ├── is_in_flow == false  →  Notification + 5‑min timer  →  ShieldManager (lock apps)
    └── is_in_flow == true   →  Cancel timer, remove shield

[Firebase]
    ├── Auth (login)
    ├── Firestore: users/{uid}, users/{uid}/summaries  (if backend has credentials)
    └── iOS sends Bearer token to backend for protected endpoints
```

---

## Components

### Backend (Python, FastAPI) — runs on Render

- **Root directory on Render:** `backend`
- **URL:** e.g. `https://drift-hrv-backend.onrender.com`
- **Endpoints:**
  - `GET /health` — liveness check
  - `GET /test_db` — test Firestore (writes a dummy doc to `users/_test_db_connection`)
  - `POST /api/v1/hrv_stream` — receives HRV readings, returns `{ "is_in_flow": true/false, "baseline", "reason" }`. If the request includes a valid Firebase ID token, the backend can write a summary to Firestore.
  - `GET /api/v1/summaries` — returns saved summaries for the authenticated user (needs `Authorization: Bearer <Firebase ID token>`)
- **Flow state logic:** Builds a baseline from early HRV; if current HRV is steady/high → in flow; if erratic or low → not in flow.
- **Firebase:** Initialized from env `FIREBASE_CREDENTIALS_JSON` (or `GOOGLE_APPLICATION_CREDENTIALS_JSON`) on Render, or from `firebase-key.json` locally.

### iOS app (Swift/SwiftUI)

- **DriftApp.swift** — Entry point. Configures Firebase, wires:
  - **WatchConnectivityManager** (HRV from Watch) and **HealthKitManager** (HRV from Health/Garmin) → **APIClient**
  - **APIClient** → on `is_in_flow == false`: **ShieldTimerManager** (notification + 5‑min timer); on `is_in_flow == true`: cancel timer, **ShieldManager.removeShield()**
  - **ShieldTimerManager** on timer expiry → **ShieldManager.applyShield()**
- **APIClient** — `baseURL` must point to your Render backend (e.g. `https://drift-hrv-backend.onrender.com`). Sends Firebase ID token when available via `authTokenProvider`.
- **FirebaseManager** — `FirebaseApp.configure()`, sign-in/sign-out, `getIdToken()`, Firestore helpers for user and summaries. Compiles with or without Firebase SDK via `#if canImport(FirebaseCore)`.
- **ShieldManager** — Family Controls / ManagedSettings: applies or removes shield on a set of app tokens (user authorizes once in the system Screen Time UI).
- **ShieldTimerManager** — 5‑minute countdown; triggers Time-Sensitive notification when drift is detected; on expiry calls `ShieldManager.applyShield()`.
- **UI:** ContentView → WelcomeView (navy animated background + Start) → MainTabView (Flow, Lock, Insight). Flow shows felt-time, timeline visualization, and insights; Lock and Insight use the same dark navy shell.

### Watch app (watchOS)

- **HealthKitManager** — Requests HR/HRV, runs a mindfulness workout so HRV is sampled in the background; on each new sample builds **HRVPayload** and sends via **WatchConnectivityManager**.
- **WatchConnectivityManager** — Sends HRV payloads to the iPhone app.

### Garmin

- No Garmin API on the backend for the current flow. Garmin data reaches the app by syncing **Garmin Connect → Apple Health**. The iOS app’s **HealthKitManager** reads HR/HRV from Health (same as for Watch data) and sends it to the same backend.

---

## What you need to set

- **iOS:** In code or config, set `APIClient.shared.baseURL` to your Render URL, e.g. `https://drift-hrv-backend.onrender.com`.
- **Render:** Environment variable `FIREBASE_CREDENTIALS_JSON` = full contents of your Firebase service account JSON (for Firestore and optional auth).
- **Firebase:** iOS app needs `GoogleService-Info.plist` and Firebase SDK (Auth + Firestore) for login and summaries; keep the plist out of Git.

---

## Docs in this repo

- **README.md** — Quick start, structure, backend URL, Garmin note.
- **docs/ENTITLEMENTS.md** — Capabilities and Info.plist (HealthKit, Time-Sensitive Notifications, Family Controls, Sign in with Apple).
- **docs/SETUP.md** — Step-by-step GitHub → Render → Firebase (Phases A–F).
- **docs/FIREBASE_SETUP_CHECKLIST.md** — Local `firebase-key.json` and Render env var.
- **backend/README.md** — Deploy backend to Render, Firebase env.

# Drift — ADHD Cognitive-Assistance App

An ADHD cognitive-assistance app that uses HRV data (from Apple Watch or Garmin via Apple Health) to infer flow state, warns when focus is drifting, and optionally locks distracting apps via Screen Time (Family Controls).

## Architecture

- **watchOS**: HealthKit (HR/HRV) + WatchConnectivity to stream data to iPhone.
- **iOS**: Receives HRV from Watch **or** reads HR/HRV from Apple Health (e.g. Garmin Connect → Health). Posts to backend, triggers Time-Sensitive notification and 5-minute timer; applies ManagedSettings shield when timer expires and flow state is still low.
- **Backend (FastAPI)**: `POST /api/v1/hrv_stream` computes baseline HRV and returns `is_in_flow` (true/false).

## Repository Structure

- `ios/` — Xcode project (iOS app + Watch app targets).
- `backend/` — Python FastAPI app and flow-state logic.
- `docs/` — Entitlements and setup notes.
- `firebase/` — Placeholder for Firebase config (do not commit secrets).

## Setup

### Backend

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate   # Windows
pip install -r requirements.txt
cp .env.example .env     # Edit with your config
uvicorn app.main:app --reload
```

### Backend URL (optional public host)

You do **not** need a Render (or other public) URL for development.

- **Simulator**: Run the backend locally and set `APIClient.shared.baseURL` to `http://localhost:8000`.
- **Physical iPhone**: Use your Mac's LAN IP (e.g. `http://192.168.1.x:8000`). Set `baseURL` in the app.
- **Public URL**: Only when the phone can't reach your machine (e.g. cellular). Deploy to Render and set `baseURL` to that URL. See `backend/README.md` and `render.yaml`.

### iOS

1. Open `ios/Drift.xcodeproj` in Xcode.
2. Add capabilities: HealthKit (Watch and iOS if using Garmin/Health), Background Modes — Workout (Watch), Time-Sensitive Notifications (iOS), Family Controls (iOS).
3. See `docs/ENTITLEMENTS.md` for Info.plist keys and steps.
4. Set the backend base URL (localhost/LAN IP for dev, or Render URL when deployed).

### Garmin watch users

Install Garmin Connect, enable Health / Apple Health sharing so HR and HRV sync to Apple Health. Drift will read that data from HealthKit on the iPhone.

### Deploy (Render, optional)

See `backend/README.md` or `render.yaml` for Render Web Service setup.

**When is Render for?** Render is for **deploying** your Python backend so it has a **public URL**. The iOS app sends HRV to that backend. For development you run the backend on your Mac (localhost/LAN) and don't need Render. Use Render when the phone can't reach your Mac (e.g. cellular, other network, or testers need a stable URL): deploy the backend to Render and set the app's `baseURL` to that URL. So Render = optional hosting for the backend when you need it reachable from the internet; it's not for running the app itself.

## Push to GitHub

To connect this repo to your GitHub repository and push, see [docs/GITHUB.md](docs/GITHUB.md).

## License

Proprietary / your choice.

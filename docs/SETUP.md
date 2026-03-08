# Drift: GitHub, Render, and Firebase Setup Guide

Step-by-step guide to get the Drift backend on Render, Firebase Auth and Firestore for login and saved summaries, and the iOS app connected end-to-end.

---

## Phase A: GitHub

1. Open a terminal in your project root (e.g. `c:\Users\wildk\...\Drift`).
2. Run `git status`. If it says "not a git repository", run `git init`.
3. Add your GitHub repo:
   - `git remote add origin https://github.com/haminxx/Drift.git`
   - Or `git remote set-url origin https://github.com/haminxx/Drift.git` if `origin` already exists.
4. Run:
   - `git add .`
   - `git commit -m "Your message"`
   - `git branch -M main`
   - `git push -u origin main`
5. If GitHub already has commits (e.g. a README), run `git pull origin main --rebase` then `git push -u origin main`.

---

## Phase B: Render

1. Sign in at [render.com](https://render.com) with GitHub.
2. **New** → **Web Service** → connect the **Drift** repository.
3. Configure:
   - **Name**: `drift-backend` (or any name; this becomes part of the URL).
   - **Region**: Choose one close to you or your users.
   - **Branch**: `main`.
   - **Root Directory**: `backend` (important — build and start run inside the backend folder).
   - **Runtime**: **Python 3**.
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
   - **Plan**: Free (or paid; free tier spins down after inactivity).
4. **Environment**: Render sets `PORT` automatically. Do not add `PORT` manually. For Firebase (Phase E), you will add `GOOGLE_APPLICATION_CREDENTIALS_JSON` later.
5. Click **Create Web Service**. Wait until the deploy shows **Live**.
6. Note the URL (e.g. `https://drift-backend.onrender.com`). Use this in the iOS app as `APIClient.shared.baseURL`.

**Optional — Blueprint:** Use **New** → **Blueprint** and point at the repo; Render can create the service from `render.yaml` (root directory and build/start commands are already set).

---

## Phase C: Firebase project and Auth

1. Go to [Firebase Console](https://console.firebase.google.com) → **Create project** (e.g. "Drift"). Enable or disable Google Analytics as you prefer.
2. **Build** → **Authentication** → **Get started** → enable **Email/Password** (and **Apple** if you want Sign in with Apple on iOS).
3. **Build** → **Firestore Database** → **Create database** → start in **test mode** for development (restrict rules before production). Choose a region.

---

## Phase D: Firebase iOS app

1. In Firebase: **Project Settings** (gear) → **Your apps** → **Add app** → **iOS**.
2. Enter your app’s **bundle ID** (from Xcode). Register the app.
3. Download **GoogleService-Info.plist**. In Xcode, drag it into the Drift app target (check "Copy items if needed"). Ensure it is listed under the app target. Keep **GoogleService-Info.plist** in `.gitignore` — do not commit it.
4. Add the Firebase iOS SDK:
   - Xcode → **File** → **Add Package Dependencies**.
   - URL: `https://github.com/firebase/firebase-ios-sdk`
   - Add **FirebaseAuth** and **FirebaseFirestore** to the Drift (iOS) target.
5. The app already calls `FirebaseApp.configure()` in `DriftApp` init and uses `FirebaseManager` for Auth and Firestore; ensure the package and plist are in place so the SDK is linked.

---

## Phase E: Firebase Admin on the backend

1. Firebase Console → **Project Settings** → **Service accounts** → **Generate new private key**. Save the JSON file securely.
2. Open the JSON file and copy its **entire contents**.
3. In Render: open your **drift-backend** service → **Environment** → **Add environment variable**:
   - Key: `GOOGLE_APPLICATION_CREDENTIALS_JSON`
   - Value: paste the JSON. Mark as **secret** if available.
4. Redeploy the service so the backend picks up the variable. The backend reads this env var and initializes the Firebase Admin SDK to verify tokens and read/write Firestore. Do not commit the JSON file to the repo.

---

## Phase F: Connect everything

- **iOS → Backend**: Set `APIClient.shared.baseURL` to your Render URL (e.g. `https://drift-backend.onrender.com`). The app sends the Firebase ID token in `Authorization: Bearer <token>` for requests when the user is signed in (handled by `FirebaseManager` and `APIClient.authTokenProvider`).
- **iOS → Firebase**: Use Firebase Auth for login/sign-out; use Firestore (via `FirebaseManager.fetchSummaries` / `setUserProfile`) to read and write `users/{uid}` and `users/{uid}/summaries` for profile and chart data.
- **Backend → Firebase**: The backend uses the Admin SDK to verify Auth tokens and read/write Firestore (e.g. when the app sends HRV data with a token, the backend can update `users/{uid}/summaries`).

---

## Firestore structure (reference)

- **users/{uid}** — One document per user: `email`, `displayName`, `createdAt`, optional `garminLinked`, `appleHealthEnabled`.
- **users/{uid}/summaries/{summaryId}** — Daily or session summaries: `date`, `flowPercent`, `driftPercent`, `avgHRV`, `interventionCount`, `createdAt`.
- **users/{uid}/settings** — Optional: theme, notifications, shield app list.

---

## Links

- [Render](https://render.com)
- [Firebase Console](https://console.firebase.google.com)
- [Firebase iOS SDK](https://github.com/firebase/firebase-ios-sdk)
- Backend README: [backend/README.md](../backend/README.md)
- Entitlements and plist: [ENTITLEMENTS.md](ENTITLEMENTS.md)

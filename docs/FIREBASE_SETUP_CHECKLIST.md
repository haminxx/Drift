# Firebase Admin SDK — Human Checklist

Use this after setting up the backend so Firebase works **locally (Windows)** and on **Render**.

---

## Local Windows (development)

1. **Get your service account key**
   - Firebase Console → Project Settings → Service accounts → **Generate new private key** → Save the JSON file (e.g. `drift-85liez-firebase-adminsdk-fbsvc-aaa7855f84.json`).

2. **Put it where the backend can read it**
   - Copy or rename the downloaded file to **`firebase-key.json`**.
   - Place `firebase-key.json` in the **backend** folder:  
     `c:\Users\wildk\OneDrive\Important files\Project Source\App Development\Drift\backend\firebase-key.json`  
   - Or place it in the folder from which you run `uvicorn` (current working directory).

3. **Confirm it’s ignored by Git**
   - Do **not** commit `firebase-key.json`. It is listed in `.gitignore` as `firebase-key.json` and `*firebase*adminsdk*.json`. Run `git status` and ensure `firebase-key.json` does not appear.

4. **Test**
   - From the **backend** folder run: `uvicorn app.main:app --reload`
   - Open: `http://localhost:8000/test_db`  
   - You should see: `{"success": true, "message": "Firestore connection OK. ..."}`

---

## Render (production)

1. **Get the same JSON**
   - Use the same Firebase service account key file (or generate a new one and use that). Open the `.json` file in a text editor.

2. **Copy the entire contents**
   - Select **all** the text in the file (one JSON object). Copy to clipboard.

3. **Paste into Render**
   - Go to [Render Dashboard](https://dashboard.render.com).
   - Open your **Web Service** (e.g. `drift-hrv-backend`).
   - Go to **Environment**.
   - Click **Add Environment Variable**.
   - **Key:** `FIREBASE_CREDENTIALS_JSON`  
     (Alternatively you can use `GOOGLE_APPLICATION_CREDENTIALS_JSON`; both are supported.)
   - **Value:** Paste the **entire** JSON (one line or pretty-printed both work).
   - If Render offers **Secret** or **Encrypt**, enable it for this variable.
   - Save.

4. **Redeploy**
   - Trigger a **Manual Deploy** (or push to GitHub so Render auto-deploys) so the new env var is loaded.

5. **Test**
   - Open: `https://drift-hrv-backend.onrender.com/test_db`  
   - You should see: `{"success": true, "message": "Firestore connection OK. ..."}`

---

## If `/test_db` returns success: false

- **Local:** Check that `firebase-key.json` is in `backend/` (or your uvicorn cwd) and is valid JSON.
- **Render:** Check that the env var key is exactly `FIREBASE_CREDENTIALS_JSON` (or `GOOGLE_APPLICATION_CREDENTIALS_JSON`) and the value is the full JSON with no extra characters or truncation.
- **Both:** In Firebase Console → Firestore, ensure the database exists and (for test mode) that rules allow the service account to write. The test writes to `users/_test_db_connection`; you can delete that document after verifying.

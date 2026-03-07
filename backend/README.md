# Deploy Drift backend to Render

1. **Render account**: Sign up at [render.com](https://render.com).

2. **New Web Service**: Dashboard → New → Web Service. Connect your GitHub repo (Drift).

3. **Settings**:
   - **Root Directory**: `backend` (so Render runs from the backend folder).
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
   - **Plan**: Free (or paid to avoid spin-down).

4. **Environment**: Render sets `PORT` automatically. Add any optional vars (e.g. Firebase) in the Render dashboard.

5. **Deploy**: After the first deploy, note the URL (e.g. `https://drift-backend.onrender.com`). Set this as the backend base URL in the iOS app (e.g. `APIClient.shared.baseURL` or a config plist).

6. **Optional**: Use the `render.yaml` in the repo root as a Blueprint (Render → New → Blueprint) to create the service from spec.

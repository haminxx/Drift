"""FastAPI app: CORS, router mount. Optional Firebase Admin init when configured."""
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1 import hrv as hrv_router
from app.api.v1 import summaries as summaries_router
from app.core.firebase import init_firebase_if_configured, get_firebase_app


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_firebase_if_configured()
    yield


app = FastAPI(
    title="Drift Backend",
    description="HRV flow-state API for Drift ADHD app",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(hrv_router.router, prefix="/api/v1")
app.include_router(summaries_router.router, prefix="/api/v1")

@app.get("/health")
def health() -> dict:
    return {"status": "ok"}


@app.get("/test_db")
def test_db() -> dict:
    """
    Test Firestore connection: write a dummy document to the users collection.
    Use this to verify Firebase Admin is configured (env var on Render or firebase-key.json locally).
    """
    from datetime import datetime, timezone
    app_fb = get_firebase_app()
    if not app_fb:
        return {
            "success": False,
            "message": "Firebase not configured. Set FIREBASE_CREDENTIALS_JSON (Render) or add firebase-key.json (local).",
        }
    try:
        from firebase_admin import firestore
        db = firestore.client()
        doc_ref = db.collection("users").document("_test_db_connection")
        doc_ref.set({
            "message": "Drift backend test write",
            "timestamp": datetime.now(tz=timezone.utc).isoformat(),
        })
        return {"success": True, "message": "Firestore connection OK. Dummy document written to users/_test_db_connection."}
    except Exception as e:
        return {"success": False, "message": f"Firestore error: {e!s}"}

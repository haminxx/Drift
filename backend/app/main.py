"""FastAPI app: CORS, router mount. Optional Firebase Admin init when configured."""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1 import hrv as hrv_router

app = FastAPI(
    title="Drift Backend",
    description="HRV flow-state API for Drift ADHD app",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(hrv_router.router, prefix="/api/v1")

@app.get("/health")
def health() -> dict:
    return {"status": "ok"}

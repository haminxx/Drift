"""HRV stream API: POST /api/v1/hrv_stream."""
from fastapi import APIRouter, Depends
from app.models.hrv_schema import HRVStreamRequest, FlowStateResponse
from app.core.flow_state import compute_flow_state, get_or_create_session_state, SessionState
from app.core.auth import verify_firebase_token
from app.core.firestore_helpers import save_summary
from datetime import datetime

router = APIRouter(prefix="/hrv_stream", tags=["hrv"])

# In-memory session store (use Redis or Firestore per session_id for production/multi-instance)
_session_store: dict[str, SessionState] = {}


@router.post("", response_model=FlowStateResponse)
def post_hrv_stream(
    body: HRVStreamRequest,
    uid: str | None = Depends(verify_firebase_token),
) -> FlowStateResponse:
    """
    Receive HRV stream from the iPhone; return whether the user is in flow.
    If Authorization: Bearer <Firebase ID token> is present and valid, optional summary is written to Firestore for the user.
    """
    hrv_values = [r.hrv_sdnn for r in body.readings]
    if not hrv_values:
        return FlowStateResponse(is_in_flow=True, reason="no_readings")

    session_state = get_or_create_session_state(body.session_id, _session_store)
    is_in_flow, baseline, current_mean, reason = compute_flow_state(hrv_values, session_state)

    if uid and body.readings:
        avg_hrv = sum(hrv_values) / len(hrv_values) if hrv_values else None
        flow_pct = 1.0 if is_in_flow else 0.0
        summary_id = body.session_id or datetime.utcnow().strftime("%Y-%m-%d-%H%M")
        save_summary(
            uid,
            summary_id,
            date=datetime.utcnow().strftime("%Y-%m-%d"),
            flow_percent=flow_pct,
            drift_percent=1.0 - flow_pct,
            avg_hrv=avg_hrv,
            intervention_count=0,
        )

    return FlowStateResponse(
        is_in_flow=is_in_flow,
        baseline=baseline,
        reason=reason,
    )

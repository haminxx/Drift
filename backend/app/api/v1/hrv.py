"""HRV stream API: POST /api/v1/hrv_stream."""
from fastapi import APIRouter
from app.models.hrv_schema import HRVStreamRequest, FlowStateResponse
from app.core.flow_state import compute_flow_state, get_or_create_session_state, SessionState

router = APIRouter(prefix="/hrv_stream", tags=["hrv"])

# In-memory session store (use Redis or Firestore per session_id for production/multi-instance)
_session_store: dict[str, SessionState] = {}


@router.post("", response_model=FlowStateResponse)
def post_hrv_stream(body: HRVStreamRequest) -> FlowStateResponse:
    """
    Receive HRV stream from the iPhone; return whether the user is in flow.
    """
    hrv_values = [r.hrv_sdnn for r in body.readings]
    if not hrv_values:
        return FlowStateResponse(is_in_flow=True, reason="no_readings")

    session_state = get_or_create_session_state(body.session_id, _session_store)
    is_in_flow, baseline, current_mean, reason = compute_flow_state(hrv_values, session_state)

    return FlowStateResponse(
        is_in_flow=is_in_flow,
        baseline=baseline,
        reason=reason,
    )

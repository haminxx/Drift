"""
Flow state logic: baseline HRV + is_in_flow decision.

- Baseline: rolling mean (and optional std) over initial window (e.g. first N minutes or K samples).
- Steady/high: current window HRV within band of baseline or above threshold → is_in_flow = True.
- Erratic or below baseline: high variance or drop below (baseline - threshold) → is_in_flow = False.
"""
from collections import deque
from dataclasses import dataclass, field
from typing import Optional

# Defaults: tune for your use case
BASELINE_WINDOW_SIZE = 60  # number of samples to establish baseline
CURRENT_WINDOW_SIZE = 24   # ~1–2 min at 1 sample every 5s
DROP_THRESHOLD_RATIO = 0.70   # below baseline * this → distracted
VARIANCE_RATIO_HIGH = 2.0     # current variance > baseline_variance * this → erratic


@dataclass
class SessionState:
    """Per-session state for baseline and current window."""
    baseline_samples: deque = field(default_factory=lambda: deque(maxlen=BASELINE_WINDOW_SIZE))
    current_samples: deque = field(default_factory=lambda: deque(maxlen=CURRENT_WINDOW_SIZE))
    baseline_mean: Optional[float] = None
    baseline_std: Optional[float] = None


def _mean(samples: deque) -> float:
    if not samples:
        return 0.0
    return sum(samples) / len(samples)


def _std(samples: deque, mean_val: Optional[float] = None) -> float:
    if len(samples) < 2:
        return 0.0
    m = mean_val if mean_val is not None else _mean(samples)
    variance = sum((x - m) ** 2 for x in samples) / (len(samples) - 1)
    return variance ** 0.5


def compute_flow_state(
    hrv_values: list[float],
    session_state: Optional[SessionState] = None,
) -> tuple[bool, Optional[float], Optional[float], str]:
    """
    Compute is_in_flow from a list of HRV (SDNN) values for this request.

    Uses in-memory session_state if provided (keyed by session_id on the caller side).
    Returns (is_in_flow, baseline_used, current_mean, reason).
    """
    state = session_state or SessionState()

    for v in hrv_values:
        state.baseline_samples.append(v)
        state.current_samples.append(v)

    # Establish baseline from initial window
    if state.baseline_mean is None and len(state.baseline_samples) >= min(10, BASELINE_WINDOW_SIZE):
        state.baseline_mean = _mean(state.baseline_samples)
        state.baseline_std = _std(state.baseline_samples)

    # Keep baseline updated only until we have a full baseline window (then freeze)
    if state.baseline_mean is not None and len(state.baseline_samples) < BASELINE_WINDOW_SIZE:
        state.baseline_mean = _mean(state.baseline_samples)
        state.baseline_std = _std(state.baseline_samples)

    if state.baseline_mean is None or state.baseline_mean <= 0:
        return True, None, _mean(state.current_samples) if state.current_samples else None, "no_baseline_yet"

    current_mean = _mean(state.current_samples) if state.current_samples else state.baseline_mean
    current_std = _std(state.current_samples, current_mean)

    # Erratic: variance in current window much higher than baseline (or baseline is 0 and current has variance)
    if state.baseline_std is not None and state.baseline_std > 0:
        if current_std > state.baseline_std * VARIANCE_RATIO_HIGH:
            return False, state.baseline_mean, current_mean, "erratic_hrv"
    elif current_std > 0:
        # Baseline had zero variance (steady); any variance in current is erratic
        return False, state.baseline_mean, current_mean, "erratic_hrv"

    # Drop: current mean significantly below baseline
    if current_mean < state.baseline_mean * DROP_THRESHOLD_RATIO:
        return False, state.baseline_mean, current_mean, "below_baseline"

    return True, state.baseline_mean, current_mean, "steady"


def get_or_create_session_state(session_id: Optional[str], store: dict) -> Optional[SessionState]:
    """Get or create SessionState for a session_id. store is a dict you pass in (e.g. in-memory or backed by Redis)."""
    if not session_id:
        return None
    if session_id not in store:
        store[session_id] = SessionState()
    return store[session_id]

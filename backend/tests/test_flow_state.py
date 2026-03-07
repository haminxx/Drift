"""Tests for flow state logic."""
import pytest
from app.core.flow_state import (
    compute_flow_state,
    SessionState,
    BASELINE_WINDOW_SIZE,
    DROP_THRESHOLD_RATIO,
)


def test_no_baseline_yet_returns_in_flow():
    """Few samples → no baseline yet → is_in_flow True."""
    vals = [50.0, 52.0, 48.0]
    is_in_flow, baseline, _, reason = compute_flow_state(vals)
    assert is_in_flow is True
    assert reason == "no_baseline_yet"


def test_steady_hrv_returns_in_flow():
    """Steady values near baseline → is_in_flow True."""
    baseline_vals = [60.0] * 20
    current_vals = [58.0, 62.0, 59.0, 61.0]
    state = SessionState()
    is_in_flow, baseline, _, reason = compute_flow_state(baseline_vals + current_vals, state)
    assert is_in_flow is True
    assert baseline is not None
    assert "steady" in reason or "no_baseline" in reason


def test_below_baseline_returns_not_in_flow():
    """Values dropping well below baseline → is_in_flow False."""
    from app.core.flow_state import CURRENT_WINDOW_SIZE
    state = SessionState()
    establish = [60.0] * 30
    compute_flow_state(establish, state)
    # Fill current window with low values so mean drops below 70% of baseline (42)
    low_vals = [30.0] * (CURRENT_WINDOW_SIZE + 1)
    is_in_flow, _, _, reason = compute_flow_state(low_vals, state)
    assert is_in_flow is False
    assert "below_baseline" in reason


def test_erratic_hrv_returns_not_in_flow():
    """High variance in current window → is_in_flow False."""
    state = SessionState()
    # Fill baseline window with steady 50s so baseline is frozen with std=0
    establish = [50.0] * BASELINE_WINDOW_SIZE
    compute_flow_state(establish, state)
    # Now add high-variance values; baseline stays frozen, current window has high std
    erratic = [10.0, 90.0] * 12  # 24 values, mean 50, high variance
    is_in_flow, _, _, reason = compute_flow_state(erratic, state)
    assert is_in_flow is False
    assert "erratic" in reason

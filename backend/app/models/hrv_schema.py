"""Pydantic request/response models for HRV stream and flow state."""
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class HRVReading(BaseModel):
    """Single HRV sample (and optional heart rate)."""
    timestamp: str = Field(..., description="ISO8601 or Unix timestamp string")
    hrv_sdnn: float = Field(..., description="HRV SDNN in milliseconds")
    heart_rate: Optional[float] = Field(None, description="Heart rate in bpm")


class HRVStreamRequest(BaseModel):
    """Request body for POST /api/v1/hrv_stream."""
    readings: list[HRVReading] = Field(..., min_length=1)
    device_id: Optional[str] = None
    session_id: Optional[str] = None


class FlowStateResponse(BaseModel):
    """Response: whether the user is in flow (steady/high HRV) or distracted (erratic/low)."""
    is_in_flow: bool = Field(..., description="True if HRV is steady/high; false if erratic or below baseline")
    baseline: Optional[float] = Field(None, description="Current baseline HRV (ms) for debugging")
    reason: Optional[str] = Field(None, description="Short reason for debugging")

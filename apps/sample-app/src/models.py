from pydantic import BaseModel
from typing import List, Optional

class PredictRequest(BaseModel):
    features: List[float]
    model_version: Optional[str] = "v1.0.0"

class PredictResponse(BaseModel):
    prediction: float
    confidence: float
    model_version: str
    request_id: str

class HealthResponse(BaseModel):
    status: str
    version: str
    uptime_seconds: float

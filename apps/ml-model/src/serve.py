import os, json, time, uuid, logging
import joblib, numpy as np
from fastapi import FastAPI, HTTPException
from fastapi.responses import PlainTextResponse
from pydantic import BaseModel
from typing import List, Optional
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

BASE      = os.path.dirname(__file__)
MODEL_PATH = os.path.join(BASE, "..", "models", "model.joblib")
META_PATH  = os.path.join(BASE, "..", "models", "metadata.json")
APP_VERSION = os.getenv("APP_VERSION", "1.0.0")
START_TIME  = time.time()

try:
    model    = joblib.load(MODEL_PATH)
    metadata = json.load(open(META_PATH))
    logger.info("Model loaded  version=%s  accuracy=%.4f",
                metadata["model_version"], metadata["accuracy"])
except FileNotFoundError:
    model    = None
    metadata = {"model_version": "not-trained", "n_features": 10, "accuracy": 0.0}
    logger.warning("Model not found — run train.py first")

PRED_COUNT   = Counter("ml_model_predictions_total", "Predictions", ["label"])
PRED_LATENCY = Histogram("ml_model_prediction_seconds", "Latency")
MODEL_ACC    = Gauge("ml_model_accuracy", "Training accuracy")
DRIFT_SCORE  = Gauge("ml_model_drift_score", "Drift score")
MODEL_ACC.set(metadata.get("accuracy", 0))

class PredictRequest(BaseModel):
    features: List[float]
    request_id: Optional[str] = None

class PredictResponse(BaseModel):
    prediction: int
    probability: List[float]
    model_version: str
    request_id: str
    latency_ms: float

app = FastAPI(title="ML Model Service",
              description="scikit-learn RandomForest inference + drift detection",
              version=APP_VERSION)

@app.get("/health", tags=["ops"])
def health():
    return {"status": "ok", "model_loaded": model is not None,
            "model_version": metadata.get("model_version"),
            "accuracy": metadata.get("accuracy"),
            "uptime_seconds": round(time.time() - START_TIME, 2)}

@app.post("/predict", response_model=PredictResponse, tags=["ml"])
def predict(req: PredictRequest):
    if model is None:
        raise HTTPException(503, "Model not loaded")
    n = metadata.get("n_features", 10)
    if len(req.features) != n:
        raise HTTPException(422, f"Expected {n} features, got {len(req.features)}")
    t0 = time.time()
    X     = np.array(req.features).reshape(1, -1)
    pred  = int(model.predict(X)[0])
    proba = model.predict_proba(X)[0].tolist()
    ms    = round((time.time() - t0) * 1000, 2)
    PRED_COUNT.labels(label=str(pred)).inc()
    logger.info("pred=%d proba=%s latency_ms=%.2f", pred, proba, ms)
    return PredictResponse(prediction=pred,
                           probability=[round(p, 4) for p in proba],
                           model_version=metadata.get("model_version", APP_VERSION),
                           request_id=req.request_id or str(uuid.uuid4()),
                           latency_ms=ms)

@app.get("/drift", tags=["ml"])
def drift():
    score = DRIFT_SCORE._value.get()
    return {"drift_score": round(score, 4), "threshold": 0.25,
            "drifted": score > 0.25, "status": "drifted" if score > 0.25 else "healthy"}

@app.get("/metrics", response_class=PlainTextResponse, tags=["ops"])
def metrics():
    return PlainTextResponse(generate_latest().decode(), media_type=CONTENT_TYPE_LATEST)

@app.get("/", tags=["ops"])
def root():
    return {"service": "ml-model", "version": APP_VERSION, "docs": "/docs"}

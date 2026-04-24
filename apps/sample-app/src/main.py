import time, uuid, os, logging
from fastapi import FastAPI, Request
from fastapi.responses import PlainTextResponse
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from .models import PredictRequest, PredictResponse, HealthResponse

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

REQUEST_COUNT   = Counter("sample_app_requests_total", "Total requests", ["method", "endpoint", "status"])
REQUEST_LATENCY = Histogram("sample_app_request_duration_seconds", "Request latency", ["endpoint"])
PREDICTION_COUNT = Counter("sample_app_predictions_total", "Total predictions")

APP_VERSION = os.getenv("APP_VERSION", "1.0.0")
START_TIME  = time.time()

app = FastAPI(title="Sample App",
              description="Vertex AI GitOps Platform — Sample FastAPI Service",
              version=APP_VERSION)

@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    start = time.time()
    response = await call_next(request)
    REQUEST_COUNT.labels(method=request.method,
                         endpoint=request.url.path,
                         status=response.status_code).inc()
    REQUEST_LATENCY.labels(endpoint=request.url.path).observe(time.time() - start)
    return response

@app.get("/health", response_model=HealthResponse, tags=["ops"])
def health():
    return HealthResponse(status="ok", version=APP_VERSION,
                          uptime_seconds=round(time.time() - START_TIME, 2))

@app.post("/predict", response_model=PredictResponse, tags=["ml"])
def predict(req: PredictRequest):
    PREDICTION_COUNT.inc()
    score      = sum(req.features) / max(len(req.features), 1)
    confidence = min(abs(score) / 10.0, 1.0)
    logger.info("prediction=%.4f confidence=%.4f", score, confidence)
    return PredictResponse(prediction=round(score, 4),
                           confidence=round(confidence, 4),
                           model_version=req.model_version or APP_VERSION,
                           request_id=str(uuid.uuid4()))

@app.get("/metrics", response_class=PlainTextResponse, tags=["ops"])
def metrics():
    return PlainTextResponse(generate_latest().decode(), media_type=CONTENT_TYPE_LATEST)

@app.get("/", tags=["ops"])
def root():
    return {"service": "sample-app", "version": APP_VERSION, "docs": "/docs"}

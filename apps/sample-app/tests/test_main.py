from fastapi.testclient import TestClient
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from src.main import app

client = TestClient(app)


def test_health():
    r = client.get("/health")
    assert r.status_code == 200
    body = r.json()
    assert body["status"] == "ok"
    assert "version" in body


def test_predict_basic():
    r = client.post("/predict", json={"features": [1.0, 2.0, 3.0]})
    assert r.status_code == 200
    body = r.json()
    assert "prediction" in body
    assert "confidence" in body
    assert "request_id" in body


def test_predict_single_feature():
    r = client.post("/predict", json={"features": [5.0]})
    assert r.status_code == 200
    assert r.json()["prediction"] == 5.0


def test_metrics_endpoint():
    r = client.get("/metrics")
    assert r.status_code == 200
    assert "sample_app_requests_total" in r.text


def test_root():
    r = client.get("/")
    assert r.status_code == 200
    assert r.json()["service"] == "sample-app"

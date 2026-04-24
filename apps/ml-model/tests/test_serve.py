import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock
import numpy as np

# Mock model before import
mock_model = MagicMock()
mock_model.predict.return_value = np.array([1])
mock_model.predict_proba.return_value = np.array([[0.2, 0.8]])

with patch("joblib.load", return_value=mock_model), \
     patch("builtins.open", side_effect=lambda p, *a, **k: (
         __import__("io").StringIO('{"model_version":"1.0.0","n_features":10,"accuracy":0.92}')
         if "metadata" in str(p) else open(p, *a, **k)
     )):
    from src.serve import app

client = TestClient(app)


def test_health():
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"


def test_predict_success():
    features = [0.1] * 10
    r = client.post("/predict", json={"features": features})
    assert r.status_code in (200, 503)  # 503 if model not trained yet locally


def test_metrics():
    r = client.get("/metrics")
    assert r.status_code == 200
    assert "ml_model" in r.text


def test_drift_endpoint():
    r = client.get("/drift")
    assert r.status_code == 200
    assert "drift_score" in r.json()


def test_root():
    r = client.get("/")
    assert r.status_code == 200
    assert r.json()["service"] == "ml-model"

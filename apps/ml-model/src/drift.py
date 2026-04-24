"""
Evidently AI drift detection job.
Compares reference training data against recent production samples.
Pushes drift score to Prometheus Pushgateway.
Run as a CronJob in Kubernetes every 15 minutes.
"""
import os
import json
import logging
import numpy as np
import pandas as pd
from sklearn.datasets import make_classification
from evidently.report import Report
from evidently.metric_preset import DataDriftPreset
from prometheus_client import CollectorRegistry, Gauge, push_to_gateway

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

PUSHGATEWAY_URL = os.getenv("PUSHGATEWAY_URL", "http://prometheus-pushgateway.monitoring:9091")
JOB_NAME = "ml_model_drift"


def generate_reference_data(n=500) -> pd.DataFrame:
    X, _ = make_classification(n_samples=n, n_features=10, random_state=42)
    cols = [f"feature_{i}" for i in range(10)]
    return pd.DataFrame(X, columns=cols)


def generate_current_data(n=200, drift=False) -> pd.DataFrame:
    """Simulate production data — add drift by shifting mean if drift=True."""
    X, _ = make_classification(n_samples=n, n_features=10, random_state=99)
    if drift:
        X += np.random.normal(loc=1.5, scale=0.5, size=X.shape)
    cols = [f"feature_{i}" for i in range(10)]
    return pd.DataFrame(X, columns=cols)


def run_drift_detection():
    logger.info("Running Evidently drift detection...")
    reference = generate_reference_data()
    current = generate_current_data(drift=os.getenv("SIMULATE_DRIFT", "false").lower() == "true")

    report = Report(metrics=[DataDriftPreset()])
    report.run(reference_data=reference, current_data=current)

    result = report.as_dict()
    drift_detected = result["metrics"][0]["result"]["dataset_drift"]
    drift_share = result["metrics"][0]["result"]["share_of_drifted_columns"]

    logger.info("drift_detected=%s drift_share=%.4f", drift_detected, drift_share)

    # Save HTML report
    report_path = f"/tmp/drift_report_{pd.Timestamp.now().strftime('%Y%m%d_%H%M%S')}.html"
    report.save_html(report_path)
    logger.info("Report saved to %s", report_path)

    # Push to Prometheus Pushgateway
    try:
        registry = CollectorRegistry()
        g = Gauge("ml_model_drift_score", "Drift share of columns", registry=registry)
        g.set(drift_share)
        push_to_gateway(PUSHGATEWAY_URL, job=JOB_NAME, registry=registry)
        logger.info("Drift score %.4f pushed to Pushgateway", drift_share)
    except Exception as e:
        logger.warning("Could not push to Pushgateway: %s", e)

    return {"drift_detected": drift_detected, "drift_share": drift_share}


if __name__ == "__main__":
    result = run_drift_detection()
    print(json.dumps(result, indent=2))

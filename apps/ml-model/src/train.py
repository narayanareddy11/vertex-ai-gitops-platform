"""
Train a simple scikit-learn model and save it as a joblib artefact.
Run: python -m apps.ml-model.src.train
"""
import os
import joblib
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.datasets import make_classification
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report

MODEL_PATH = os.path.join(os.path.dirname(__file__), "..", "models", "model.joblib")
METADATA_PATH = os.path.join(os.path.dirname(__file__), "..", "models", "metadata.json")


def train():
    print("Generating synthetic dataset...")
    X, y = make_classification(
        n_samples=2000,
        n_features=10,
        n_informative=6,
        n_redundant=2,
        random_state=42,
    )
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    print("Training RandomForestClassifier...")
    model = RandomForestClassifier(n_estimators=100, max_depth=6, random_state=42)
    model.fit(X_train, y_train)

    y_pred = model.predict(X_test)
    acc = accuracy_score(y_test, y_pred)
    print(f"Test accuracy: {acc:.4f}")
    print(classification_report(y_test, y_pred))

    os.makedirs(os.path.dirname(MODEL_PATH), exist_ok=True)
    joblib.dump(model, MODEL_PATH)
    print(f"Model saved to {MODEL_PATH}")

    import json
    metadata = {
        "model_version": "1.0.0",
        "algorithm": "RandomForestClassifier",
        "n_features": X.shape[1],
        "accuracy": round(float(acc), 4),
        "trained_at": __import__("datetime").datetime.utcnow().isoformat(),
    }
    with open(METADATA_PATH, "w") as f:
        json.dump(metadata, f, indent=2)
    print(f"Metadata saved to {METADATA_PATH}")
    return model


if __name__ == "__main__":
    train()

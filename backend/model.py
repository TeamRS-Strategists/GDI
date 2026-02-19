"""
model.py — The Brain
KNN gesture classifier with unknown-gesture detection and persistence.
"""

import os
import pickle
import logging
from typing import Dict, Optional

import numpy as np
from sklearn.neighbors import KNeighborsClassifier

logger = logging.getLogger(__name__)

# ── Constants ────────────────────────────────────────────────────────────────
MODEL_PATH = os.path.join(os.path.dirname(__file__), "gesture_model.pkl")
UNKNOWN_THRESHOLD = 0.6  # distance above which a gesture is "Unknown"


class GestureClassifier:
    """Train / predict hand gestures via K-Nearest Neighbors."""

    def __init__(self, n_neighbors: int = 5):
        self.n_neighbors = n_neighbors
        self.X_data: list[np.ndarray] = []
        self.y_data: list[str] = []
        self.model: Optional[KNeighborsClassifier] = None
        self._is_trained = False

    # ── Training ─────────────────────────────────────────────────────────

    def add_sample(self, label: str, landmarks: np.ndarray) -> None:
        """Append a normalised 63-float vector with its label."""
        self.X_data.append(landmarks)
        self.y_data.append(label)

    def train(self) -> None:
        """Fit the KNN model on accumulated samples."""
        if len(self.X_data) == 0:
            logger.warning("train() called with no data — skipping.")
            return

        n = min(self.n_neighbors, len(self.X_data))
        self.model = KNeighborsClassifier(n_neighbors=n)
        X = np.array(self.X_data)
        self.model.fit(X, self.y_data)
        self._is_trained = True
        logger.info(
            "Model trained on %d samples across %d classes.",
            len(self.X_data),
            len(set(self.y_data)),
        )

    # ── Prediction ───────────────────────────────────────────────────────

    def predict(self, landmarks: np.ndarray) -> Dict[str, object]:
        """
        Predict the gesture label.

        Returns
        -------
        {"label": str, "confidence": float}
        If the nearest-neighbor distance exceeds UNKNOWN_THRESHOLD the
        label is "Unknown".
        """
        if not self._is_trained or self.model is None:
            return {"label": "Unknown", "confidence": 0.0}

        sample = landmarks.reshape(1, -1)
        distances, _ = self.model.kneighbors(sample)
        min_dist = float(distances[0][0])

        if min_dist > UNKNOWN_THRESHOLD:
            return {"label": "Unknown", "confidence": round(min_dist, 4)}

        label = self.model.predict(sample)[0]
        # Confidence: invert distance so closer = higher, capped at 1.0
        confidence = max(0.0, min(1.0, 1.0 - min_dist))
        return {"label": label, "confidence": round(confidence, 4)}

    # ── Persistence ──────────────────────────────────────────────────────

    def save_model(self, path: str = MODEL_PATH) -> None:
        """Pickle the entire classifier state to disk."""
        payload = {
            "X_data": self.X_data,
            "y_data": self.y_data,
            "model": self.model,
            "is_trained": self._is_trained,
        }
        with open(path, "wb") as f:
            pickle.dump(payload, f)
        logger.info("Model saved to %s", path)

    def load_model(self, path: str = MODEL_PATH) -> bool:
        """
        Load a previously saved model. Returns True on success.
        """
        if not os.path.exists(path):
            logger.info("No saved model found at %s", path)
            return False

        with open(path, "rb") as f:
            payload = pickle.load(f)

        self.X_data = payload["X_data"]
        self.y_data = payload["y_data"]
        self.model = payload["model"]
        self._is_trained = payload["is_trained"]
        logger.info(
            "Model loaded from %s  (%d samples, trained=%s)",
            path,
            len(self.X_data),
            self._is_trained,
        )
        return True

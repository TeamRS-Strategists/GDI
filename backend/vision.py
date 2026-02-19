"""
vision.py — The Eyes
Handles MediaPipe hand landmark detection (Tasks API), coordinate
normalization, and skeleton drawing.
"""

import os
import cv2
import numpy as np
from typing import Optional, Tuple, List

import mediapipe as mp
from mediapipe.tasks.python import BaseOptions
from mediapipe.tasks.python.vision import (
    HandLandmarker,
    HandLandmarkerOptions,
    HandLandmarksConnections,
    RunningMode,
    drawing_utils,
)
from mediapipe.tasks.python.vision.drawing_utils import DrawingSpec

# ── Model path ───────────────────────────────────────────────────────────────
_MODEL_PATH = os.path.join(os.path.dirname(__file__), "hand_landmarker.task")


def create_hand_landmarker() -> HandLandmarker:
    """
    Create a MediaPipe HandLandmarker configured for VIDEO mode
    (synchronous per-frame detection).
    """
    options = HandLandmarkerOptions(
        base_options=BaseOptions(model_asset_path=_MODEL_PATH),
        running_mode=RunningMode.VIDEO,
        num_hands=1,
        min_hand_detection_confidence=0.7,
        min_hand_presence_confidence=0.5,
        min_tracking_confidence=0.5,
    )
    return HandLandmarker.create_from_options(options)


# ── Public API ───────────────────────────────────────────────────────────────

def process_frame(
    landmarker: HandLandmarker,
    frame: np.ndarray,
    timestamp_ms: int,
):
    """
    Run hand detection on a BGR frame.

    Parameters
    ----------
    landmarker : HandLandmarker
    frame      : BGR numpy array from OpenCV
    timestamp_ms : monotonically increasing timestamp in milliseconds

    Returns
    -------
    result : HandLandmarkerResult (may have empty .hand_landmarks)
    """
    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)
    result = landmarker.detect_for_video(mp_image, timestamp_ms)
    return result


def normalize_landmarks(landmarks) -> np.ndarray:
    """
    Normalize 21 hand landmarks to a translation-and-scale-invariant
    63-float vector.

    Steps
    -----
    1. Shift all points so Wrist (index 0) is at (0, 0, 0).
    2. Scale so the distance from Wrist → Middle-Finger MCP (index 9) = 1.0.
    3. Flatten to a 1-D array of shape (63,).

    Parameters
    ----------
    landmarks : list of NormalizedLandmark (21 items)
    """
    coords = np.array(
        [[lm.x, lm.y, lm.z] for lm in landmarks],
        dtype=np.float64,
    )  # shape (21, 3)

    # 1. Translate wrist to origin
    wrist = coords[0].copy()
    coords -= wrist

    # 2. Scale by wrist→MCP9 distance
    mcp9_dist = np.linalg.norm(coords[9])
    if mcp9_dist > 0:
        coords /= mcp9_dist

    # 3. Flatten
    return coords.flatten().astype(np.float32)  # (63,)


def draw_landmarks_on_frame(frame: np.ndarray, hand_landmarks_list) -> np.ndarray:
    """
    Draw hand skeleton overlay on the frame (in-place) and return it.

    Parameters
    ----------
    frame : BGR numpy array
    hand_landmarks_list : list of lists of NormalizedLandmark
    """
    try:
        for hand_lms in hand_landmarks_list:
            drawing_utils.draw_landmarks(
                frame,
                hand_lms,
                HandLandmarksConnections.HAND_CONNECTIONS,
                DrawingSpec(color=(0, 0, 255), thickness=2, circle_radius=2),
                DrawingSpec(color=(0, 255, 0), thickness=2, circle_radius=2),
            )
    except Exception as exc:
        import logging
        logging.getLogger(__name__).warning("draw_landmarks failed: %s", exc)
    return frame

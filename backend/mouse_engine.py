"""
mouse_engine.py — The Cursor
Deterministic, geometry-based mouse controller.
Active by default — no training required.
"""

import time
import math
import logging

import numpy as np
import pyautogui

logger = logging.getLogger(__name__)

# Prevent pyautogui fail-safe (moving mouse to corner to abort)
pyautogui.FAILSAFE = False
pyautogui.PAUSE = 0        # no artificial delay between pyautogui calls


class MouseController:
    """
    Maps the index-finger tip to the screen cursor and detects
    pinch-to-click gestures using raw hand landmarks.
    """

    def __init__(
        self,
        frame_reduction: int = 100,
        smoothening: int = 7,
        click_threshold: float = 0.05,
        click_cooldown: float = 0.5,
    ):
        """
        Parameters
        ----------
        frame_reduction : int
            Pixel margin defining the "active zone" inside the camera frame.
        smoothening : int
            Divisor for exponential smoothing (higher = smoother, slower).
        click_threshold : float
            Max normalised distance between fingertips to register a click.
        click_cooldown : float
            Minimum seconds between consecutive click events.
        """
        self.screen_width, self.screen_height = pyautogui.size()
        self.frame_reduction = frame_reduction
        self.smoothening = smoothening
        self.click_threshold = click_threshold
        self.click_cooldown = click_cooldown

        # Previous cursor position (start at screen centre)
        self.prev_x: float = self.screen_width / 2
        self.prev_y: float = self.screen_height / 2

        # Click debouncing
        self._last_left_click: float = 0.0
        self._last_right_click: float = 0.0

    # ── helpers ──────────────────────────────────────────────────────────

    @staticmethod
    def _distance(lm_a, lm_b) -> float:
        """Euclidean distance between two MediaPipe NormalizedLandmark (2-D)."""
        return math.sqrt((lm_a.x - lm_b.x) ** 2 + (lm_a.y - lm_b.y) ** 2)

    # ── main entry point ─────────────────────────────────────────────────

    def process_hand(self, landmarks) -> None:
        """
        Accepts a list of 21 NormalizedLandmark objects.

        1. Moves the cursor based on index-finger tip.
        2. Detects left-click  (thumb tip ↔ index tip pinch).
        3. Detects right-click (thumb tip ↔ middle tip pinch).
        """
        lms = landmarks  # already a list of NormalizedLandmark

        # ── 1. Cursor tracking (Landmark 8 — Index Finger Tip) ──────────
        index_x = lms[8].x   # normalised 0..1
        index_y = lms[8].y

        # Map from normalised coords to screen coords with margin
        fr = self.frame_reduction
        target_x = np.interp(
            index_x,
            (fr / self.screen_width, 1 - fr / self.screen_width),
            (0, self.screen_width),
        )
        target_y = np.interp(
            index_y,
            (fr / self.screen_height, 1 - fr / self.screen_height),
            (0, self.screen_height),
        )

        # Smooth
        curr_x = self.prev_x + (target_x - self.prev_x) / self.smoothening
        curr_y = self.prev_y + (target_y - self.prev_y) / self.smoothening

        # Move
        try:
            pyautogui.moveTo(int(curr_x), int(curr_y))
        except Exception as exc:
            logger.debug("moveTo failed: %s", exc)

        self.prev_x = curr_x
        self.prev_y = curr_y

        # ── 2. Click detection ───────────────────────────────────────────
        now = time.time()

        # Left click — Index Tip (8) ↔ Thumb Tip (4)
        dist_left = self._distance(lms[8], lms[4])
        if dist_left < self.click_threshold:
            if (now - self._last_left_click) > self.click_cooldown:
                pyautogui.click()
                self._last_left_click = now
                logger.debug("Left click (dist=%.4f)", dist_left)

        # Right click — Middle Tip (12) ↔ Thumb Tip (4)
        dist_right = self._distance(lms[12], lms[4])
        if dist_right < self.click_threshold:
            if (now - self._last_right_click) > self.click_cooldown:
                pyautogui.rightClick()
                self._last_right_click = now
                logger.debug("Right click (dist=%.4f)", dist_right)

"""
mouse_engine.py — The Cursor
Deterministic, geometry-based mouse controller.
Active by default — no training required.
"""

import time
import math
import logging
import sys

import numpy as np

logger = logging.getLogger(__name__)

# ── Platform-specific setup ──────────────────────────────────────────────
IS_MACOS = sys.platform == "darwin"

if IS_MACOS:
    import ctypes
    import ctypes.util
    
    # Load Core Graphics framework
    _cg = ctypes.CDLL(ctypes.util.find_library("CoreGraphics"))
    
    # CGPoint structure
    class CGPoint(ctypes.Structure):
        _fields_ = [("x", ctypes.c_double), ("y", ctypes.c_double)]
    
    # Function prototypes
    _cg.CGMainDisplayID.argtypes = []
    _cg.CGMainDisplayID.restype = ctypes.c_uint32
    
    _cg.CGDisplayPixelsWide.argtypes = [ctypes.c_uint32]
    _cg.CGDisplayPixelsWide.restype = ctypes.c_size_t
    
    _cg.CGDisplayPixelsHigh.argtypes = [ctypes.c_uint32]
    _cg.CGDisplayPixelsHigh.restype = ctypes.c_size_t
    
    _cg.CGEventCreateMouseEvent.argtypes = [ctypes.c_void_p, ctypes.c_uint32, CGPoint, ctypes.c_uint32]
    _cg.CGEventCreateMouseEvent.restype = ctypes.c_void_p
    
    _cg.CGEventPost.argtypes = [ctypes.c_uint32, ctypes.c_void_p]
    _cg.CGEventPost.restype = None
    
    _cg.CFRelease.argtypes = [ctypes.c_void_p]
    _cg.CFRelease.restype = None
    
    # Event types
    kCGEventMouseMoved = 5
    kCGEventLeftMouseDown = 1
    kCGEventLeftMouseUp = 2
    kCGEventRightMouseDown = 3
    kCGEventRightMouseUp = 4
    kCGMouseButtonLeft = 0
    kCGMouseButtonRight = 1
    
    class _MacMouseAPI:
        """Wrapper for macOS mouse operations using ctypes."""
        
        @staticmethod
        def size():
            """Get screen size."""
            display_id = _cg.CGMainDisplayID()
            width = _cg.CGDisplayPixelsWide(display_id)
            height = _cg.CGDisplayPixelsHigh(display_id)
            return (int(width), int(height))
        
        @staticmethod
        def moveTo(x, y):
            """Move mouse to absolute position."""
            point = CGPoint(float(x), float(y))
            event = _cg.CGEventCreateMouseEvent(None, kCGEventMouseMoved, point, 0)
            if event:
                _cg.CGEventPost(0, event)
                _cg.CFRelease(event)
        
        @staticmethod
        def click():
            """Perform left mouse click at current position."""
            # We need to get current position - use CGEventGetLocation from a new event
            # Simpler: just create events at (0,0) won't matter since we just moved there
            event_source = None
            # Create a null event to get current mouse location
            null_event = _cg.CGEventCreate(event_source)
            if null_event:
                _cg.CGEventGetLocation.argtypes = [ctypes.c_void_p]
                _cg.CGEventGetLocation.restype = CGPoint
                point = _cg.CGEventGetLocation(null_event)
                _cg.CFRelease(null_event)
            else:
                point = CGPoint(0, 0)
            
            down = _cg.CGEventCreateMouseEvent(None, kCGEventLeftMouseDown, point, kCGMouseButtonLeft)
            up = _cg.CGEventCreateMouseEvent(None, kCGEventLeftMouseUp, point, kCGMouseButtonLeft)
            if down and up:
                _cg.CGEventPost(0, down)
                _cg.CGEventPost(0, up)
                _cg.CFRelease(down)
                _cg.CFRelease(up)
        
        @staticmethod
        def rightClick():
            """Perform right mouse click at current position."""
            event_source = None
            null_event = _cg.CGEventCreate(event_source)
            if null_event:
                _cg.CGEventGetLocation.argtypes = [ctypes.c_void_p]
                _cg.CGEventGetLocation.restype = CGPoint
                point = _cg.CGEventGetLocation(null_event)
                _cg.CFRelease(null_event)
            else:
                point = CGPoint(0, 0)
            
            down = _cg.CGEventCreateMouseEvent(None, kCGEventRightMouseDown, point, kCGMouseButtonRight)
            up = _cg.CGEventCreateMouseEvent(None, kCGEventRightMouseUp, point, kCGMouseButtonRight)
            if down and up:
                _cg.CGEventPost(0, down)
                _cg.CGEventPost(0, up)
                _cg.CFRelease(down)
                _cg.CFRelease(up)
    
    # Add CGEventCreate prototype
    _cg.CGEventCreate.argtypes = [ctypes.c_void_p]
    _cg.CGEventCreate.restype = ctypes.c_void_p
    
    pyautogui = _MacMouseAPI()
    FAILSAFE = False
    PAUSE = 0
else:
    import pyautogui
    pyautogui.FAILSAFE = False
    pyautogui.PAUSE = 0


class MouseController:
    """
    Maps the index-finger tip to the screen cursor and detects
    pinch-to-click gestures using raw hand landmarks.
    """

    def __init__(
        self,
        frame_reduction: int = 100,
        smoothening: int = 3,
        click_threshold: float = 0.05,
        click_cooldown: float = 0.3,
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

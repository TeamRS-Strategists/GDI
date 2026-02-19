"""
controller.py — The Hands
Maps recognised gestures to OS-level desktop actions with debouncing.
Uses native macOS AppleScript commands via osascript for reliable media control.
Supports both preset actions and custom keyboard shortcuts.
"""

import subprocess
import sys
import time
import logging
from typing import Dict, Optional

logger = logging.getLogger(__name__)

# ── Detect platform ─────────────────────────────────────────────────────────
IS_MACOS = sys.platform == "darwin"

# ── macOS key code map for common modifier-free keys ────────────────────────
# Used by _run_keyboard_shortcut for macOS
_MAC_KEYCODE: Dict[str, int] = {
    "a": 0, "b": 11, "c": 8, "d": 2, "e": 14, "f": 3, "g": 5,
    "h": 4, "i": 34, "j": 38, "k": 40, "l": 37, "m": 46, "n": 45,
    "o": 31, "p": 35, "q": 12, "r": 15, "s": 1, "t": 17, "u": 32,
    "v": 9, "w": 13, "x": 7, "y": 16, "z": 6,
    "0": 29, "1": 18, "2": 19, "3": 20, "4": 21, "5": 23,
    "6": 22, "7": 26, "8": 28, "9": 25,
    "space": 49, "return": 36, "tab": 48, "escape": 53, "delete": 51,
    "up": 126, "down": 125, "left": 123, "right": 124,
    "f1": 122, "f2": 120, "f3": 99, "f4": 118, "f5": 96, "f6": 97,
    "f7": 98, "f8": 100, "f9": 101, "f10": 109, "f11": 103, "f12": 111,
    "[": 33, "]": 30, ";": 41, "'": 39, ",": 43, ".": 47, "/": 44,
    "-": 27, "=": 24, "`": 50, "\\": 42,
}

_MAC_MODIFIER_MAP = {
    "cmd": "command down",
    "command": "command down",
    "shift": "shift down",
    "alt": "option down",
    "option": "option down",
    "ctrl": "control down",
    "control": "control down",
}


def _run_applescript(script: str) -> bool:
    """Run an AppleScript snippet via osascript (macOS only). Returns True on success."""
    try:
        result = subprocess.run(
            ["osascript", "-e", script],
            capture_output=True,
            text=True,
            timeout=5,
        )
        if result.returncode != 0:
            logger.error("osascript failed (rc=%d): %s", result.returncode, result.stderr.strip())
            return False
        return True
    except subprocess.TimeoutExpired:
        logger.error("osascript timed out")
        return False
    except Exception as exc:
        logger.error("osascript error: %s", exc)
        return False


def _run_keyboard_shortcut(keys: str) -> bool:
    """
    Execute a custom keyboard shortcut.
    Format: "cmd+shift+a", "ctrl+c", "space", "f11", etc.
    """
    parts = [k.strip().lower() for k in keys.split("+")]

    if IS_MACOS:
        return _run_keyboard_shortcut_macos(parts)
    else:
        return _run_keyboard_shortcut_pyautogui(parts)


def _run_keyboard_shortcut_macos(parts: list[str]) -> bool:
    """Execute a keyboard shortcut on macOS via System Events."""
    modifiers = []
    key_part = None

    for p in parts:
        if p in _MAC_MODIFIER_MAP:
            modifiers.append(_MAC_MODIFIER_MAP[p])
        else:
            key_part = p

    if key_part is None:
        logger.error("No key found in shortcut: %s", "+".join(parts))
        return False

    keycode = _MAC_KEYCODE.get(key_part)
    if keycode is None:
        logger.error("Unknown key '%s' for macOS keycode", key_part)
        return False

    if modifiers:
        modifier_str = ", ".join(modifiers)
        script = f'tell application "System Events" to key code {keycode} using {{{modifier_str}}}'
    else:
        script = f'tell application "System Events" to key code {keycode}'

    return _run_applescript(script)


def _run_keyboard_shortcut_pyautogui(parts: list[str]) -> bool:
    """Execute a keyboard shortcut via pyautogui (non-macOS)."""
    try:
        import pyautogui
        pyautogui.FAILSAFE = False

        # Map modifier names to pyautogui names
        key_map = {"cmd": "command", "ctrl": "ctrl", "alt": "alt", "option": "alt"}
        mapped = [key_map.get(p, p) for p in parts]

        if len(mapped) == 1:
            pyautogui.press(mapped[0])
        else:
            pyautogui.hotkey(*mapped)
        return True
    except Exception as exc:
        logger.error("pyautogui keyboard shortcut failed: %s", exc)
        return False


def _run_action(action: str) -> bool:
    """
    Execute a desktop action by name.
    If action starts with "keyboard:", treat as custom keyboard shortcut.
    Otherwise, treat as a preset media action.
    """
    if action.startswith("keyboard:"):
        keys = action[len("keyboard:"):]
        return _run_keyboard_shortcut(keys)

    if IS_MACOS:
        return _run_action_macos(action)
    else:
        return _run_action_pyautogui(action)


def _run_action_macos(action: str) -> bool:
    """Execute preset actions using native macOS AppleScript."""
    try:
        if action == "Volume Up":
            return _run_applescript(
                "set volume output volume ((output volume of (get volume settings)) + 6.25)"
            )
        elif action == "Volume Down":
            return _run_applescript(
                "set volume output volume ((output volume of (get volume settings)) - 6.25)"
            )
        elif action == "Volume Mute":
            return _run_applescript(
                "set volume output muted (not (output muted of (get volume settings)))"
            )
        elif action == "Play/Pause":
            return _run_applescript(
                'tell application "System Events" to key code 49'
            )
        elif action == "Next Track":
            return _run_applescript(
                'tell application "System Events" to key code 124 using {command down}'
            )
        elif action == "Previous Track":
            return _run_applescript(
                'tell application "System Events" to key code 123 using {command down}'
            )
        elif action == "Screenshot":
            result = subprocess.run(["screencapture", "-c"], capture_output=True, timeout=5)
            return result.returncode == 0
        elif action == "Scroll Up":
            return _run_applescript(
                'tell application "System Events" to key code 126 using {option down}'
            )
        elif action == "Scroll Down":
            return _run_applescript(
                'tell application "System Events" to key code 125 using {option down}'
            )
        elif action == "Next Tab":
            return _run_applescript(
                'tell application "System Events" to key code 30 using {command down, shift down}'
            )
        elif action == "Previous Tab":
            return _run_applescript(
                'tell application "System Events" to key code 33 using {command down, shift down}'
            )
        else:
            logger.warning("Unknown preset action for macOS: '%s'", action)
            return False
    except Exception as exc:
        logger.error("macOS action '%s' failed: %s", action, exc)
        return False


def _run_action_pyautogui(action: str) -> bool:
    """Fallback: use pyautogui for non-macOS platforms."""
    try:
        import pyautogui
        pyautogui.FAILSAFE = False

        action_to_key = {
            "Volume Up": "volumeup",
            "Volume Down": "volumedown",
            "Volume Mute": "volumemute",
            "Play/Pause": "playpause",
            "Next Track": "nexttrack",
            "Previous Track": "prevtrack",
            "Screenshot": "printscreen",
            "Scroll Up": "pageup",
            "Scroll Down": "pagedown",
        }

        key = action_to_key.get(action)
        if key is None:
            logger.warning("No pyautogui key for action '%s'", action)
            return False

        if action == "Next Tab":
            pyautogui.hotkey("ctrl", "tab")
        elif action == "Previous Tab":
            pyautogui.hotkey("ctrl", "shift", "tab")
        else:
            pyautogui.press(key)
        return True
    except Exception as exc:
        logger.error("pyautogui action '%s' failed: %s", action, exc)
        return False


class DesktopController:
    """Execute desktop commands mapped to gesture labels."""

    def __init__(
        self,
        gesture_map: Optional[Dict[str, str]] = None,
        cooldown: float = 1.0,
    ):
        self.gesture_map = gesture_map or {}
        self.cooldown = cooldown
        self._last_action_time: Dict[str, float] = {}

        logger.info(
            "DesktopController initialized (platform=%s, gestures=%s)",
            "macOS" if IS_MACOS else "other",
            list(self.gesture_map.keys()),
        )

    def execute(self, gesture: str) -> bool:
        """Execute the desktop action for *gesture* if mapped and cooldown elapsed."""
        if gesture in ("Unknown", "None", None):
            return False

        action = self.gesture_map.get(gesture)
        if action is None:
            return False

        now = time.time()
        last = self._last_action_time.get(gesture, 0.0)
        if (now - last) < self.cooldown:
            return False

        success = _run_action(action)
        if success:
            self._last_action_time[gesture] = now
            logger.info("Action triggered: %s → %s ✓", gesture, action)
        else:
            logger.error("Action FAILED: %s → %s", gesture, action)

        return success

    def update_mapping(self, gesture: str, action: str) -> None:
        """Dynamically add or update a gesture→action binding."""
        self.gesture_map[gesture] = action
        logger.info("Mapping updated: %s → %s", gesture, action)

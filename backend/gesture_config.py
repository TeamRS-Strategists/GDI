"""
gesture_config.py — Persistent gesture configuration store.
Saves gesture→action mappings to a JSON file so they survive restarts.
"""

import json
import os
import logging
from typing import Dict, Optional

logger = logging.getLogger(__name__)

CONFIG_PATH = os.path.join(os.path.dirname(__file__), "gesture_configs.json")


class GestureConfigEntry:
    """A single gesture configuration entry."""

    def __init__(self, name: str, action_type: str, action: str, keys: str = ""):
        """
        Parameters
        ----------
        name : str
            Human-readable gesture name (e.g. "Thumbs Up").
        action_type : str
            "preset" for built-in actions, "keyboard" for custom shortcuts.
        action : str
            For preset: action name like "Volume Up".
            For keyboard: display label (can match keys).
        keys : str
            For keyboard shortcuts: key combo string like "cmd+shift+a".
            Empty for preset actions.
        """
        self.name = name
        self.action_type = action_type
        self.action = action
        self.keys = keys

    def to_dict(self) -> dict:
        return {
            "name": self.name,
            "action_type": self.action_type,
            "action": self.action,
            "keys": self.keys,
        }

    @classmethod
    def from_dict(cls, data: dict) -> "GestureConfigEntry":
        return cls(
            name=data["name"],
            action_type=data.get("action_type", "preset"),
            action=data.get("action", ""),
            keys=data.get("keys", ""),
        )


class GestureConfigStore:
    """Load/save gesture configurations from/to a JSON file."""

    def __init__(self, path: str = CONFIG_PATH):
        self.path = path
        self._configs: Dict[str, GestureConfigEntry] = {}
        self.load()

    def load(self) -> None:
        """Load configs from disk. If file doesn't exist, use defaults."""
        if not os.path.exists(self.path):
            logger.info("No gesture config file found, using defaults")
            self._load_defaults()
            self.save()  # persist defaults
            return

        try:
            with open(self.path, "r") as f:
                data = json.load(f)

            self._configs = {}
            for entry_data in data.get("gestures", []):
                entry = GestureConfigEntry.from_dict(entry_data)
                self._configs[entry.name] = entry

            logger.info(
                "Loaded %d gesture configs from %s", len(self._configs), self.path
            )
        except Exception as exc:
            logger.error("Failed to load gesture configs: %s", exc)
            self._load_defaults()

    def _load_defaults(self) -> None:
        """Set up default gesture mappings."""
        defaults = [
            GestureConfigEntry("Fist", "preset", "Volume Mute"),
            GestureConfigEntry("Open Palm", "preset", "Play/Pause"),
            GestureConfigEntry("Thumbs Up", "preset", "Volume Up"),
            GestureConfigEntry("Thumbs Down", "preset", "Volume Down"),
        ]
        self._configs = {e.name: e for e in defaults}

    def save(self) -> None:
        """Persist all configs to disk."""
        data = {"gestures": [e.to_dict() for e in self._configs.values()]}
        try:
            with open(self.path, "w") as f:
                json.dump(data, f, indent=2)
            logger.info("Saved %d gesture configs to %s", len(self._configs), self.path)
        except Exception as exc:
            logger.error("Failed to save gesture configs: %s", exc)

    def get_all(self) -> list[dict]:
        """Return all configs as a list of dicts."""
        return [e.to_dict() for e in self._configs.values()]

    def get(self, name: str) -> Optional[GestureConfigEntry]:
        """Get a single config by gesture name."""
        return self._configs.get(name)

    def upsert(self, name: str, action_type: str, action: str, keys: str = "") -> None:
        """Add or update a gesture config and persist."""
        self._configs[name] = GestureConfigEntry(name, action_type, action, keys)
        self.save()
        logger.info("Config upserted: %s → %s (%s)", name, action, action_type)

    def delete(self, name: str) -> bool:
        """Remove a gesture config. Returns True if it existed."""
        if name in self._configs:
            del self._configs[name]
            self.save()
            logger.info("Config deleted: %s", name)
            return True
        return False

    def build_gesture_map(self) -> Dict[str, str]:
        """
        Build the gesture_name → action_string map used by DesktopController.
        For preset actions: returns the action name (e.g. "Volume Up").
        For keyboard shortcuts: returns "keyboard:<keys>" (e.g. "keyboard:cmd+shift+a").
        """
        result = {}
        for name, entry in self._configs.items():
            if entry.action_type == "keyboard":
                result[name] = f"keyboard:{entry.keys}"
            else:
                result[name] = entry.action
        return result

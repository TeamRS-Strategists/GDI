"""
voice_commands.py - Voice Command Handler for GDI + OpenClaw

This module handles voice commands detected by the "Jarvis" wake word and
executes them through OpenClaw's AI assistant.

Features:
- Wake word detection via OpenClaw Voice Wake
- Natural language command processing
- Integration with GDI gesture system
- System automation via OpenClaw tools
"""

import asyncio
import json
import logging
from typing import Optional, Callable, Dict, Any, List
from dataclasses import dataclass
from datetime import datetime
from enum import Enum

logger = logging.getLogger(__name__)


class CommandStatus(Enum):
    """Status of voice command execution."""
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


@dataclass
class VoiceCommand:
    """Represents a voice command with metadata."""
    text: str
    timestamp: datetime
    session_id: str
    command_id: str
    status: CommandStatus = CommandStatus.PENDING
    response: str = ""
    tools_used: List[str] = None
    error: Optional[str] = None
    
    def __post_init__(self):
        if self.tools_used is None:
            self.tools_used = []
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for JSON serialization."""
        return {
            "text": self.text,
            "timestamp": self.timestamp.isoformat(),
            "session_id": self.session_id,
            "command_id": self.command_id,
            "status": self.status.value,
            "response": self.response,
            "tools_used": self.tools_used,
            "error": self.error
        }


class VoiceCommandHandler:
    """
    Handles voice commands with OpenClaw integration.
    
    This class manages the lifecycle of voice commands:
    1. Wake word detection
    2. Speech recognition
    3. AI processing via OpenClaw
    4. Action execution
    5. Response delivery
    """
    
    def __init__(self):
        self.commands_history: List[VoiceCommand] = []
        self.active_command: Optional[VoiceCommand] = None
        self.command_callbacks: List[Callable] = []
        self.enabled = False
        
        # Statistics
        self.total_commands = 0
        self.successful_commands = 0
        self.failed_commands = 0
    
    async def process_command(
        self,
        command_text: str,
        session_id: str = "main",
        openclaw_bridge = None
    ) -> VoiceCommand:
        """
        Process a voice command using OpenClaw AI.
        
        Args:
            command_text: The transcribed voice command
            session_id: Session identifier
            openclaw_bridge: OpenClaw bridge instance for AI execution
            
        Returns:
            VoiceCommand object with execution results
        """
        # Create command object
        command = VoiceCommand(
            text=command_text,
            timestamp=datetime.now(),
            session_id=session_id,
            command_id=f"cmd_{self.total_commands + 1}",
            status=CommandStatus.PROCESSING
        )
        
        self.active_command = command
        self.total_commands += 1
        
        logger.info(f"🎙️ Processing voice command: '{command_text}'")
        
        try:
            # Execute command through OpenClaw
            if openclaw_bridge and openclaw_bridge.connected:
                result = await openclaw_bridge.execute_command(command_text)
                
                if "error" in result:
                    command.status = CommandStatus.FAILED
                    command.error = result["error"]
                    self.failed_commands += 1
                    logger.error(f"❌ Command failed: {command.error}")
                else:
                    command.status = CommandStatus.COMPLETED
                    command.response = result.get("response", "Command executed successfully")
                    command.tools_used = result.get("tools", [])
                    self.successful_commands += 1
                    logger.info(f"✅ Command completed: {command.response}")
            else:
                # Fallback: basic command execution without OpenClaw
                command.status = CommandStatus.COMPLETED
                command.response = await self._execute_basic_command(command_text)
                self.successful_commands += 1
                logger.info(f"✅ Basic command executed: {command.response}")
        
        except Exception as e:
            command.status = CommandStatus.FAILED
            command.error = str(e)
            self.failed_commands += 1
            logger.error(f"❌ Command execution error: {e}")
        
        # Add to history
        self.commands_history.append(command)
        
        # Notify callbacks
        await self._notify_callbacks(command)
        
        self.active_command = None
        return command
    
    async def _execute_basic_command(self, command_text: str) -> str:
        """
        Execute basic commands without OpenClaw (fallback).
        
        Args:
            command_text: Command to execute
            
        Returns:
            Response message
        """
        text_lower = command_text.lower()
        
        # Basic command patterns
        if any(word in text_lower for word in ["time", "clock"]):
            from datetime import datetime
            return f"The current time is {datetime.now().strftime('%I:%M %p')}"
        
        elif any(word in text_lower for word in ["date", "day"]):
            from datetime import datetime
            return f"Today is {datetime.now().strftime('%A, %B %d, %Y')}"
        
        elif "open" in text_lower:
            # Extract app name (basic parsing)
            words = text_lower.split()
            if "open" in words:
                idx = words.index("open")
                if idx + 1 < len(words):
                    app_name = words[idx + 1]
                    import subprocess
                    try:
                        subprocess.Popen(["open", "-a", app_name.title()])
                        return f"Opening {app_name.title()}"
                    except Exception as e:
                        return f"Could not open {app_name}: {str(e)}"
        
        return f"I heard: {command_text}. OpenClaw is not connected for advanced command execution."
    
    def add_command_callback(self, callback: Callable[[VoiceCommand], None]):
        """Add a callback to be notified when commands are processed."""
        self.command_callbacks.append(callback)
    
    async def _notify_callbacks(self, command: VoiceCommand):
        """Notify all registered callbacks about command completion."""
        for callback in self.command_callbacks:
            try:
                if asyncio.iscoroutinefunction(callback):
                    await callback(command)
                else:
                    callback(command)
            except Exception as e:
                logger.error(f"Error in command callback: {e}")
    
    def get_recent_commands(self, limit: int = 10) -> List[Dict[str, Any]]:
        """Get recent command history."""
        return [cmd.to_dict() for cmd in self.commands_history[-limit:]]
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get voice command statistics."""
        return {
            "total_commands": self.total_commands,
            "successful": self.successful_commands,
            "failed": self.failed_commands,
            "success_rate": (
                round(self.successful_commands / self.total_commands * 100, 1)
                if self.total_commands > 0 else 0
            ),
            "enabled": self.enabled
        }
    
    def clear_history(self):
        """Clear command history."""
        self.commands_history.clear()


# Example command templates for common tasks
COMMAND_EXAMPLES = {
    "system": [
        "open chrome",
        "close all windows",
        "take a screenshot",
        "show desktop",
        "lock screen"
    ],
    "files": [
        "create a new folder called projects",
        "create a file named readme.md",
        "open the downloads folder",
        "find files containing python"
    ],
    "development": [
        "create a website for me",
        "create a react app",
        "create a python script",
        "start a local server",
        "open vs code"
    ],
    "gestures": [
        "add a new gesture for play pause",
        "show me all gestures",
        "delete the volume gesture",
        "enable gesture detection"
    ],
    "info": [
        "what time is it",
        "what's the date",
        "what's the weather",
        "tell me a joke"
    ]
}


def get_command_suggestions() -> Dict[str, List[str]]:
    """Get command suggestions grouped by category."""
    return COMMAND_EXAMPLES

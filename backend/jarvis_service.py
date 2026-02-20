"""
jarvis_service.py - Backend Service for Jarvis Voice Assistant

Manages the Jarvis voice process and communicates with the Flutter frontend
via WebSocket events.
"""

import asyncio
import subprocess
import json
import logging
import os
import time
from typing import Optional, Callable
from pathlib import Path

logger = logging.getLogger(__name__)


class JarvisService:
    """Service to manage Jarvis voice assistant process"""
    
    def __init__(self, broadcast_callback: Optional[Callable] = None):
        """
        Initialize Jarvis service
        
        Args:
            broadcast_callback: Function to broadcast events to WebSocket clients
        """
        self.process: Optional[asyncio.subprocess.Process] = None
        self.broadcast = broadcast_callback
        self.is_running = False
        self.current_state = "idle"  # idle, listening, processing, speaking
        self._monitor_task: Optional[asyncio.Task] = None
        self._event_seq = 0
        self._events = []
        self._max_events = 500

    def _record_event(self, event: dict):
        """Store event in memory for polling fallback."""
        self._event_seq += 1
        enriched = {
            "id": self._event_seq,
            "timestamp": time.time(),
            **event,
        }
        self._events.append(enriched)
        if len(self._events) > self._max_events:
            self._events = self._events[-self._max_events:]
        return enriched

    async def _emit_event(self, event: dict):
        """Record and broadcast a Jarvis event."""
        enriched = self._record_event(event)
        if self.broadcast:
            await self.broadcast("voice_event", enriched)

    def get_events(self, since_id: int = 0, limit: int = 200):
        """Return recent events for frontend polling fallback."""
        events = [e for e in self._events if e.get("id", 0) > since_id]
        if limit > 0:
            events = events[:limit]
        return events
        
    async def start(self):
        """Start the Jarvis voice assistant"""
        if self.is_running:
            logger.warning("Jarvis already running")
            return {"status": "already_running"}
        
        try:
            # Get the project root directory
            backend_dir = Path(__file__).parent
            project_dir = backend_dir.parent
            jarvis_script = project_dir / "jarvis_voice.py"
            venv_python = project_dir / "voice_env" / "bin" / "python"
            
            if not jarvis_script.exists():
                logger.error(f"Jarvis script not found: {jarvis_script}")
                return {"status": "error", "message": "Jarvis script not found"}
            
            if not venv_python.exists():
                logger.error(f"Virtual environment not found: {venv_python}")
                return {"status": "error", "message": "Virtual environment not found"}
            
            # Start Jarvis process
            env = os.environ.copy()
            env["PYTHONUNBUFFERED"] = "1"
            self.process = await asyncio.create_subprocess_exec(
                str(venv_python),
                "-u",
                str(jarvis_script),
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                stdin=asyncio.subprocess.PIPE,
                env=env,
            )
            
            self.is_running = True
            self.current_state = "listening"
            
            # Start monitoring the process output
            self._monitor_task = asyncio.create_task(self._monitor_output())
            
            # Broadcast start event
            await self._emit_event({
                "type": "jarvis_started",
                "state": "listening"
            })
            
            logger.info("Jarvis voice assistant started")
            return {"status": "started", "state": "listening"}
            
        except Exception as e:
            logger.error(f"Failed to start Jarvis: {e}")
            self.is_running = False
            return {"status": "error", "message": str(e)}
    
    async def stop(self):
        """Stop the Jarvis voice assistant"""
        if not self.is_running or not self.process:
            return {"status": "not_running"}
        
        try:
            # Cancel monitoring task
            if self._monitor_task:
                self._monitor_task.cancel()
                try:
                    await self._monitor_task
                except asyncio.CancelledError:
                    pass
            
            # Terminate the process
            self.process.terminate()
            try:
                await asyncio.wait_for(self.process.wait(), timeout=5.0)
            except asyncio.TimeoutError:
                self.process.kill()
                await self.process.wait()
            
            self.is_running = False
            self.current_state = "idle"
            
            # Broadcast stop event
            await self._emit_event({
                "type": "jarvis_stopped",
                "state": "idle"
            })
            
            logger.info("Jarvis voice assistant stopped")
            return {"status": "stopped"}
            
        except Exception as e:
            logger.error(f"Error stopping Jarvis: {e}")
            return {"status": "error", "message": str(e)}
    
    async def _monitor_output(self):
        """Monitor Jarvis process output and broadcast events"""
        if not self.process or not self.process.stdout:
            return
        
        try:
            while self.is_running and self.process:
                line = await self.process.stdout.readline()
                if not line:
                    break
                
                text = line.decode().strip()
                if not text:
                    continue
                
                # Parse output and detect state changes
                await self._parse_output(text)
                
        except asyncio.CancelledError:
            logger.info("Output monitoring cancelled")
        except Exception as e:
            logger.error(f"Error monitoring output: {e}")
    
    async def _parse_output(self, text: str):
        """Parse Jarvis output and broadcast appropriate events"""
        
        # Detect wake word
        if "Listening... (say 'Jarvis' to activate)" in text or "🎤 Listening..." in text:
            self.current_state = "listening"
            await self._emit_event({
                "type": "state_change",
                "state": "listening",
                "message": "Listening for wake word"
            })
        
        # Detect wake word detected
        elif "Yes? I'm listening" in text or "Wake word" in text:
            self.current_state = "activated"
            await self._emit_event({
                "type": "wake_word_detected",
                "state": "activated"
            })
        
        # Detect user speech
        elif "👤 You:" in text:
            user_text = text.replace("👤 You:", "").strip()
            self.current_state = "processing"
            await self._emit_event({
                "type": "user_speech",
                "text": user_text,
                "state": "processing"
            })
        
        # Detect Jarvis thinking
        elif "Let me think about that" in text or "⚙️  Processing" in text:
            self.current_state = "processing"
            await self._emit_event({
                "type": "processing",
                "state": "processing"
            })
        
        # Detect Jarvis response
        elif "🤖 Jarvis:" in text:
            response_text = text.replace("🤖 Jarvis:", "").strip()
            if response_text and response_text not in ["Calibrating microphone, please wait.", "Hello! I'm Jarvis, your AI assistant. Say my name whenever you need me."]:
                self.current_state = "speaking"
                await self._emit_event({
                    "type": "jarvis_response",
                    "text": response_text,
                    "state": "speaking"
                })
        
        # Detect metadata
        elif "📊" in text and "[" in text:
            # Model and duration info
            await self._emit_event({
                "type": "metadata",
                "info": text
            })
    
    def get_status(self):
        """Get current Jarvis status"""
        return {
            "is_running": self.is_running,
            "state": self.current_state,
            "process_alive": self.process is not None and self.process.returncode is None
        }

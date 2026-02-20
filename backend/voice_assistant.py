"""
voice_assistant.py - Voice Command System with Wake Word Detection

Provides wake word detection ("Jarvis") and speech-to-text conversion
for voice-controlled commands. Integrates with OpenClaw for AI execution.

Features:
- Wake word detection using Porcupine or simple keyword spotting
- Speech recognition using Google Speech API
- Audio feedback (beeps, TTS)
- Background thread for continuous listening
"""

import asyncio
import logging
import queue
import threading
import time
from typing import Optional, Callable
from dataclasses import dataclass
from enum import Enum

logger = logging.getLogger(__name__)

# Try to import audio libraries
try:
    import speech_recognition as sr
    SPEECH_RECOGNITION_AVAILABLE = True
except ImportError:
    SPEECH_RECOGNITION_AVAILABLE = False
    logger.warning("speech_recognition not available - install with: pip install SpeechRecognition")

try:
    import pyttsx3
    TTS_AVAILABLE = True
except ImportError:
    TTS_AVAILABLE = False
    logger.warning("pyttsx3 not available - install with: pip install pyttsx3")

try:
    import pvporcupine
    PORCUPINE_AVAILABLE = True
except ImportError:
    PORCUPINE_AVAILABLE = False
    logger.warning("Porcupine not available - using fallback keyword detection")


class VoiceState(Enum):
    """States of the voice assistant."""
    IDLE = "idle"                      # Waiting for wake word
    LISTENING = "listening"            # Actively listening for command
    PROCESSING = "processing"          # Processing the command
    SPEAKING = "speaking"              # Providing audio feedback
    ERROR = "error"                    # Error state


@dataclass
class VoiceCommand:
    """Represents a voice command."""
    text: str
    confidence: float
    timestamp: float
    language: str = "en-US"


class VoiceAssistant:
    """Voice assistant with wake word detection and speech recognition."""
    
    def __init__(
        self,
        wake_word: str = "jarvis",
        language: str = "en-US",
        timeout: int = 5,
        porcupine_access_key: Optional[str] = None,
        enable_tts: bool = True
    ):
        """
        Initialize voice assistant.
        
        Args:
            wake_word: Wake word to listen for (default: "jarvis")
            language: Language code for speech recognition
            timeout: Seconds to listen after wake word
            porcupine_access_key: Porcupine API key (optional)
            enable_tts: Enable text-to-speech feedback
        """
        self.wake_word = wake_word.lower()
        self.language = language
        self.timeout = timeout
        self.porcupine_access_key = porcupine_access_key
        self.enable_tts = enable_tts
        
        # State management
        self.state = VoiceState.IDLE
        self.running = False
        self.listening_thread: Optional[threading.Thread] = None
        
        # Command callback
        self.on_command: Optional[Callable[[VoiceCommand], None]] = None
        self.on_state_change: Optional[Callable[[VoiceState], None]] = None
        
        # Initialize components
        self._init_speech_recognizer()
        self._init_tts()
        self._init_wake_word_detector()
        
        # Command queue for async processing
        self.command_queue = queue.Queue()
        
        logger.info(f"Voice assistant initialized with wake word: '{self.wake_word}'")
    
    def _init_speech_recognizer(self):
        """Initialize speech recognition."""
        if not SPEECH_RECOGNITION_AVAILABLE:
            logger.error("Speech recognition not available")
            self.recognizer = None
            self.microphone = None
            return
        
        try:
            self.recognizer = sr.Recognizer()
            self.microphone = sr.Microphone()
            
            # Adjust for ambient noise
            with self.microphone as source:
                logger.info("Calibrating for ambient noise...")
                self.recognizer.adjust_for_ambient_noise(source, duration=1)
            
            logger.info("Speech recognizer initialized")
            
        except Exception as e:
            logger.error(f"Failed to initialize speech recognizer: {e}")
            self.recognizer = None
            self.microphone = None
    
    def _init_tts(self):
        """Initialize text-to-speech engine."""
        if not self.enable_tts or not TTS_AVAILABLE:
            self.tts_engine = None
            return
        
        try:
            self.tts_engine = pyttsx3.init()
            self.tts_engine.setProperty('rate', 175)  # Speed
            self.tts_engine.setProperty('volume', 0.9)  # Volume
            logger.info("TTS engine initialized")
            
        except Exception as e:
            logger.error(f"Failed to initialize TTS: {e}")
            self.tts_engine = None
    
    def _init_wake_word_detector(self):
        """Initialize wake word detection (Porcupine or fallback)."""
        if PORCUPINE_AVAILABLE and self.porcupine_access_key:
            try:
                # Initialize Porcupine with custom wake word
                self.porcupine = pvporcupine.create(
                    access_key=self.porcupine_access_key,
                    keywords=[self.wake_word]
                )
                self.use_porcupine = True
                logger.info(f"Porcupine wake word detector initialized for '{self.wake_word}'")
                
            except Exception as e:
                logger.warning(f"Porcupine initialization failed: {e}, using fallback")
                self.use_porcupine = False
        else:
            self.use_porcupine = False
            logger.info("Using fallback keyword detection for wake word")
    
    def _set_state(self, new_state: VoiceState):
        """Change assistant state and notify listeners."""
        if self.state != new_state:
            old_state = self.state
            self.state = new_state
            logger.info(f"State change: {old_state.value} → {new_state.value}")
            
            if self.on_state_change:
                try:
                    self.on_state_change(new_state)
                except Exception as e:
                    logger.error(f"Error in state change callback: {e}")
    
    def speak(self, text: str):
        """
        Speak text using TTS engine.
        
        Args:
            text: Text to speak
        """
        if not self.tts_engine:
            logger.debug(f"TTS not available, would have said: {text}")
            return
        
        try:
            self._set_state(VoiceState.SPEAKING)
            self.tts_engine.say(text)
            self.tts_engine.runAndWait()
            self._set_state(VoiceState.IDLE)
            
        except Exception as e:
            logger.error(f"TTS error: {e}")
            self._set_state(VoiceState.IDLE)
    
    def _detect_wake_word_in_text(self, text: str) -> bool:
        """
        Fallback method: detect wake word in recognized text.
        
        Args:
            text: Recognized speech text
            
        Returns:
            True if wake word detected
        """
        return self.wake_word in text.lower()
    
    def _listen_for_wake_word(self) -> bool:
        """
        Listen for wake word using speech recognition.
        
        Returns:
            True if wake word detected
        """
        if not self.recognizer or not self.microphone:
            logger.error("Speech recognizer not initialized")
            return False
        
        try:
            with self.microphone as source:
                logger.debug("Listening for wake word...")
                # Listen for a short duration
                audio = self.recognizer.listen(source, timeout=1, phrase_time_limit=3)
            
            # Recognize speech
            text = self.recognizer.recognize_google(audio, language=self.language).lower()
            logger.debug(f"Heard: {text}")
            
            # Check if wake word is present
            if self._detect_wake_word_in_text(text):
                logger.info(f"Wake word '{self.wake_word}' detected!")
                return True
            
        except sr.WaitTimeoutError:
            # Normal timeout, keep listening
            pass
        except sr.UnknownValueError:
            # Speech not understood
            pass
        except sr.RequestError as e:
            logger.error(f"Speech recognition service error: {e}")
        except Exception as e:
            logger.error(f"Wake word detection error: {e}")
        
        return False
    
    def _listen_for_command(self) -> Optional[VoiceCommand]:
        """
        Listen for voice command after wake word.
        
        Returns:
            VoiceCommand if recognized, None otherwise
        """
        if not self.recognizer or not self.microphone:
            return None
        
        try:
            self._set_state(VoiceState.LISTENING)
            
            # Optional audio feedback
            self.speak("Yes?")  # or play a beep
            
            with self.microphone as source:
                logger.info(f"Listening for command (timeout: {self.timeout}s)...")
                audio = self.recognizer.listen(
                    source,
                    timeout=self.timeout,
                    phrase_time_limit=10
                )
            
            # Recognize command
            logger.info("Processing speech...")
            text = self.recognizer.recognize_google(audio, language=self.language)
            
            logger.info(f"Command recognized: '{text}'")
            
            command = VoiceCommand(
                text=text,
                confidence=1.0,  # Google doesn't provide confidence
                timestamp=time.time(),
                language=self.language
            )
            
            return command
            
        except sr.WaitTimeoutError:
            logger.warning("No command heard (timeout)")
            self.speak("I didn't hear anything")
            
        except sr.UnknownValueError:
            logger.warning("Could not understand command")
            self.speak("Sorry, I didn't understand that")
            
        except sr.RequestError as e:
            logger.error(f"Speech recognition service error: {e}")
            self.speak("Sorry, there was a technical issue")
            
        except Exception as e:
            logger.error(f"Command recognition error: {e}")
            self.speak("Something went wrong")
        
        finally:
            self._set_state(VoiceState.IDLE)
        
        return None
    
    def _listening_loop(self):
        """Main listening loop (runs in background thread)."""
        logger.info("Voice assistant listening loop started")
        
        while self.running:
            try:
                # Wait for wake word
                if self._listen_for_wake_word():
                    # Wake word detected, listen for command
                    command = self._listen_for_command()
                    
                    if command:
                        # Add to queue for async processing
                        self.command_queue.put(command)
                        
                        # Call callback if registered
                        if self.on_command:
                            try:
                                self.on_command(command)
                            except Exception as e:
                                logger.error(f"Error in command callback: {e}")
                
            except Exception as e:
                logger.error(f"Error in listening loop: {e}")
                time.sleep(1)  # Avoid tight loop on persistent errors
        
        logger.info("Voice assistant listening loop stopped")
    
    def start(self):
        """Start the voice assistant in background."""
        if self.running:
            logger.warning("Voice assistant already running")
            return
        
        if not self.recognizer:
            logger.error("Cannot start: speech recognizer not initialized")
            return
        
        self.running = True
        self.listening_thread = threading.Thread(
            target=self._listening_loop,
            daemon=True,
            name="VoiceAssistant"
        )
        self.listening_thread.start()
        logger.info("Voice assistant started")
    
    def stop(self):
        """Stop the voice assistant."""
        if not self.running:
            return
        
        logger.info("Stopping voice assistant...")
        self.running = False
        
        if self.listening_thread:
            self.listening_thread.join(timeout=5)
        
        logger.info("Voice assistant stopped")
    
    def get_pending_commands(self) -> list[VoiceCommand]:
        """
        Get all pending commands from the queue.
        
        Returns:
            List of pending voice commands
        """
        commands = []
        while not self.command_queue.empty():
            try:
                commands.append(self.command_queue.get_nowait())
            except queue.Empty:
                break
        return commands


# Convenience function
def create_voice_assistant(**kwargs) -> Optional[VoiceAssistant]:
    """
    Create and initialize a voice assistant.
    
    Args:
        **kwargs: Arguments passed to VoiceAssistant constructor
        
    Returns:
        VoiceAssistant instance or None if dependencies missing
    """
    if not SPEECH_RECOGNITION_AVAILABLE:
        logger.error("Cannot create voice assistant: speech_recognition not installed")
        return None
    
    try:
        return VoiceAssistant(**kwargs)
    except Exception as e:
        logger.error(f"Failed to create voice assistant: {e}")
        return None


# Example usage
if __name__ == "__main__":
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s  %(name)-18s  %(levelname)-5s  %(message)s"
    )
    
    def on_command_received(cmd: VoiceCommand):
        print(f"\n🎤 Command: {cmd.text}")
        print(f"   Confidence: {cmd.confidence}")
        print(f"   Timestamp: {cmd.timestamp}\n")
    
    def on_state_changed(state: VoiceState):
        print(f"📊 State: {state.value}")
    
    # Create assistant
    assistant = create_voice_assistant(
        wake_word="jarvis",
        language="en-US",
        timeout=5,
        enable_tts=True
    )
    
    if assistant:
        assistant.on_command = on_command_received
        assistant.on_state_change = on_state_changed
        
        # Start listening
        assistant.start()
        
        print("🎙️  Voice assistant is running. Say 'Jarvis' followed by a command.")
        print("   Press Ctrl+C to stop.\n")
        
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            print("\nStopping...")
            assistant.stop()

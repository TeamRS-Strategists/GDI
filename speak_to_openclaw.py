#!/usr/bin/env python3
"""
Speak to OpenClaw - Standalone Voice Command Tool

This script allows you to speak directly to OpenClaw Gateway without
needing the full GDI backend/frontend setup.

Usage:
    python speak_to_openclaw.py

Say "Jarvis" followed by your command!
"""

import asyncio
import json
import sys
import time
from pathlib import Path

# Add backend to path
sys.path.insert(0, str(Path(__file__).parent / "backend"))

try:
    import speech_recognition as sr
    SPEECH_AVAILABLE = True
except ImportError:
    SPEECH_AVAILABLE = False
    print("⚠️  speech_recognition not installed")
    print("   Install with: pip install SpeechRecognition pyaudio")
    print("   Continuing with text input mode...")

from openclaw_bridge import OpenClawBridge


class VoiceCLI:
    """Voice command line interface for OpenClaw."""
    
    def __init__(self):
        self.bridge = OpenClawBridge()
        self.recognizer = sr.Recognizer() if SPEECH_AVAILABLE else None
        self.microphone = sr.Microphone() if SPEECH_AVAILABLE else None
        self.wake_word = "jarvis"
        self.listening = False
        
    async def connect(self):
        """Connect to OpenClaw Gateway."""
        print("🔌 Connecting to OpenClaw Gateway...")
        connected = await self.bridge.connect()
        
        if not connected:
            print("❌ Failed to connect to OpenClaw Gateway")
            print("   Make sure OpenClaw is running: openclaw gateway --port 18789")
            return False
        
        print("✅ Connected to OpenClaw Gateway!")
        return True
    
    def listen_for_wake_word(self):
        """Listen for the wake word using microphone."""
        if not SPEECH_AVAILABLE:
            return False
        
        print(f"\n🎤 Listening for '{self.wake_word}'... (or press Ctrl+C to quit)")
        
        with self.microphone as source:
            # Adjust for ambient noise
            self.recognizer.adjust_for_ambient_noise(source, duration=0.5)
            
            try:
                audio = self.recognizer.listen(source, timeout=None, phrase_time_limit=3)
                
                try:
                    text = self.recognizer.recognize_google(audio).lower()
                    print(f"   Heard: '{text}'")
                    
                    if self.wake_word in text:
                        print(f"\n🌟 Wake word '{self.wake_word}' detected!")
                        return True
                    
                except sr.UnknownValueError:
                    pass  # Couldn't understand audio
                except sr.RequestError as e:
                    print(f"   Error with speech recognition service: {e}")
                
            except sr.WaitTimeoutError:
                pass  # No speech detected
        
        return False
    
    def listen_for_command(self):
        """Listen for the actual command after wake word."""
        if not SPEECH_AVAILABLE:
            return input("💬 Enter your command: ").strip()
        
        print("🗣️  Listening for your command... (speak now)")
        
        with self.microphone as source:
            try:
                audio = self.recognizer.listen(source, timeout=5, phrase_time_limit=10)
                
                try:
                    command = self.recognizer.recognize_google(audio)
                    print(f"   You said: '{command}'")
                    return command
                    
                except sr.UnknownValueError:
                    print("   ❌ Could not understand audio")
                    return None
                except sr.RequestError as e:
                    print(f"   ❌ Error with speech recognition: {e}")
                    return None
                
            except sr.WaitTimeoutError:
                print("   ❌ No speech detected (timeout)")
                return None
    
    async def execute_command(self, command):
        """Send command to OpenClaw and get response."""
        print(f"\n⚙️  Processing: '{command}'")
        print("   Please wait...")
        
        # Reconnect if connection was dropped
        if not self.bridge.connected:
            print("   🔄 Reconnecting to OpenClaw...")
            await self.bridge.connect()
        
        result = await self.bridge.execute_command(command)
        
        print("\n" + "=" * 60)
        if "error" in result:
            print(f"❌ Error: {result['error']}")
            # Try to reconnect for next time
            if "not connected" in result.get("error", "").lower():
                print("   🔄 Will reconnect on next command...")
        else:
            response = result.get("response", "Command executed")
            print(f"✅ Response: {response}")
            
            if result.get("tools"):
                print(f"🔧 Tools used: {', '.join(result['tools'])}")
        print("=" * 60)
    
    async def run_voice_mode(self):
        """Run in voice mode with wake word detection."""
        print("\n" + "=" * 60)
        print("🎙️  VOICE MODE")
        print("=" * 60)
        print(f"Wake word: '{self.wake_word}'")
        print("Process:")
        print("  1. Say 'Jarvis' to activate")
        print("  2. Wait for confirmation")
        print("  3. Speak your command")
        print("  4. Wait for OpenClaw to respond")
        print("\nPress Ctrl+C to exit")
        print("=" * 60)
        
        try:
            while True:
                # Listen for wake word
                if self.listen_for_wake_word():
                    # Get command
                    command = self.listen_for_command()
                    
                    if command:
                        # Execute command
                        await self.execute_command(command)
                        print(f"\n{'─' * 60}")
                        print(f"Ready for next command. Say '{self.wake_word}' again...")
                    else:
                        print("   No command detected. Try again.")
                
                # Small delay to prevent CPU spinning
                await asyncio.sleep(0.1)
                
        except KeyboardInterrupt:
            print("\n\n👋 Goodbye!")
    
    async def run_text_mode(self):
        """Run in text mode (keyboard input)."""
        print("\n" + "=" * 60)
        print("⌨️  TEXT MODE (Speech recognition not available)")
        print("=" * 60)
        print("Type your commands and press Enter")
        print("Type 'quit' or 'exit' to stop")
        print("=" * 60)
        print()
        
        try:
            while True:
                # Get command from keyboard
                command = input(f"💬 Command (or type '{self.wake_word}' first): ").strip()
                
                if command.lower() in ['quit', 'exit', 'q']:
                    break
                
                if not command:
                    continue
                
                # Remove wake word if user typed it
                if command.lower().startswith(self.wake_word):
                    command = command[len(self.wake_word):].strip()
                
                if command:
                    await self.execute_command(command)
                    print()
        
        except KeyboardInterrupt:
            print("\n\n👋 Goodbye!")
    
    async def run_interactive(self):
        """Run interactive mode with menu."""
        print("\n" + "=" * 60)
        print("🎯 INTERACTIVE MODE")
        print("=" * 60)
        
        while True:
            print("\nChoose mode:")
            print("  1. Voice mode (say 'Jarvis' then command)")
            print("  2. Text mode (type commands)")
            print("  3. Single command (quick test)")
            print("  4. Exit")
            
            choice = input("\nEnter choice (1-4): ").strip()
            
            if choice == '1':
                if not SPEECH_AVAILABLE:
                    print("❌ Voice mode not available (install SpeechRecognition)")
                    continue
                await self.run_voice_mode()
            
            elif choice == '2':
                await self.run_text_mode()
            
            elif choice == '3':
                command = input("💬 Enter command: ").strip()
                if command:
                    await self.execute_command(command)
            
            elif choice == '4':
                print("\n👋 Goodbye!")
                break
            
            else:
                print("Invalid choice. Try again.")
    
    async def cleanup(self):
        """Cleanup resources."""
        await self.bridge.disconnect()


async def main():
    """Main entry point."""
    print("=" * 60)
    print("🎤 Speak to OpenClaw - Voice Command Tool")
    print("=" * 60)
    
    cli = VoiceCLI()
    
    # Connect to OpenClaw
    if not await cli.connect():
        return
    
    try:
        # Check if speech is available
        if SPEECH_AVAILABLE:
            # Default to voice mode
            await cli.run_voice_mode()
        else:
            # Fall back to text mode
            await cli.run_text_mode()
    
    finally:
        await cli.cleanup()


if __name__ == "__main__":
    # Check command line args
    if len(sys.argv) > 1:
        if sys.argv[1] == "--interactive":
            asyncio.run(VoiceCLI().run_interactive())
        elif sys.argv[1] == "--text":
            cli = VoiceCLI()
            async def run():
                if await cli.connect():
                    await cli.run_text_mode()
                    await cli.cleanup()
            asyncio.run(run())
        elif sys.argv[1] == "--help":
            print(__doc__)
            print("\nOptions:")
            print("  --interactive  Interactive mode with menu")
            print("  --text        Text-only mode")
            print("  --help        Show this help")
            sys.exit(0)
    else:
        asyncio.run(main())

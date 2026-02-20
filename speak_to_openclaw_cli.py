#!/usr/bin/env python3
"""
Speak to OpenClaw - Voice Command Interface (CLI Version)

This script listens for "Jarvis" wake word and executes commands
through the OpenClaw CLI, bypassing the WebSocket authentication issues.
"""

import speech_recognition as sr
import subprocess
import json
import time

class VoiceCLI:
    """Voice Command Line Interface for OpenClaw"""
    
    def __init__(self):
        """Initialize voice recognition"""
        self.recognizer = sr.Recognizer()
        self.microphone = sr.Microphone()
        
        # Adjust for ambient noise
        print("🎤 Calibrating microphone...")
        with self.microphone as source:
            self.recognizer.adjust_for_ambient_noise(source, duration=1)
        print("✅ Microphone ready!")
        
    def listen_for_wake_word(self):
        """Listen for the wake word 'jarvis'"""
        with self.microphone as source:
            print("\n🎤 Listening for 'jarvis'... (or press Ctrl+C to quit)")
            
            try:
                audio = self.recognizer.listen(source, timeout=None, phrase_time_limit=3)
                
                try:
                    text = self.recognizer.recognize_google(audio).lower()
                    
                    if text and text != "jarvis":
                        print(f"   Heard: '{text}'")
                    
                    if "jarvis" in text:
                        return True
                    
                except sr.UnknownValueError:
                    pass  # Couldn't understand audio
                except sr.RequestError as e:
                    print(f"❌ Speech recognition error: {e}")
                    time.sleep(1)
                    
            except KeyboardInterrupt:
                raise
            except Exception as e:
                print(f"❌ Microphone error: {e}")
                time.sleep(1)
        
        return False
    
    def listen_for_command(self):
        """Listen for user command after wake word"""
        print("\n🌟 Wake word 'jarvis' detected!")
        print("🗣️  Listening for your command... (speak now)")
        
        with self.microphone as source:
            try:
                audio = self.recognizer.listen(source, timeout=5, phrase_time_limit=10)
                
                try:
                    command = self.recognizer.recognize_google(audio)
                    print(f"   You said: '{command}'")
                    return command
                    
                except sr.UnknownValueError:
                    print("❌ Could not understand audio")
                    return None
                except sr.RequestError as e:
                    print(f"❌ Speech recognition error: {e}")
                    return None
                    
            except sr.WaitTimeoutError:
                print("❌ No command heard (timeout)")
                return None
            except Exception as e:
                print(f"❌ Error: {e}")
                return None
    
    def execute_command(self, command):
        """Execute command through OpenClaw CLI"""
        print(f"\n⚙️  Processing: '{command}'")
        print("   Please wait...")
        
        try:
            # Call openclaw CLI directly
            result = subprocess.run(
                [
                    "openclaw", "agent",
                    "--message", command,
                    "--session-id", "voice_jarvis",
                    "--json"
                ],
                capture_output=True,
                text=True,
                timeout=60
            )
            
            if result.returncode == 0:
                try:
                    # Parse JSON response
                    response = json.loads(result.stdout)
                    
                    # Extract the text response
                    if "payloads" in response and len(response["payloads"]) > 0:
                        text_response = response["payloads"][0].get("text", "")
                        
                        print("\n" + "=" * 60)
                        print("🤖 OpenClaw Response:")
                        print("=" * 60)
                        print(text_response)
                        print("=" * 60)
                        
                        # Show usage info if available
                        if "meta" in response and "agentMeta" in response["meta"]:
                            agent_meta = response["meta"]["agentMeta"]
                            print(f"\n📊 Model: {agent_meta.get('model', 'N/A')}")
                            print(f"⏱️  Duration: {response['meta'].get('durationMs', 0)}ms")
                        
                        return True
                    else:
                        print("\n❌ No response from OpenClaw")
                        return False
                        
                except json.JSONDecodeError:
                    print("\n✅ Command executed (non-JSON response)")
                    if result.stdout:
                        print(result.stdout)
                    return True
            else:
                print(f"\n❌ OpenClaw CLI error (exit code {result.returncode})")
                if result.stderr:
                    print("Error output:")
                    print(result.stderr[:500])
                return False
                
        except subprocess.TimeoutExpired:
            print("\n❌ Command timeout (60s)")
            return False
        except FileNotFoundError:
            print("\n❌ OpenClaw CLI not found!")
            print("   Make sure 'openclaw' is installed and in your PATH")
            return False
        except Exception as e:
            print(f"\n❌ Error executing command: {e}")
            return False
    
    def run_voice_mode(self):
        """Main voice interaction loop"""
        try:
            while True:
                # Wait for wake word
                if self.listen_for_wake_word():
                    # Get command
                    command = self.listen_for_command()
                    
                    if command:
                        # Execute through OpenClaw
                        self.execute_command(command)
                    
                    print("\n" + "─" * 60)
                    print("Ready for next command. Say 'jarvis' again...")
                    
        except KeyboardInterrupt:
            print("\n\n👋 Goodbye!")
            return


def main():
    """Main entry point"""
    print("=" * 60)
    print("🎤 Speak to OpenClaw - Voice Command Tool (CLI Mode)")
    print("=" * 60)
    print()
    print("=" * 60)
    print("🎙️  VOICE MODE")
    print("=" * 60)
    print("Wake word: 'jarvis'")
    print("Process:")
    print("  1. Say 'Jarvis' to activate")
    print("  2. Wait for confirmation")
    print("  3. Speak your command")
    print("  4. Wait for OpenClaw to respond")
    print()
    print("Press Ctrl+C to exit")
    print("=" * 60)
    print()
    
    cli = VoiceCLI()
    cli.run_voice_mode()


if __name__ == "__main__":
    main()

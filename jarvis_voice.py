#!/usr/bin/env python3
"""
Jarvis - Conversational Voice Assistant with OpenClaw

A true conversational AI assistant that speaks back to you!
Listens for "Jarvis" wake word and has voice conversations.
"""

import speech_recognition as sr
import subprocess
import json
import time
import sys

# TTS Setup - try multiple backends
TTS_ENGINE = None
TTS_TYPE = None

try:
    import pyttsx3
    TTS_ENGINE = pyttsx3.init()
    TTS_ENGINE.setProperty('rate', 180)  # Speed
    TTS_ENGINE.setProperty('volume', 0.9)  # Volume
    TTS_TYPE = "pyttsx3"
    print("🔊 Using pyttsx3 for text-to-speech")
except Exception as e:
    print(f"⚠️  pyttsx3 not available: {e}")
    try:
        # Fallback to macOS 'say' command
        result = subprocess.run(['which', 'say'], capture_output=True)
        if result.returncode == 0:
            TTS_TYPE = "macos_say"
            print("🔊 Using macOS 'say' command for text-to-speech")
    except:
        pass

if not TTS_TYPE:
    print("❌ No text-to-speech available!")
    print("   Install with: pip install pyttsx3")
    sys.exit(1)


class JarvisVoice:
    """Conversational Voice Assistant with OpenClaw"""
    
    def __init__(self):
        """Initialize voice recognition and TTS"""
        self.recognizer = sr.Recognizer()
        self.microphone = sr.Microphone()
        
        # Adjust for ambient noise
        self.speak("Calibrating microphone, please wait.", print_only=True)
        with self.microphone as source:
            self.recognizer.adjust_for_ambient_noise(source, duration=1)
        print("✅ Microphone ready!")
        
    def speak(self, text, print_only=False):
        """Speak text using TTS"""
        print(f"\n🤖 Jarvis: {text}\n")
        
        if print_only:
            return
        
        if TTS_TYPE == "pyttsx3":
            try:
                TTS_ENGINE.say(text)
                TTS_ENGINE.runAndWait()
            except Exception as e:
                print(f"⚠️  TTS error: {e}")
        elif TTS_TYPE == "macos_say":
            try:
                subprocess.run(['say', text], check=False)
            except Exception as e:
                print(f"⚠️  TTS error: {e}")
    
    def listen_for_wake_word(self):
        """Listen for the wake word 'jarvis'"""
        with self.microphone as source:
            print("🎤 Listening... (say 'Jarvis' to activate)")
            
            try:
                audio = self.recognizer.listen(source, timeout=None, phrase_time_limit=3)
                
                try:
                    text = self.recognizer.recognize_google(audio).lower()
                    
                    if text and "jarvis" not in text:
                        print(f"   [{text}]")
                    
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
        self.speak("Yes? I'm listening.")
        
        with self.microphone as source:
            try:
                audio = self.recognizer.listen(source, timeout=8, phrase_time_limit=15)
                
                try:
                    command = self.recognizer.recognize_google(audio)
                    print(f"👤 You: {command}")
                    return command
                    
                except sr.UnknownValueError:
                    self.speak("Sorry, I didn't catch that. Could you repeat?")
                    return None
                except sr.RequestError as e:
                    self.speak("I'm having trouble with speech recognition.")
                    print(f"❌ Error: {e}")
                    return None
                    
            except sr.WaitTimeoutError:
                self.speak("I didn't hear anything. Say Jarvis to try again.")
                return None
            except Exception as e:
                print(f"❌ Error: {e}")
                return None
    
    def execute_command(self, command):
        """Execute command through OpenClaw CLI and speak response"""
        self.speak("Let me think about that...")
        
        try:
            # Call openclaw CLI
            result = subprocess.run(
                [
                    "openclaw", "agent",
                    "--message", command,
                    "--session-id", "jarvis_conversation",
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
                        
                        if text_response:
                            # Speak the response
                            self.speak(text_response)
                            
                            # Show metadata
                            if "meta" in response and "agentMeta" in response["meta"]:
                                agent_meta = response["meta"]["agentMeta"]
                                duration = response['meta'].get('durationMs', 0)
                                print(f"📊 [{agent_meta.get('model', 'N/A')} • {duration}ms]")
                            
                            return True
                        else:
                            self.speak("I received an empty response.")
                            return False
                    else:
                        self.speak("I didn't get a proper response.")
                        return False
                        
                except json.JSONDecodeError as e:
                    self.speak("I had trouble parsing the response.")
                    print(f"JSON error: {e}")
                    if result.stdout:
                        print(result.stdout[:500])
                    return False
            else:
                self.speak("I encountered an error processing that request.")
                if result.stderr:
                    print(f"Error: {result.stderr[:300]}")
                return False
                
        except subprocess.TimeoutExpired:
            self.speak("That request took too long. Let's try something else.")
            return False
        except FileNotFoundError:
            self.speak("I can't find the OpenClaw CLI. Please check the installation.")
            return False
        except Exception as e:
            self.speak("Something went wrong.")
            print(f"❌ Error: {e}")
            return False
    
    def run(self):
        """Main conversational loop"""
        # Greet user
        self.speak("Hello! I'm Jarvis, your AI assistant. Say my name whenever you need me.")
        
        try:
            while True:
                # Wait for wake word
                if self.listen_for_wake_word():
                    # Get command
                    command = self.listen_for_command()
                    
                    if command:
                        # Execute and speak response
                        self.execute_command(command)
                    
                    print("\n" + "─" * 60 + "\n")
                    
        except KeyboardInterrupt:
            self.speak("Goodbye! Have a great day.")
            print("\n👋 Jarvis shutting down...\n")
            return


def main():
    """Main entry point"""
    print("\n" + "=" * 60)
    print("🎙️  JARVIS - Conversational AI Assistant")
    print("=" * 60)
    print()
    print("💡 How to use:")
    print("   1. Say 'Jarvis' to activate")
    print("   2. Speak your request")
    print("   3. Listen to Jarvis's response")
    print("   4. Repeat anytime!")
    print()
    print("Examples:")
    print("   • 'Jarvis' → 'What time is it?'")
    print("   • 'Jarvis' → 'Tell me a joke'")
    print("   • 'Jarvis' → 'Create a simple Python script'")
    print()
    print("Press Ctrl+C to exit")
    print("=" * 60)
    print()
    
    jarvis = JarvisVoice()
    jarvis.run()


if __name__ == "__main__":
    main()

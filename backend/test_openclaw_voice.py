"""
test_openclaw_voice.py - Test script for OpenClaw voice wake integration

This script tests:
1. Connection to OpenClaw Gateway (port 18789)
2. Voice wake word detection ("Jarvis")
3. Command execution via OpenClaw AI

Run this to verify OpenClaw integration is working.
"""

import asyncio
import json
import logging
import sys
from pathlib import Path

# Add backend directory to path
sys.path.insert(0, str(Path(__file__).parent))

from openclaw_bridge import OpenClawBridge

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)
logger = logging.getLogger(__name__)


async def test_openclaw_connection():
    """Test basic connection to OpenClaw Gateway."""
    logger.info("=" * 60)
    logger.info("Testing OpenClaw Gateway Connection")
    logger.info("=" * 60)
    
    bridge = OpenClawBridge(gateway_url="ws://127.0.0.1:18789")
    
    # Test 1: Connection
    logger.info("\n[1/4] Testing connection to OpenClaw Gateway...")
    connected = await bridge.connect()
    
    if not connected:
        logger.error("❌ Failed to connect to OpenClaw Gateway")
        logger.error("Make sure OpenClaw is running: openclaw gateway --port 18789")
        return False
    
    logger.info("✅ Connected to OpenClaw Gateway")
    
    # Test 2: Send a simple message
    logger.info("\n[2/4] Testing message sending...")
    success = await bridge.send_message("main", "Hello from GDI!")
    
    if success:
        logger.info("✅ Message sent successfully")
    else:
        logger.warning("⚠️  Message send failed (may not be critical)")
    
    # Wait a bit for any responses
    await asyncio.sleep(2)
    
    # Test 3: Execute a simple command
    logger.info("\n[3/4] Testing command execution...")
    logger.info("Sending command: 'What is the current time?'")
    
    result = await bridge.execute_command("What is the current time?")
    
    if "error" in result:
        logger.warning(f"⚠️  Command execution returned: {result}")
    else:
        logger.info(f"✅ Command result: {result}")
    
    # Test 4: Check session status
    logger.info("\n[4/4] Checking session status...")
    status = await bridge.get_session_status("main")
    logger.info(f"Session status: {status}")
    
    # Cleanup
    logger.info("\n[Cleanup] Disconnecting from OpenClaw Gateway...")
    await bridge.disconnect()
    logger.info("✅ Disconnected")
    
    logger.info("\n" + "=" * 60)
    logger.info("OpenClaw Integration Test Complete!")
    logger.info("=" * 60)
    logger.info("\nNext steps:")
    logger.info("1. Make sure microphone permissions are granted")
    logger.info("2. Start the GDI backend: uvicorn main:app --reload")
    logger.info("3. Use /api/voice/start to enable voice wake")
    logger.info("4. Say 'Jarvis' to trigger voice command mode")
    logger.info("5. Speak your command (e.g., 'create a website for me')")
    
    return True


async def test_voice_wake_listener():
    """Test voice wake word detection by listening to OpenClaw events."""
    logger.info("\n" + "=" * 60)
    logger.info("Testing Voice Wake Word Detection")
    logger.info("=" * 60)
    logger.info("\nThis will listen for the wake word 'Jarvis'")
    logger.info("Say 'Jarvis' followed by your command...")
    logger.info("Press Ctrl+C to stop\n")
    
    bridge = OpenClawBridge()
    
    # Connect
    if not await bridge.connect():
        logger.error("Failed to connect to OpenClaw Gateway")
        return
    
    # Register event handlers
    @bridge.on_message("voice.wake_detected")
    async def on_wake(data):
        logger.info("🎤 WAKE WORD DETECTED: Jarvis!")
        logger.info(f"Data: {data}")
    
    @bridge.on_message("voice.transcription")
    async def on_transcription(data):
        text = data.get("text", "")
        logger.info(f"📝 Transcription: {text}")
    
    @bridge.on_message("agent.response")
    async def on_response(data):
        response = data.get("response", "")
        logger.info(f"🤖 AI Response: {response}")
    
    @bridge.on_message("agent.tool_use")
    async def on_tool(data):
        tool_name = data.get("tool", "")
        logger.info(f"🔧 Tool Used: {tool_name}")
        logger.info(f"   Args: {data.get('args', {})}")
    
    try:
        # Keep listening
        while True:
            await asyncio.sleep(0.1)
    except KeyboardInterrupt:
        logger.info("\n\nStopping voice wake listener...")
        await bridge.disconnect()


if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1 and sys.argv[1] == "--listen":
        # Run voice wake listener
        asyncio.run(test_voice_wake_listener())
    else:
        # Run connection test
        asyncio.run(test_openclaw_connection())

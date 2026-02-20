"""
Test voice events broadcasting
This script simulates voice events to test the UI overlays
"""

import asyncio
import json
from websockets import serve

async def handler(websocket):
    """Handle WebSocket connection and send test voice events."""
    print("Client connected!")
    
    try:
        # Wait a bit
        await asyncio.sleep(2)
        
        # Simulate wake word detection
        print("Sending wake word detection...")
        await websocket.send(json.dumps({
            "type": "voice_wake_detected",
            "wake_word": "jarvis",
            "voice_state": "listening"
        }))
        
        # Wait for "listening" period
        await asyncio.sleep(3)
        
        # Simulate command received
        print("Sending command received...")
        await websocket.send(json.dumps({
            "type": "voice_command",
            "command": "Create a website for me",
            "voice_state": "processing"
        }))
        
        # Wait for processing
        await asyncio.sleep(4)
        
        # Simulate command completion
        print("Sending command completion...")
        await websocket.send(json.dumps({
            "type": "voice_response",
            "command": "Create a website for me",
            "response": "I've created a website template with HTML, CSS, and JavaScript files!",
            "voice_state": "idle"
        }))
        
        # Keep connection alive
        while True:
            await asyncio.sleep(1)
            
    except Exception as e:
        print(f"Error: {e}")

async def main():
    print("=" * 60)
    print("Voice Event Test Server")
    print("=" * 60)
    print("Starting WebSocket server on ws://localhost:8001/ws")
    print("Connect your Flutter app to this endpoint to test overlays")
    print()
    print("Events that will be sent:")
    print("  1. Wake word detected (after 2s)")
    print("  2. Command received (after 3s)")
    print("  3. Command completed (after 4s)")
    print()
    print("Press Ctrl+C to stop")
    print("=" * 60)
    
    async with serve(handler, "localhost", 8001, subprotocols=["websocket"]):
        await asyncio.Future()  # run forever

if __name__ == "__main__":
    asyncio.run(main())

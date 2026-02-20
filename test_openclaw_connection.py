#!/usr/bin/env python3
"""Test OpenClaw Gateway WebSocket connection"""

import asyncio
import websockets
import json

async def test_connection():
    """Test basic connection and message exchange with OpenClaw Gateway"""
    print("🔌 Testing OpenClaw Gateway connection...")
    print("━" * 60)
    
    try:
        # Connect to gateway
        uri = "ws://127.0.0.1:18789"
        print(f"📡 Connecting to {uri}...")
        
        async with websockets.connect(uri) as websocket:
            print("✅ WebSocket connected successfully!")
            print("━" * 60)
            
            # Test 1: Send a simple command
            test_command = "what time is it"
            print(f"\n📤 Sending test command: '{test_command}'")
            
            message = {
                "command": test_command,
                "session_id": "test_session_123"
            }
            
            await websocket.send(json.dumps(message))
            print("✅ Command sent")
            
            # Wait for response
            print("⏳ Waiting for response (timeout: 10s)...")
            
            try:
                response = await asyncio.wait_for(websocket.recv(), timeout=10.0)
                print(f"✅ Received response:")
                print("─" * 60)
                print(response)
                print("─" * 60)
                
                # Try to parse as JSON
                try:
                    response_data = json.loads(response)
                    print("\n📊 Parsed response:")
                    print(json.dumps(response_data, indent=2))
                except json.JSONDecodeError:
                    print("\n⚠️  Response is not JSON")
                
            except asyncio.TimeoutError:
                print("❌ No response received within 10 seconds")
                print("💡 This might indicate the gateway is not processing commands")
            
            print("\n━" * 60)
            print("✅ Connection test complete")
            
    except websockets.exceptions.WebSocketException as e:
        print(f"❌ WebSocket error: {e}")
        print("💡 The gateway might not be accepting WebSocket connections properly")
    except ConnectionRefusedError:
        print("❌ Connection refused - is the gateway running?")
    except Exception as e:
        print(f"❌ Unexpected error: {type(e).__name__}: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    print("=" * 60)
    print("🧪 OpenClaw Gateway Connection Test")
    print("=" * 60)
    asyncio.run(test_connection())

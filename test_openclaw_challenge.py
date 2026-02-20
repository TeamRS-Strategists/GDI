#!/usr/bin/env python3
"""Test OpenClaw Gateway authentication with challenge response"""

import asyncio
import websockets
import json
import hashlib

GATEWAY_URL = "ws://127.0.0.1:18789"
AUTH_TOKEN = "f5269db2521921796c7645e93a993d233cf2e4cf5ce483a6"

async def test_challenge_response():
    """Test authentication with challenge-response"""
    
    print("=" * 70)
    print("🔐 OpenClaw Gateway Challenge-Response Authentication")
    print("=" * 70)
    
    try:
        print(f"\n🔌 Connecting to {GATEWAY_URL}...")
        async with websockets.connect(GATEWAY_URL, ping_interval=20) as ws:
            print("✅ WebSocket connected")
            
            # Step 1: Receive challenge
            print("\n📥 Waiting for challenge...")
            challenge = await ws.recv()
            print(f"📩 Received: {challenge}")
            
            challenge_data = json.loads(challenge)
            nonce = challenge_data.get("payload", {}).get("nonce")
            
            if not nonce:
                print("❌ No nonce in challenge")
                return
            
            print(f"🔑 Nonce: {nonce}")
            
            # Step 2: Respond to challenge with token
            print("\n📤 Sending authentication response...")
            
            # Try different response formats
            responses_to_try = [
                # Format 1: Direct token response
                {
                    "type": "request",
                    "method": "connect.authenticate",
                    "params": {
                        "token": AUTH_TOKEN,
                        "nonce": nonce
                    },
                    "id": 1
                },
                # Format 2: Challenge response with hash
                {
                    "type": "request",
                    "method": "connect.authenticate",
                    "params": {
                        "response": hashlib.sha256(f"{nonce}:{AUTH_TOKEN}".encode()).hexdigest()
                    },
                    "id": 1
                },
                # Format 3: Simple auth object
                {
                    "method": "connect",
                    "params": {
                        "auth": {
                            "token": AUTH_TOKEN
                        },
                        "nonce": nonce
                    },
                    "id": 1
                }
            ]
            
            for i, response in enumerate(responses_to_try, 1):
                print(f"\n📝 Trying format {i}:")
                print(f"   {json.dumps(response, indent=2)[:200]}...")
                
                await ws.send(json.dumps(response))
                print("   📤 Sent")
                
                try:
                    reply = await asyncio.wait_for(ws.recv(), timeout=3.0)
                    print(f"   📥 Response: {reply}")
                    
                    reply_data = json.loads(reply)
                    
                    # If success, try sending a command
                    if reply_data.get("type") == "response" and reply_data.get("result"):
                        print("\n   ✅ Authentication successful!")
                        
                        # Send a test command
                        print("\n   📤 Sending test command...")
                        command = {
                            "method": "gateway.agent.send",
                            "params": {
                                "message": "what time is it",
                                "sessionId": "test"
                            },
                            "id": 2
                        }
                        await ws.send(json.dumps(command))
                        
                        # Wait for responses
                        print("   ⏳ Waiting for agent response...")
                        for _ in range(5):
                            try:
                                msg = await asyncio.wait_for(ws.recv(), timeout=5.0)
                                print(f"   📥 {msg}")
                            except asyncio.TimeoutError:
                                break
                        
                        return  # Success!
                    
                except asyncio.TimeoutError:
                    print("   ⏱️  Timeout waiting for response")
                except Exception as e:
                    print(f"   ❌ Error: {e}")
                    
                # Reconnect for next try
                if i < len(responses_to_try):
                    print("\n   🔄 Reconnecting for next attempt...")
                    break
            
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
    
    print("\n" + "=" * 70)

if __name__ == "__main__":
    asyncio.run(test_challenge_response())

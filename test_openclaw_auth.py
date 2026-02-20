#!/usr/bin/env python3
"""Test OpenClaw Gateway authentication"""

import asyncio
import websockets
import json

GATEWAY_URL = "ws://127.0.0.1:18789"
AUTH_TOKEN = "f5269db2521921796c7645e93a993d233cf2e4cf5ce483a6"

async def test_auth_methods():
    """Test different authentication methods"""
    
    print("=" * 70)
    print("🔐 Testing OpenClaw Gateway Authentication")
    print("=" * 70)
    
    # Method 1: Token in URL params
    print("\n📝 Method 1: Token as URL parameter")
    try:
        uri = f"{GATEWAY_URL}?token={AUTH_TOKEN}"
        print(f"   Trying: {uri[:50]}...")
        async with websockets.connect(uri, ping_interval=20) as ws:
            print("   ✅ Connected!")
            
            # Try sending a test message
            test_msg = {"type": "ping"}
            await ws.send(json.dumps(test_msg))
            print("   📤 Sent ping")
            
            try:
                response = await asyncio.wait_for(ws.recv(), timeout=3.0)
                print(f"   📥 Response: {response[:100]}")
            except asyncio.TimeoutError:
                print("   ⏱️  No response (timeout)")
                
    except Exception as e:
        print(f"   ❌ Failed: {e}")
    
    # Method 2: Token in Authorization header
    print("\n📝 Method 2: Token in Authorization header (Bearer)")
    try:
        headers = {"Authorization": f"Bearer {AUTH_TOKEN}"}
        print(f"   Headers: Authorization: Bearer {AUTH_TOKEN[:20]}...")
        async with websockets.connect(GATEWAY_URL, extra_headers=headers, ping_interval=20) as ws:
            print("   ✅ Connected!")
            
            # Try sending a test message
            test_msg = {"type": "ping"}
            await ws.send(json.dumps(test_msg))
            print("   📤 Sent ping")
            
            try:
                response = await asyncio.wait_for(ws.recv(), timeout=3.0)
                print(f"   📥 Response: {response[:100]}")
            except asyncio.TimeoutError:
                print("   ⏱️  No response (timeout)")
                
    except Exception as e:
        print(f"   ❌ Failed: {e}")
    
    # Method 3: Token in first message
    print("\n📝 Method 3: Token in initial handshake message")
    try:
        print(f"   Connecting to: {GATEWAY_URL}")
        async with websockets.connect(GATEWAY_URL, ping_interval=20) as ws:
            print("   ✅ Connected!")
            
            # Send auth message first
            auth_msg = {
                "type": "auth",
                "token": AUTH_TOKEN
            }
            await ws.send(json.dumps(auth_msg))
            print("   📤 Sent auth message")
            
            try:
                response = await asyncio.wait_for(ws.recv(), timeout=3.0)
                print(f"   📥 Response: {response[:100]}")
            except asyncio.TimeoutError:
                print("   ⏱️  No response (timeout)")
                
    except Exception as e:
        print(f"   ❌ Failed: {e}")
    
    # Method 4: Token in connect.params
    print("\n📝 Method 4: Token in connect params")
    try:
        print(f"   Connecting to: {GATEWAY_URL}")
        async with websockets.connect(GATEWAY_URL, ping_interval=20) as ws:
            print("   ✅ Connected!")
            
            # Send connect with params
            connect_msg = {
                "method": "connect",
                "params": {
                    "auth": {
                        "token": AUTH_TOKEN
                    }
                }
            }
            await ws.send(json.dumps(connect_msg))
            print("   📤 Sent connect message with auth.token")
            
            try:
                response = await asyncio.wait_for(ws.recv(), timeout=5.0)
                print(f"   📥 Response: {response}")
                
                # Try sending a command after auth
                cmd_msg = {
                    "method": "gateway.agent.send",
                    "params": {
                        "message": "what time is it",
                        "sessionId": "test_session"
                    },
                    "id": 1
                }
                await ws.send(json.dumps(cmd_msg))
                print("   📤 Sent test command")
                
                response2 = await asyncio.wait_for(ws.recv(), timeout=10.0)
                print(f"   📥 Command response: {response2}")
                
            except asyncio.TimeoutError:
                print("   ⏱️  No response (timeout)")
                
    except Exception as e:
        print(f"   ❌ Failed: {e}")
    
    print("\n" + "=" * 70)

if __name__ == "__main__":
    asyncio.run(test_auth_methods())

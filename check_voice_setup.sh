#!/bin/bash

echo "=================================="
echo "Voice Commands Setup Verification"
echo "=================================="
echo ""

# Check if backend is running
echo "[1/5] Checking if backend is running..."
if lsof -ti:8000 > /dev/null 2>&1; then
    echo "✅ Backend is running on port 8000"
else
    echo "❌ Backend is NOT running"
    echo "   Start it with: ./start_backend.sh"
fi
echo ""

# Check if OpenClaw is running
echo "[2/5] Checking if OpenClaw Gateway is running..."
if lsof -ti:18789 > /dev/null 2>&1; then
    echo "✅ OpenClaw Gateway is running on port 18789"
    PID=$(lsof -ti:18789)
    echo "   PID: $PID"
else
    echo "❌ OpenClaw Gateway is NOT running"
    echo "   Start it with: openclaw gateway --port 18789"
fi
echo ""

# Test voice status API
echo "[3/5] Testing voice status API..."
if curl -s -f http://localhost:8000/api/voice/status > /dev/null 2>&1; then
    echo "✅ Voice API is responding"
    STATUS=$(curl -s http://localhost:8000/api/voice/status | python3 -m json.tool 2>/dev/null || echo "")
    if [ ! -z "$STATUS" ]; then
        echo "$STATUS" | head -10
    fi
else
    echo "❌ Voice API is not responding"
fi
echo ""

# Check Flutter dependencies
echo "[4/5] Checking Flutter widget files..."
if [ -f "lib/widgets/jarvis_trigger_overlay.dart" ]; then
    echo "✅ Jarvis trigger overlay widget exists"
else
    echo "❌ Jarvis trigger overlay widget NOT found"
fi

if [ -f "lib/widgets/voice_command_indicator.dart" ]; then
    echo "✅ Voice command indicator widget exists"
else
    echo "❌ Voice command indicator widget NOT found"
fi
echo ""

# Check backend files
echo "[5/5] Checking backend files..."
if [ -f "backend/openclaw_bridge.py" ]; then
    echo "✅ OpenClaw bridge exists"
else
    echo "❌ OpenClaw bridge NOT found"
fi

if [ -f "backend/voice_commands.py" ]; then
    echo "✅ Voice commands handler exists"
else
    echo "❌ Voice commands handler NOT found"
fi
echo ""

echo "=================================="
echo "Summary"
echo "=================================="
echo ""
echo "To enable voice commands:"
echo "1. Start backend (if not running): ./start_backend.sh"
echo "2. Run Flutter app: flutter run -d macos"
echo "3. Toggle voice assistant ON in the UI"
echo "4. Say 'Jarvis' to trigger the overlay"
echo "5. Speak your command (e.g., 'create a website for me')"
echo ""
echo "To test UI overlays without voice:"
echo "  python backend/test_voice_events.py"
echo "  (Connect Flutter app to ws://localhost:8001/ws)"
echo ""

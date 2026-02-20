#!/bin/bash
# Test Jarvis Integration - Verify Everything Works

echo "======================================================"
echo "🧪 Testing Jarvis Integration"
echo "======================================================"
echo ""

# Check if backend is running
echo "1️⃣  Checking backend..."
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo "   ✅ Backend is running"
else
    echo "   ❌ Backend is NOT running"
    echo "   Run: ./start_backend.sh"
    exit 1
fi

# Check Jarvis status endpoint
echo ""
echo "2️⃣  Checking Jarvis status endpoint..."
STATUS=$(curl -s http://localhost:8000/api/jarvis/status)
echo "   Response: $STATUS"

# Check if Flutter app is running
echo ""
echo "3️⃣  Checking if Flutter app is running..."
if pgrep -f "flutter_tools.*debug" > /dev/null; then
    echo "   ✅ Flutter app is running"
else
    echo "   ⚠️  Flutter app might not be running"
    echo "   Run: flutter run -d macos"
fi

echo ""
echo "======================================================"
echo "✅ Integration Check Complete!"
echo "======================================================"
echo ""
echo "📍 WHERE TO FIND JARVIS:"
echo "   1. Open your Flutter app"
echo "   2. You'll see it on the DASHBOARD (right panel)"
echo "   3. Look for 'Jarvis Voice Assistant' card"
echo "   4. Toggle the switch ON"
echo ""
echo "🗣️  HOW TO TEST:"
echo "   1. Toggle Jarvis ON in the app"
echo "   2. Wait for 'Listening for wake word'"
echo "   3. Say: 'Jarvis'"
echo "   4. Say: 'What time is it?'"
echo "   5. Watch the conversation appear in the UI!"
echo ""
echo "💡 The conversation will show:"
echo "   - Your speech in BLUE bubbles"
echo "   - Jarvis responses in GRAY bubbles"
echo "   - Status updates in the middle"
echo ""

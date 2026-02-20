#!/bin/bash
# Quick Demo: Test Jarvis Voice Integration

echo "======================================================"
echo "🎙️  JARVIS VOICE ASSISTANT - QUICK TEST"
echo "======================================================"
echo ""
echo "This will test if Jarvis is working standalone"
echo "Press Ctrl+C to stop"
echo ""

cd "$(dirname "$0")"

# Activate virtual environment
source voice_env/bin/activate

# Run Jarvis
python jarvis_voice.py

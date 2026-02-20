#!/bin/bash

# ============================================================================
# Voice Assistant Setup Script for GDI
# ============================================================================

set -e  # Exit on error

echo "🎙️  GDI Voice Assistant Setup"
echo "================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if running on macOS, Linux, or Windows (WSL)
OS="$(uname -s)"
case "${OS}" in
    Darwin*)    PLATFORM="macOS";;
    Linux*)     PLATFORM="Linux";;
    CYGWIN*|MINGW*|MSYS*) PLATFORM="Windows";;
    *)          PLATFORM="Unknown";;
esac

echo -e "${GREEN}Detected platform: ${PLATFORM}${NC}"
echo ""

# ── Step 1: Check Python ────────────────────────────────────────────────────

echo "📦 Checking Python installation..."
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python 3 not found. Please install Python 3.8 or higher.${NC}"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
echo -e "${GREEN}✅ Python ${PYTHON_VERSION} found${NC}"
echo ""

# ── Step 2: Install system dependencies ─────────────────────────────────────

echo "🔧 Installing system dependencies..."

if [ "$PLATFORM" = "macOS" ]; then
    if ! command -v brew &> /dev/null; then
        echo -e "${YELLOW}⚠️  Homebrew not found. Install from https://brew.sh/${NC}"
    else
        echo "Installing PortAudio via Homebrew..."
        brew install portaudio || true
        echo -e "${GREEN}✅ PortAudio installed${NC}"
    fi
    
elif [ "$PLATFORM" = "Linux" ]; then
    echo "Installing PortAudio development files..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y portaudio19-dev python3-pyaudio
    elif command -v yum &> /dev/null; then
        sudo yum install -y portaudio-devel
    fi
    echo -e "${GREEN}✅ System dependencies installed${NC}"
fi

echo ""

# ── Step 3: Create virtual environment ──────────────────────────────────────

echo "🐍 Setting up Python virtual environment..."

cd backend

if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo -e "${GREEN}✅ Virtual environment created${NC}"
else
    echo -e "${YELLOW}⚠️  Virtual environment already exists${NC}"
fi

# Activate virtual environment
if [ "$PLATFORM" = "Windows" ]; then
    source venv/Scripts/activate
else
    source venv/bin/activate
fi

echo ""

# ── Step 4: Install Python packages ─────────────────────────────────────────

echo "📚 Installing Python packages..."

pip install --upgrade pip
pip install -r requirements.txt

echo -e "${GREEN}✅ Python packages installed${NC}"
echo ""

# ── Step 5: Create .env file ────────────────────────────────────────────────

echo "⚙️  Setting up environment configuration..."

if [ ! -f ".env" ]; then
    cp .env.example .env
    echo -e "${GREEN}✅ .env file created${NC}"
    echo -e "${YELLOW}📝 Please edit backend/.env to configure your settings${NC}"
else
    echo -e "${YELLOW}⚠️  .env file already exists${NC}"
fi

echo ""

# ── Step 6: Test voice assistant ────────────────────────────────────────────

echo "🧪 Testing voice assistant components..."

# Test speech recognition
echo "Testing SpeechRecognition..."
python3 -c "import speech_recognition as sr; print('✅ SpeechRecognition OK')" || echo -e "${RED}❌ SpeechRecognition failed${NC}"

# Test TTS
echo "Testing pyttsx3..."
python3 -c "import pyttsx3; print('✅ pyttsx3 OK')" || echo -e "${RED}❌ pyttsx3 failed${NC}"

# Test PyAudio
echo "Testing PyAudio..."
python3 -c "import pyaudio; print('✅ PyAudio OK')" || echo -e "${RED}❌ PyAudio failed - see troubleshooting guide${NC}"

echo ""

# ── Step 7: OpenClaw check ──────────────────────────────────────────────────

echo "🦞 Checking for OpenClaw..."

if command -v openclaw &> /dev/null; then
    OPENCLAW_VERSION=$(openclaw --version 2>&1 || echo "unknown")
    echo -e "${GREEN}✅ OpenClaw found: ${OPENCLAW_VERSION}${NC}"
    echo ""
    echo "To start OpenClaw Gateway:"
    echo "  openclaw gateway --port 18789"
else
    echo -e "${YELLOW}⚠️  OpenClaw not found${NC}"
    echo ""
    echo "Install OpenClaw for advanced AI capabilities:"
    echo "  npm install -g openclaw@latest"
    echo ""
    echo "Or continue with basic voice commands (limited features)"
fi

echo ""

# ── Step 8: Summary ─────────────────────────────────────────────────────────

echo "================================"
echo -e "${GREEN}✨ Voice Assistant Setup Complete!${NC}"
echo "================================"
echo ""
echo "Next steps:"
echo ""
echo "1. Configure your settings:"
echo "   ${YELLOW}nano backend/.env${NC}"
echo ""
echo "2. (Optional) Get Porcupine access key:"
echo "   https://console.picovoice.ai/"
echo ""
echo "3. (Optional) Start OpenClaw Gateway:"
echo "   ${YELLOW}openclaw gateway --port 18789${NC}"
echo ""
echo "4. Start GDI backend:"
echo "   ${YELLOW}cd backend${NC}"
echo "   ${YELLOW}source venv/bin/activate${NC}"
echo "   ${YELLOW}python main.py${NC}"
echo ""
echo "5. Start Flutter app:"
echo "   ${YELLOW}flutter run -d macos${NC}"
echo ""
echo "6. Enable voice assistant in the app and say:"
echo "   ${GREEN}'Jarvis, hello'${NC}"
echo ""
echo "📖 For detailed documentation, see:"
echo "   VOICE_ASSISTANT_SETUP.md"
echo ""

# Deactivate virtual environment
deactivate 2>/dev/null || true

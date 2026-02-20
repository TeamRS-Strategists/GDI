# GestureFlow Setup and Run Guide

This guide provides a clean setup and run flow for GestureFlow on macOS.

## 1) Prerequisites
- macOS with camera and microphone permissions
- Python 3.10+
- Flutter SDK (desktop enabled)
- Xcode command line tools

Verify:
- `python3 --version`
- `flutter --version`
- `flutter config --enable-macos-desktop`

## 2) Go to project root
- `cd /Users/siddhantparashar/projects/GDI`

## 3) Backend environments
This repo currently uses:
- `.venv` for backend startup script (`start_backend.sh`)
- `voice_env` for Jarvis runtime (`jarvis_voice.py` via `jarvis_service.py`)

### 3.1 Create `.venv`
- `python3 -m venv .venv`
- `source .venv/bin/activate`
- `pip install -r backend/requirements.txt`

### 3.2 Create `voice_env`
- `python3 -m venv voice_env`
- `source voice_env/bin/activate`
- `pip install SpeechRecognition pyaudio pyttsx3 pyobjc websockets`

## 4) Frontend setup
From project root:
- `flutter pub get`

## 5) Start OpenClaw
If you use OpenClaw-backed voice/testing flows, start OpenClaw before backend/frontend.

Open a terminal and run:
- `openclaw gateway --port 18789`

Quick check (separate terminal):
- `openclaw agent --message "what time is it" --session-id test_voice --json`

If OpenClaw auto-restarts and you want to stop it:
- `launchctl bootout gui/$(id -u) ai.openclaw.gateway || launchctl remove ai.openclaw.gateway`

## 6) Run the project
Open two terminals at project root.

### Terminal A (backend)
- `./start_backend.sh`

Expected backend URL:
- `http://127.0.0.1:8000`

### Terminal B (frontend)
- `flutter run -d macos`

## 7) Verify Jarvis flow
- Turn ON Jarvis in dashboard panel
- Say “Jarvis”
- Speak command
- You should see chat-style messages (You / Jarvis) and hear voice output

## 8) Useful API checks
- `curl -s http://127.0.0.1:8000/api/jarvis/status`
- `curl -s "http://127.0.0.1:8000/api/jarvis/events?since_id=0&limit=20"`

## 9) Troubleshooting
### Port 8000 already in use
- `lsof -i :8000`
- stop old process, then restart backend

### Jarvis speaking but no frontend chat
- confirm backend is running latest code
- hot restart Flutter app
- verify `/api/jarvis/events` returns events

### PyAudio install issue
Install missing macOS audio/build dependencies, then reinstall in `voice_env`.

## 10) Product-ready checklist
- Backend running on `127.0.0.1:8000`
- Frontend connected and rendering camera feed
- Camera/mic permissions granted
- Jarvis panel shows live state + chat messages

"""
main.py — The Interface
FastAPI WebSocket server for GestureFlow.

Start with:
    uvicorn main:app --host 0.0.0.0 --port 8000
"""

import asyncio
import json
import logging
import time

import cv2
import numpy as np
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional

from vision import create_hand_landmarker, process_frame, normalize_landmarks
from model import GestureClassifier
from controller import DesktopController
from mouse_engine import MouseController
from gesture_config import GestureConfigStore
from voice_assistant import create_voice_assistant, VoiceCommand, VoiceState
from openclaw_bridge import OpenClawBridge, is_openclaw_running
from jarvis_service import JarvisService

# ── Logging ──────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(name)-18s  %(levelname)-5s  %(message)s",
)
logger = logging.getLogger(__name__)

# ── FastAPI app ──────────────────────────────────────────────────────────────
app = FastAPI(title="GestureFlow Backend", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Shared state (one instance per process) ──────────────────────────────────
gesture_model = GestureClassifier()
config_store = GestureConfigStore()
desktop_ctrl = DesktopController(gesture_map=config_store.build_gesture_map())
mouse_ctrl = MouseController()

# Voice assistant and OpenClaw bridge (optional features)
voice_assistant = None
openclaw_bridge = None
voice_enabled = False

# Jarvis conversational voice assistant
jarvis_service: Optional[JarvisService] = None

# Connected WebSocket clients for broadcasting
active_websockets = set()

# Try to load a previously saved model
gesture_model.load_model()


# ── Voice Event Broadcasting ─────────────────────────────────────────────────

async def broadcast_voice_event(event_type: str, data: dict):
    """Broadcast voice events to all connected WebSocket clients."""
    message = {"type": event_type, "data": data}
    disconnected = set()
    
    logger.info(f"📡 Broadcasting {event_type}")
    logger.info(f"📦 Full message: {message}")
    logger.info(f"👥 Active WebSocket clients: {len(active_websockets)}")
    
    for ws in active_websockets:
        try:
            await ws.send_json(message)
            logger.info(f"✅ Sent to client: {message}")
        except Exception as e:
            logger.error(f"❌ Error broadcasting to websocket: {e}")
            disconnected.add(ws)
    
    # Clean up disconnected clients
    active_websockets.difference_update(disconnected)
    if disconnected:
        logger.info(f"🧹 Cleaned up {len(disconnected)} disconnected clients")


# ── Pydantic models for REST API ─────────────────────────────────────────────
class GestureConfigBody(BaseModel):
    name: str
    action_type: str = "preset"  # "preset" or "keyboard"
    action: str = ""
    keys: str = ""


# ── REST API endpoints ───────────────────────────────────────────────────────

@app.get("/api/gestures")
def get_gestures():
    """Return all gesture configs."""
    return {"gestures": config_store.get_all()}


@app.post("/api/gestures")
def upsert_gesture(body: GestureConfigBody):
    """Add or update a gesture config."""
    config_store.upsert(body.name, body.action_type, body.action, body.keys)
    # Rebuild controller's live mapping
    desktop_ctrl.gesture_map = config_store.build_gesture_map()
    return {"status": "ok", "gesture": body.name}


@app.delete("/api/gestures/{name}")
def delete_gesture(name: str):
    """Delete a gesture config."""
    found = config_store.delete(name)
    if found:
        desktop_ctrl.gesture_map = config_store.build_gesture_map()
    return {"status": "ok" if found else "not_found", "gesture": name}


# ── Voice Assistant API endpoints ────────────────────────────────────────────

@app.get("/api/voice/status")
async def get_voice_status():
    """Get voice assistant status."""
    global voice_assistant, voice_enabled, openclaw_bridge
    
    openclaw_running = False
    if openclaw_bridge:
        openclaw_running = openclaw_bridge.connected
    else:
        # Check if OpenClaw Gateway is accessible
        try:
            openclaw_running = await is_openclaw_running()
        except:
            pass
    
    return {
        "enabled": voice_enabled,
        "state": voice_assistant.state.value if voice_assistant else "disabled",
        "openclaw_connected": openclaw_running,
        "wake_word": "jarvis" if voice_assistant else None,
        "features": {
            "speech_recognition": voice_assistant is not None,
            "tts": voice_assistant.tts_engine is not None if voice_assistant else False,
            "openclaw": openclaw_running
        }
    }


@app.post("/api/voice/start")
async def start_voice_assistant():
    """Start the voice assistant."""
    global voice_assistant, voice_enabled, openclaw_bridge
    
    if voice_enabled and voice_assistant:
        return {"status": "already_running"}
    
    try:
        # Initialize voice assistant
        voice_assistant = create_voice_assistant(
            wake_word="jarvis",
            language="en-US",
            timeout=5,
            enable_tts=True
        )
        
        if not voice_assistant:
            return {"status": "error", "message": "Failed to create voice assistant"}
        
        # Set up wake word detection callback
        async def on_wake_word():
            logger.info("🎤 Wake word 'Jarvis' detected!")
            await broadcast_voice_event("voice_wake_detected", {
                "wake_word": "jarvis",
                "voice_state": "listening"
            })
        
        # Set up command callback
        async def on_voice_command(cmd: VoiceCommand):
            logger.info(f"Voice command received: {cmd.text}")
            # Queue command for processing
            asyncio.create_task(process_voice_command(cmd))
        
        # Register callbacks
        voice_assistant.on_wake_word = on_wake_word
        voice_assistant.on_command = on_voice_command
        
        # Start listening
        voice_assistant.start()
        voice_enabled = True
        
        # Try to connect to OpenClaw if available
        try:
            openclaw_bridge = OpenClawBridge()
            connected = await openclaw_bridge.connect()
            if connected:
                logger.info("Connected to OpenClaw Gateway")
            else:
                logger.warning("OpenClaw Gateway not available - voice commands will use basic execution")
        except Exception as e:
            logger.warning(f"Could not connect to OpenClaw: {e}")
        
        return {
            "status": "started",
            "wake_word": "jarvis",
            "openclaw_connected": openclaw_bridge.connected if openclaw_bridge else False
        }
        
    except Exception as e:
        logger.error(f"Failed to start voice assistant: {e}")
        return {"status": "error", "message": str(e)}


@app.post("/api/voice/stop")
def stop_voice_assistant():
    """Stop the voice assistant."""
    global voice_assistant, voice_enabled, openclaw_bridge
    
    if not voice_enabled or not voice_assistant:
        return {"status": "not_running"}
    
    try:
        voice_assistant.stop()
        voice_enabled = False
        
        # Disconnect from OpenClaw
        if openclaw_bridge:
            asyncio.create_task(openclaw_bridge.disconnect())
        
        return {"status": "stopped"}
        
    except Exception as e:
        logger.error(f"Failed to stop voice assistant: {e}")
        return {"status": "error", "message": str(e)}


# ── Jarvis Voice Assistant API endpoints ────────────────────────────────────

@app.get("/api/jarvis/status")
async def get_jarvis_status():
    """Get Jarvis voice assistant status."""
    global jarvis_service
    
    if not jarvis_service:
        return {
            "is_running": False,
            "state": "idle",
            "available": True
        }
    
    return jarvis_service.get_status()


@app.get("/api/jarvis/events")
async def get_jarvis_events(since_id: int = 0, limit: int = 200):
    """Get recent Jarvis events for polling fallback on frontend."""
    global jarvis_service

    if not jarvis_service:
        return {
            "events": [],
            "last_event_id": since_id,
        }

    events = jarvis_service.get_events(since_id=since_id, limit=limit)
    last_event_id = since_id
    if events:
        last_event_id = events[-1].get("id", since_id)

    return {
        "events": events,
        "last_event_id": last_event_id,
    }


@app.post("/api/jarvis/start")
async def start_jarvis():
    """Start Jarvis conversational voice assistant."""
    global jarvis_service
    
    try:
        # Create service if not exists
        if not jarvis_service:
            jarvis_service = JarvisService(broadcast_callback=broadcast_voice_event)
        
        # Start Jarvis
        result = await jarvis_service.start()
        return result
        
    except Exception as e:
        logger.error(f"Error starting Jarvis: {e}")
        return {"status": "error", "message": str(e)}


@app.post("/api/jarvis/stop")
async def stop_jarvis():
    """Stop Jarvis voice assistant."""
    global jarvis_service
    
    if not jarvis_service:
        return {"status": "not_running"}
    
    try:
        result = await jarvis_service.stop()
        return result
    except Exception as e:
        logger.error(f"Error stopping Jarvis: {e}")
        return {"status": "error", "message": str(e)}


@app.get("/api/voice/commands")
def get_voice_commands():
    """Get pending voice commands from the queue."""
    global voice_assistant
    
    if not voice_assistant:
        return {"commands": []}
    
    commands = voice_assistant.get_pending_commands()
    return {
        "commands": [
            {
                "text": cmd.text,
                "confidence": cmd.confidence,
                "timestamp": cmd.timestamp,
                "language": cmd.language
            }
            for cmd in commands
        ]
    }


async def process_voice_command(cmd: VoiceCommand):
    """
    Process a voice command - send to OpenClaw or execute locally.
    
    Args:
        cmd: Voice command to process
    """
    global openclaw_bridge
    
    try:
        logger.info(f"Processing voice command: '{cmd.text}'")
        
        # Broadcast that command was received
        await broadcast_voice_event("voice_command", {
            "command": cmd.text,
            "voice_state": "processing"
        })
        
        # If OpenClaw is connected, send command there
        if openclaw_bridge and openclaw_bridge.connected:
            result = await openclaw_bridge.execute_command(cmd.text)
            logger.info(f"OpenClaw result: {result}")
            
            # Broadcast completion
            if "error" not in result:
                await broadcast_voice_event("voice_response", {
                    "command": cmd.text,
                    "response": result.get("response", "Command executed successfully"),
                    "voice_state": "idle"
                })
            else:
                await broadcast_voice_event("voice_response", {
                    "command": cmd.text,
                    "response": f"Error: {result['error']}",
                    "voice_state": "error"
                })
            
            # Provide audio feedback
            if voice_assistant and voice_assistant.enable_tts:
                if "error" not in result:
                    voice_assistant.speak("Command executed")
                else:
                    voice_assistant.speak("Command failed")
        
        else:
            # Fallback: execute simple commands locally
            response = await execute_local_voice_command(cmd.text)
            await broadcast_voice_event("voice_response", {
                "command": cmd.text,
                "response": response,
                "voice_state": "idle"
            })

            await execute_local_voice_command(cmd.text)
            
    except Exception as e:
        logger.error(f"Error processing voice command: {e}")
        if voice_assistant:
            voice_assistant.speak("Sorry, something went wrong")


async def execute_local_voice_command(command_text: str):
    """
    Execute simple voice commands locally without OpenClaw.
    
    Args:
        command_text: Command text to execute
    """
    cmd_lower = command_text.lower()
    
    # Simple command patterns
    if "hello" in cmd_lower or "hi" in cmd_lower:
        if voice_assistant:
            voice_assistant.speak("Hello! How can I help you?")
    
    elif "gesture" in cmd_lower and "status" in cmd_lower:
        gestures = config_store.get_all()
        count = len(gestures)
        if voice_assistant:
            voice_assistant.speak(f"You have {count} gestures configured")
    
    elif "mouse" in cmd_lower:
        if "enable" in cmd_lower or "on" in cmd_lower:
            desktop_ctrl.enabled = True
            if voice_assistant:
                voice_assistant.speak("Mouse control enabled")
        elif "disable" in cmd_lower or "off" in cmd_lower:
            desktop_ctrl.enabled = False
            if voice_assistant:
                voice_assistant.speak("Mouse control disabled")
    
    else:
        # Unknown command
        logger.warning(f"Unknown local voice command: {command_text}")
        if voice_assistant:
            voice_assistant.speak("I don't know how to do that yet. Try connecting to OpenClaw for more features.")


# ── Constants ────────────────────────────────────────────────────────────────
TARGET_FPS = 60
FRAME_INTERVAL = 1.0 / TARGET_FPS   # ~16 ms
PROCESS_EVERY_N = 1  # Process every frame for lowest latency


# ── Helpers ──────────────────────────────────────────────────────────────────

def _open_camera(index: int = 0) -> cv2.VideoCapture:
    """Open the webcam and configure it for low-latency capture."""
    cap = cv2.VideoCapture(index)
    if not cap.isOpened():
        raise RuntimeError(f"Cannot open camera index {index}")
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
    cap.set(cv2.CAP_PROP_FPS, 60)
    cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
    logger.info("Camera %d opened  (%dx%d)", index, 640, 480)
    return cap


def _landmarks_to_list(hand_lms) -> list:
    """Convert MediaPipe NormalizedLandmarks to a list of [x, y] pairs."""
    return [[round(lm.x, 4), round(lm.y, 4)] for lm in hand_lms]


# ── WebSocket endpoint ──────────────────────────────────────────────────────

@app.websocket("/ws")
async def websocket_endpoint(ws: WebSocket):
    await ws.accept()
    logger.info("Client connected")
    
    # Register this WebSocket for voice event broadcasting
    active_websockets.add(ws)

    # Per-connection state
    training_mode = False
    training_label: str = ""
    mouse_enabled = True

    # Create a HandLandmarker for this connection
    landmarker = create_hand_landmarker()

    try:
        cap = await asyncio.to_thread(_open_camera)
    except RuntimeError as exc:
        await ws.send_json({"error": str(exc)})
        await ws.close()
        active_websockets.discard(ws)
        return

    frame_count = 0
    # Monotonic timestamp counter for MediaPipe (must be strictly increasing)
    timestamp_counter = 0
    # Training frame tracking
    target_frames = 200
    frames_captured = 0
    
    # QC State
    prev_wrist_coords = None  # (x, y) of wrist from previous frame
    QC_VELOCITY_THRESHOLD = 0.3  # Max allowed distance per frame (tunable)

    # Cache last result for skipped frames
    last_payload = {
        "gesture": "None",
        "confidence": 0.0,
        "landmarks": None,
        "status": "active",
    }

    try:
        while True:
            loop_start = time.time()

            # ── 1. Check for incoming client commands (non-blocking) ─────
            try:
                raw = await asyncio.wait_for(ws.receive_text(), timeout=0.001)
                msg = json.loads(raw)
                cmd = msg.get("command")

                if cmd == "start_training":
                    training_mode = True
                    training_label = msg.get("label", "gesture")
                    target_frames = msg.get("target_frames", 200)
                    frames_captured = 0
                    prev_wrist_coords = None  # Reset QC state
                    logger.info(
                        "Training started for label: %s (target: %d frames)",
                        training_label, target_frames,
                    )

                elif cmd == "stop_training":
                    training_mode = False
                    gesture_model.train()
                    gesture_model.save_model()
                    logger.info("Training stopped — model retrained & saved")
                    await ws.send_json({"status": "training_complete"})

                elif cmd == "save_model":
                    gesture_model.save_model()
                    await ws.send_json({"status": "model_saved"})

                elif cmd == "toggle_mouse":
                    mouse_enabled = not mouse_enabled
                    logger.info("Mouse control %s", "enabled" if mouse_enabled else "disabled")

                elif cmd == "update_mapping":
                    gesture = msg.get("gesture", "")
                    action = msg.get("action", "")
                    action_type = msg.get("action_type", "preset")
                    keys = msg.get("keys", "")
                    if gesture and (action or keys):
                        # Persist to config store
                        config_store.upsert(gesture, action_type, action, keys)
                        desktop_ctrl.gesture_map = config_store.build_gesture_map()
                        await ws.send_json({"status": "mapping_updated", "gesture": gesture, "action": action})

            except asyncio.TimeoutError:
                pass  # no message — continue to next frame
            except json.JSONDecodeError:
                logger.warning("Received non-JSON message, ignoring")

            # ── 2. Capture frame (blocking → thread) ─────────────────────
            ret, frame = await asyncio.to_thread(cap.read)
            if not ret:
                logger.warning("Frame capture failed — retrying")
                await asyncio.sleep(FRAME_INTERVAL)
                continue

            # Flip horizontally for mirror effect
            frame = cv2.flip(frame, 1)
            frame_count += 1

            # ── 3. Frame skipping — only process every Nth frame ─────────
            #    During training, process ALL frames (we need every sample).
            #    During prediction, skip frames to save CPU.
            if not training_mode and (frame_count % PROCESS_EVERY_N != 0):
                # Send cached result for skipped frames
                await ws.send_json(last_payload)
                elapsed = time.time() - loop_start
                await asyncio.sleep(max(0, FRAME_INTERVAL - elapsed))
                continue

            # ── 4. Process frame with MediaPipe (blocking → thread) ──────
            timestamp_counter += 1
            result = await asyncio.to_thread(
                process_frame, landmarker, frame, timestamp_counter
            )

            has_hand = len(result.hand_landmarks) > 0

            if not has_hand:
                # No hand detected
                status = "hand_lost" if training_mode else "active"
                
                payload = {
                    "gesture": "None",
                    "confidence": 0.0,
                    "landmarks": None,
                    "status": status,
                    "frames_captured": frames_captured if training_mode else 0,
                }
                last_payload = payload
                await ws.send_json(payload)
                
                # Reset QC state if hand is lost
                if training_mode:
                    prev_wrist_coords = None
                    
                elapsed = time.time() - loop_start
                await asyncio.sleep(max(0, FRAME_INTERVAL - elapsed))
                continue

            # First hand's landmarks (list of 21 NormalizedLandmark)
            hand_lms = result.hand_landmarks[0]

            # ── 5. Normalise landmarks for the model ─────────────────────
            norm = normalize_landmarks(hand_lms)

            # ── 6. Mouse control (runs before KNN, on raw lms) ───────────
            if mouse_enabled and not training_mode:
                mouse_ctrl.process_hand(hand_lms)

            # ── 7. Training vs. Prediction ───────────────────────────────
            gesture_label = "None"
            confidence = 0.0

            status = "active"

            if training_mode:
                # QC: Velocity Check (Motion Blur Prevention)
                wrist = hand_lms[0]
                current_wrist_coords = (wrist.x, wrist.y)
                
                is_moving_too_fast = False
                if prev_wrist_coords is not None:
                    dist = np.linalg.norm(np.array(current_wrist_coords) - np.array(prev_wrist_coords))
                    if dist > QC_VELOCITY_THRESHOLD:
                        is_moving_too_fast = True
                
                prev_wrist_coords = current_wrist_coords
                
                if is_moving_too_fast:
                    status = "moving_too_fast"
                    gesture_label = "None"
                    # Do NOT save frame, do NOT increment counter
                else:
                    status = "tracking"
                    gesture_model.add_sample(training_label, norm)
                    frames_captured += 1
                    gesture_label = training_label
                    confidence = 1.0

                    # Auto-stop when target reached
                    if frames_captured >= target_frames:
                        training_mode = False
                        gesture_model.train()
                        gesture_model.save_model()
                        logger.info(
                            "Auto-stopped training after %d frames — model retrained",
                            frames_captured,
                        )
                        # We will send "training_complete" at the end of the loop
            else:
                pred = gesture_model.predict(norm)
                gesture_label = pred["label"]
                confidence = pred["confidence"]

                # Trigger desktop action (blocking subprocess → thread)
                triggered_action = None
                if gesture_label not in ("Unknown", "None"):
                    action_name = desktop_ctrl.gesture_map.get(gesture_label)
                    success = await asyncio.to_thread(desktop_ctrl.execute, gesture_label)
                    if success:
                        triggered_action = action_name

            # ── 8. Build & send lightweight payload ──────────────────────
            landmarks_list = _landmarks_to_list(hand_lms)

            payload = {
                "gesture": gesture_label,
                "confidence": round(confidence, 4),
                "landmarks": landmarks_list,
                "status": status,
            }

            # Include the action name when one was triggered
            if not training_mode and triggered_action is not None:
                payload["action"] = triggered_action

            # Include frame counts during/after training
            if frames_captured > 0:
                payload["frames_captured"] = frames_captured
                payload["target_frames"] = target_frames

            # Send training_complete AFTER the payload with final frame count
            if frames_captured >= target_frames and not training_mode:
                await ws.send_json(payload)
                await ws.send_json({"status": "training_complete"})
                frames_captured = 0  # Reset so we stop sending counts
                elapsed = time.time() - loop_start
                await asyncio.sleep(max(0, FRAME_INTERVAL - elapsed))
                continue

            last_payload = payload
            await ws.send_json(payload)

            # ── 9. Frame-rate throttle ───────────────────────────────────
            elapsed = time.time() - loop_start
            await asyncio.sleep(max(0, FRAME_INTERVAL - elapsed))

    except WebSocketDisconnect:
        logger.info("Client disconnected")
    except Exception as exc:
        logger.exception("WebSocket error: %s", exc)
    finally:
        # Remove from active websockets
        active_websockets.discard(ws)
        cap.release()
        landmarker.close()
        logger.info("Camera and landmarker released")


# ── Health check ─────────────────────────────────────────────────────────────

@app.get("/health")
async def health():
    return {"status": "ok"}

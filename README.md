# GestureFlow: Gesture-Based Desktop Control System

## Overview

GestureFlow is an interactive product that allows users to control their desktop environment using customizable hand gestures. The system merges real-time computer vision with a highly polished, UX-focused desktop interface. It is built to feel like a seamless product rather than a technical prototype , ensuring that adding, modifying, or monitoring gestures is intuitive for non-technical users.

## ✨ Key Features

* 
**Customizable Gesture Library:** Add new hand gestures or remove existing ones through a guided, 3-phase snapshot capture process.


* 
**Instant Model Retraining:** Utilize a lightweight K-Nearest Neighbors (KNN) architecture for "One-Click" model retraining. The system updates instantly without heavy processing delays.


* 
**Desktop Automation:** Map gestures to OS-level actions, including switching tabs, media playback controls (pause/play, next), and system shortcuts.


* **Native Mouse Emulation:** Deterministic cursor control mapped to the index finger, with pinch-to-click functionality active by default.
* **Smart Quality Control:** The backend actively rejects frames with motion blur or lost tracking during the training phase, preventing "garbage data" from ruining model confidence.
* 
**High-Fidelity Dashboard:** A beautifully crafted Flutter desktop client featuring a "Cyberpunk Glassmorphism" aesthetic, real-time feedback loops, and live confidence metrics.



---

## 🏗️ System Architecture

The application operates on a local Client-Server model to bypass browser sandboxing restrictions while delivering a native experience.

* 
**The Face (Frontend):** A Flutter Desktop application acts as the primary control panel. It handles state management, UI transitions, and video stream rendering.


* **The Brain & Hands (Backend):** A Python FastAPI server running locally. It captures the webcam feed, processes skeletal landmarks, predicts the gesture, and executes PyAutoGUI commands.
* **The Bridge:** High-speed WebSockets (`ws://localhost:8000/ws`) maintain a 30 FPS bi-directional stream of Base64 video frames, telemetry data, and user commands.

## 🛠️ Tech Stack

### Frontend (Desktop Client)

* **Framework:** Flutter (Windows / macOS)
* **State Management:** Provider / Riverpod
* **Networking:** `web_socket_channel`
* **UI/UX:** Custom Glassmorphism styling, Lottie animations, `window_manager` for frameless window design.

### Backend (AI & OS Controller)

* **Server:** Python 3.9+, FastAPI, Uvicorn, WebSockets
* **Computer Vision:** Google MediaPipe Hands, OpenCV (`cv2`)
* **Machine Learning:** Scikit-Learn (`KNeighborsClassifier`)
* **Automation:** PyAutoGUI, Keyboard

---

## 🚀 Quick Run

From project root:

1. Start backend
```bash
./start_backend.sh
```

2. Start frontend
```bash
flutter pub get
flutter run -d macos
```

---

## 📘 Setup and Operations Guide

All setup details, environment preparation, API checks, and troubleshooting are consolidated in:

- [SETUP_AND_RUN.md](SETUP_AND_RUN.md)

---
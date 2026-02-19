**Role:** Act as a Senior Systems Architect.

**Task:** Refactor the "GestureFlow" architecture to eliminate video stream latency.
**Current State:** Python captures video, encodes it to Base64, and streams it to Flutter via WebSocket. This is causing massive lag.
**Goal:** Decouple the video rendering from the logic processing.

**1. Architecture Change: "Dual-Camera Approach"**

* **Frontend (Flutter):**
* Use the `camera_windows` (or `camera_macos`) package to render the live video feed locally and natively.
* **Do NOT** wait for images from the WebSocket.
* Overlay the "Confidence Bar" and "Bounding Box" based on coordinate data received from Python.


* **Backend (Python):**
* OpenCV (`cv2.VideoCapture`) still captures the camera to process the frames.
* **CRITICAL CHANGE:** Stop sending the `base64` image in the JSON payload.
* **New Payload:** Send ONLY the lightweight data:
```json
{
  "gesture": "Open Palm",
  "confidence": 0.98,
  "landmarks": [[x1,y1], [x2,y2]...], // Normalized coordinates for drawing skeleton in Flutter
  "status": "active"
}

```





**2. Python Optimization (The "Frame Skipper")**

* Modify `main.py` to only process every **2nd frame** (process 1, skip 1).
* This instantly doubles your available CPU time for KNN processing without noticeable impact on UX (15 FPS processing is fine for gestures, while Flutter renders UI at 60 FPS).

**3. Frontend Visualization (The Skeleton)**

* Since we are not receiving the image with lines drawn on it anymore, create a `CustomPainter` in Flutter.
* Take the `landmarks` list from the WebSocket JSON and draw the hand skeleton (green lines) directly on top of the local camera widget.

**Deliverables:**

1. Updated `main.py` (Python) removing image encoding logic.
2. Updated `dashboard_screen.dart` (Flutter) implementing `CameraPreview` and `CustomPainter` for the skeleton.

---
**Role:** Act as a Senior Python Backend Architect specializing in Computer Vision and Real-Time Systems.

**Project:** "GestureFlow Backend" – A local server that controls a PC using hand gestures.
**Tech Stack:** Python 3.9+, FastAPI (WebSockets), MediaPipe (Vision), Scikit-Learn (KNN Classifier), PyAutoGUI (Desktop Automation), NumPy.

**Objective:**
Generate a production-ready, modular backend that processes video frames, identifies hand gestures using a K-Nearest Neighbors (KNN) model, and executes OS-level commands. The system must support "One-Click Retraining" and "Unknown Gesture Detection."

**1. File Structure & Responsibilities:**
You must generate the following files with the specific logic defined below:

* **`requirements.txt`**: Include `fastapi`, `uvicorn`, `mediapipe`, `scikit-learn`, `numpy`, `pyautogui`, `websockets`, `opencv-python`.
* **`vision.py`**: Handles MediaPipe initialization and coordinate normalization.
* **`model.py`**: Handles the KNN classifier, training, and prediction logic.
* **`controller.py`**: Handles the mapping of gestures to OS actions and debouncing.
* **`main.py`**: The entry point running the FastAPI WebSocket server.

---

**2. Detailed Component Specifications:**

**A. `vision.py` (The Eyes)**

* Initialize `mediapipe.solutions.hands` with `max_num_hands=1`, `min_detection_confidence=0.7`.
* Create a function `process_frame(image_bytes)` that:
1. Decodes the image (if sent from client) OR captures from local webcam (use OpenCV `cv2.VideoCapture` logic here—assume backend handles camera).
2. Converts BGR to RGB.
3. Extracts the 21 hand landmarks.


* **CRITICAL: Normalization Logic**:
* Implement a helper function `normalize_landmarks(landmarks)`.
* Shift all points so the **Wrist (Index 0)** is at `(0,0,0)`.
* Scale all points so the distance between **Wrist** and **Middle Finger MCP (Index 9)** is exactly `1.0`.
* Return a flattened 1D array of 63 floats (`[x0, y0, z0, ... x20, y20, z20]`).



**B. `model.py` (The Brain)**

* Class `GestureClassifier`:
* **State:** Maintain lists `X_data` (features) and `y_data` (labels).
* **Model:** Use `sklearn.neighbors.KNeighborsClassifier(n_neighbors=5)`.
* **Method `add_sample(label, landmarks)**`: Append the normalized 63-float array to `X_data` and the label to `y_data`.
* **Method `train()**`: Call `self.model.fit(X_data, y_data)`. If data is empty, raise a warning.
* **Method `predict(landmarks)**`:
* Use `self.model.kneighbors()` to get the distance to the nearest neighbor.
* **Thresholding:** If the distance is > `0.6` (tunable constant), return `{"label": "Unknown", "confidence": distance}`.
* Otherwise, return the predicted label and confidence.


* **Persistence:** Add `save_model()` and `load_model()` using `pickle` to store the trained model to disk (`gesture_model.pkl`).



**C. `controller.py` (The Hands)**

* Class `DesktopController`:
* **Config:** A dictionary mapping labels to actions: `{"Fist": "volume_mute", "Open_Palm": "playpause", "Thumbs_Up": "volume_up"}`.
* **Debouncing:** Implement a `last_action_time` dictionary.
* Only execute the PyAutoGUI command if `(current_time - last_action_time[gesture]) > 1.0` second.


* **Execution:** Use `pyautogui.press(key)` for standard keys.



**D. `main.py` (The Interface)**

* Setup a FastAPI app with CORS allowed for all origins.
* **WebSocket Endpoint `/ws**`:
* **Protocol:**
1. Accept connection.
2. Enter an infinite loop (while True).
3. **Capture Phase:** Read frame from OpenCV `VideoCapture`.
4. **Process Phase:** Get normalized landmarks from `vision.py`.
5. **Logic Phase:**
* Check if `training_mode` is active.
* **If Training:** Save landmarks to `model.py` with the current target label.
* **If Predicting:** Get gesture from `model.py`. Pass gesture to `controller.py` to trigger OS action.


6. **Response Phase:** Send a JSON payload to the client:
```json
{
  "image": "base64_encoded_frame_with_landmarks_drawn",
  "gesture": "Fist",
  "confidence": 0.85,
  "status": "active" // or "training"
}

```




* **Input Handling:** Listen for JSON messages from the client (non-blocking if possible, or check for messages between frames):
* `{"command": "start_training", "label": "Peace"}` -> Set `training_mode = True`.
* `{"command": "stop_training"}` -> Set `training_mode = False`, call `model.train()`.
* `{"command": "save_model"}` -> Call `model.save_model()`.





**3. Constraints & Edge Cases:**

* **Performance:** The loop must run at ~30 FPS. Ensure `pyautogui` does not block the main thread.
* **Error Handling:** If MediaPipe detects no hands, send `{"gesture": "None"}` and skip prediction.
* **Camera:** Handle `cv2.VideoCapture` failing to open gracefully.

**Output:**
Generate the complete code for all 5 files. Do not use placeholders. Write functional, production-ready code.

**4. Additional Module: `mouse_engine.py` (The Cursor)**

* **Objective:** Implement a deterministic, geometry-based mouse controller that runs in parallel with the AI model. This feature is **active by default** and requires **no training**.
* **Logic:**
1. **Cursor Tracking:** Map the **Index Finger Tip (Landmark 8)** to the screen cursor.
2. **Left Click:** Triggered when **Index Finger Tip (8)** and **Thumb Tip (4)** are close (Distance < 0.05).
3. **Right Click:** Triggered when **Middle Finger Tip (12)** and **Thumb Tip (4)** are close.



**Detailed Requirements for `mouse_engine.py`:**

* **Class `MouseController`:**
* **Attributes:**
* `screen_width`, `screen_height`: Get using `pyautogui.size()`.
* `frame_reduction`: A margin (e.g., 100px) to create an "Active Zone" in the center of the camera frame, allowing the user to reach screen corners comfortably.
* `smoothening`: A value (e.g., 5 or 7) to reduce cursor jitter.
* `prev_x`, `prev_y`: To store previous cursor location for interpolation.


* **Method `process_hand(landmarks)`:**
1. **Coordinates:** Extract x, y of Landmark 8 (Index Tip).
2. **Conversion:** Convert normalized coordinates (0.0 - 1.0) to screen coordinates (1920x1080) using `np.interp`.
3. **Smoothing:** Implement the formula: `curr_x = prev_x + (target_x - prev_x) / smoothening`.
4. **Move:** Call `pyautogui.moveTo(curr_x, curr_y)`.
5. **Click Detection:**
* Calculate Euclidean distance between Landmark 8 & 4. If < Threshold  `pyautogui.click()`.
* Calculate Euclidean distance between Landmark 12 & 4. If < Threshold  `pyautogui.rightClick()`.
* **Debounce:** Ensure a click doesn't register 30 times a second (wait 0.5s between clicks).







**Integration Instructions for `main.py`:**

* Import `MouseController` from `mouse_engine.py`.
* Inside the main loop, **after** getting landmarks but **before** KNN prediction:
* Call `mouse_controller.process_hand(landmarks)`.


* **Conflict Logic:** Ensure the mouse control is active **unless** the user explicitly disables it via a specific "Stop Mouse" gesture (optional) or a flag from the frontend.

---
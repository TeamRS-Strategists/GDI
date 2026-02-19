
**Role:** Act as a Senior Flutter UI/UX Engineer.

**Task:** Overhaul the "Step 2: Capture" screen of the Add Gesture Wizard in `GestureFlow`.
**Objective:** Replace the simple recording flow with a **professional, guided data collection process** that ensures high-quality gesture data.

**New Functional Requirements:**

1. **Phase 1: Instruction Overlay (The "Pre-Flight" Check)**
* **Initial State:** When the user enters Step 2, do *not* start recording immediately.
* **Visuals:** Display the live camera feed with a **semi-transparent dark overlay**.
* **Content:** In the center, show an animated icon (Lottie placeholder) of a hand rotating slowly.
* **Text:** "Position your hand in the center. Rotate slightly to capture all angles."
* **Action:** A prominent "I'm Ready" button.


2. **Phase 2: High-Fidelity Recording**
* **Trigger:** When "I'm Ready" is clicked, remove the overlay and start a 3-2-1 countdown.
* **Duration:** The recording phase must last exactly **4 Seconds**.
* **Data Goal:** We need to capture **200 frames** (approx 50 FPS or high-speed capture).
* **Visual Feedback:**
* **Progress Ring:** A thick, neon-blue `CircularProgressIndicator` that fills smoothly over exactly 4 seconds.
* **Frame Counter:** A small badge updating in real-time: *"Captured: 45/200"*.
* **Status Text:** Change text from "Calibrating..." to "Move Hand Slowly..." to "Finishing..." based on the progress percentage.





**Technical Implementation Details:**

**A. `CaptureStep` Widget Logic:**
Refactor your state management (`ConsumerStatefulWidget`) to handle these enums:

```dart
enum CaptureState { instruction, countdown, recording, processing, complete }

```

**B. The Animation Controller:**

* Initialize an `AnimationController` with `duration: const Duration(seconds: 4)`.
* Sync the progress ring value to `controller.value`.

**C. Backend Communication (Protocol Update):**
Update the `startRecording` method in `WebSocketService` to send the configuration parameters:

```dart
// Send this when the countdown finishes
channel.sink.add(jsonEncode({
  "command": "start_training",
  "label": widget.gestureName,
  "duration_seconds": 4,
  "target_frames": 200
}));

```

**D. UI Layout (Stack):**

* **Layer 1 (Bottom):** The `Image.memory` (Webcam Feed) - ensure it is high resolution and fills the container.
* **Layer 2 (Overlay):** A `Container` with `color: Colors.black54` that only appears during `CaptureState.instruction`.
* **Layer 3 (HUD):** The `CustomPaint` widget for the active scanning box and the progress ring.

**Deliverables:**
Provide the complete Flutter code for `capture_step.dart`. Ensure the transition between "Instruction" and "Recording" is animated and smooth.

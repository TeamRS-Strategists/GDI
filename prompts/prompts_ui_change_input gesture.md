**Role:** Act as a Senior Flutter UI/UX Engineer.

**Context:** We are updating the "Step 2: Capture" screen of the `GestureFlow` Add Gesture Wizard. We need to move away from a continuous 4-second recording. Instead, the user wants a **3-Phase Snapshot System**. There must be a physical "gap" (prep time) between each phase for the user to reposition their hand, followed by a burst capture (taking screenshots/frames).

**Objective:**
Implement a state-machine driven capture UI with preparation gaps, screen-flash animations, and a visual "Snapshot Gallery" at the bottom of the feed instead of simple text instructions.

**1. UI Layout Updates (`capture_step.dart`)**

* **Camera Feed:** Keep the live video feed centered with the neon target box.
* **The Shutter Flash:** Add an `AnimatedOpacity` white overlay on top of the video feed that flashes `opacity: 0.8` to `0.0` quickly (like a camera shutter) when a capture burst happens.
* **Snapshot Gallery (Replacing Text Below):** At the bottom of the camera feed, create a `Row` of 3 glassmorphism thumbnail boxes (`Container` with `BackdropFilter` and border).
* Empty state: An outlined box with a subtle number (1, 2, 3).
* Filled state: Once a phase is captured, fill the box with the captured screenshot (Base64 image) and a neon green checkmark.



**2. The UX Timeline & State Machine**
Implement a timer-based state machine that loops through Prep and Capture for 3 phases:

* **Phase 1 (Center):**
* *Gap (2 seconds):* Display a large countdown overlay "3.. 2.. 1.." with text "Hold steady in center".
* *Capture (Burst):* Trigger Shutter Flash. Send command to backend to capture 50 frames. Populate Thumbnail 1.


* **Phase 2 (Closer):**
* *Gap (2 seconds):* Display countdown "3.. 2.. 1.." with text "Move hand slightly closer".
* *Capture (Burst):* Trigger Shutter Flash. Backend captures 50 frames. Populate Thumbnail 2.


* **Phase 3 (Tilted):**
* *Gap (2 seconds):* Display countdown "3.. 2.. 1.." with text "Tilt hand slightly".
* *Capture (Burst):* Trigger Shutter Flash. Backend captures 50 frames. Populate Thumbnail 3.
* *Finish:* Auto-transition to Step 3 of the Wizard.



**3. Backend Communication (Protocol Update)**
Update the `WebSocketService` to handle discrete burst commands rather than one continuous recording flag.

* Instead of `start_training`, expose a method: `captureBurst(String label, int phase)`.
* Send JSON: `{"command": "capture_burst", "label": gestureName, "phase": currentPhase, "frames": 50}`.
* Listen for a `{"status": "burst_complete", "snapshot": "base64_string"}` message from the backend to trigger the UI transition to the next Gap phase and populate the Thumbnail.

**Deliverables:**
Provide the complete Flutter code for the new `capture_step.dart`. Focus on the `Timer` or `AnimationController` logic that orchestrates the "Gap -> Flash -> Gap" sequence, and ensure the 3-thumbnail gallery perfectly matches the dark/glassmorphism theme. Do not use placeholders for the state machine logic.

---

### **Why this fixes the UX:**

1. **Eliminates Confusion:** The "gap" gives the user 2 full seconds to read the instruction and move their hand *before* data is recorded, ensuring zero motion blur.
2. **Psychological Feedback:** The "Shutter Flash" and the populating thumbnails give intense, satisfying feedback that data was actually captured, acting like a progress bar but much more engaging.
3. **High-Quality Variance:** By capturing 3 distinct bursts (Center, Closer, Tilted), your KNN model gets exactly the varied data it needs to prevent the "Low Confidence" errors you were experiencing.
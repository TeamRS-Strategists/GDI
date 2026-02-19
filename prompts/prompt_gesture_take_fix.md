
**Role:** Act as a Senior Full-Stack Engineer (Flutter & Python).

**Context:** I am building "GestureFlow," a desktop gesture control application. We need to overhaul the data collection process (Step 2 of adding a gesture) because users are currently holding their hands perfectly still, which causes our K-Nearest Neighbors (KNN) model to overfit and perform poorly in real-world scenarios.

**Objective:**
Implement a "Guided Variance" capture flow on the Flutter frontend and a "Real-Time Quality Control (QC)" gate on the Python backend. The goal is to force the user to provide varied training data while ensuring bad data (motion blur, lost tracking) is never saved. This addresses the core project requirement of maintaining "Clear feedback loops between user input and system response".

Please implement the following architecture:

#### **1. Frontend Implementation (Flutter: `capture_step.dart`)**

I need you to refactor the Capture screen to use a 4-phase guided animation.

* **The 4-Phase Timeline:** Instead of a single 4-second timer, divide the capture into four distinct 1-second phases.
* *Phase 1 (0-25%):* Text reads "Hold Steady in Center". Progress ring is Blue.
* *Phase 2 (25-50%):* Text reads "Move Slightly Closer". Progress ring is Cyan.
* *Phase 3 (50-75%):* Text reads "Move Slightly Back". Progress ring is Purple.
* *Phase 4 (75-100%):* Text reads "Tilt Hand Left & Right". Progress ring is Green.


* **Visual Feedback:**
* Add a "Frames Captured: X/200" badge.
* Draw the 21-point hand skeleton over the live video feed (using the coordinates sent from the WebSocket) so the user can see exactly what the AI sees.


* **The "Smart Pause" UI Logic:**
* Listen to the WebSocket stream for the `status` key.
* If `status == "tracking"`, progress the animation and ring normally.
* If `status == "hand_lost"`, pause the animation timer immediately. Turn the progress ring Red and flash a warning: "Hand Lost! Reposition in center."
* If `status == "moving_too_fast"`, pause the timer, turn the ring Yellow, and flash: "Moving too fast! Slow down."
* The timer should only resume when the status returns to "tracking".



#### **2. Backend Implementation (Python: `model.py` and `main.py`)**

I need you to add Real-Time Quality Control (QC) to the data collection loop during the training phase.

* **Visibility Check:**
* If MediaPipe returns no hands during the `is_training` loop, send `{"status": "hand_lost"}` to the WebSocket. Do *not* increment the frame counter and do *not* save the frame to the training array.


* **Velocity Check (Motion Blur Prevention):**
* Store the coordinates of the "Wrist" (Landmark 0) from the previous frame.
* Calculate the Euclidean distance between the current frame's wrist and the previous frame's wrist.
* If this distance exceeds a tunable threshold (meaning the hand jerked violently across the screen), send `{"status": "moving_too_fast"}` to the WebSocket. Do *not* save this frame.


* **Data Saving:**
* If the hand is visible and moving at an acceptable speed, send `{"status": "tracking"}`, append the normalized coordinates to the training array, and increment the counter.
* Once 200 valid frames are collected, automatically trigger the KNN `fit()` function and send `{"status": "training_complete"}`.



**Deliverables:**
Please write the Flutter widget logic (`capture_step.dart`) using an `AnimationController` to handle the pausing/resuming phases, and update the Python WebSocket loop to include the mathematical distance checks for the QC gate. Focus on making the state transitions robust.

*** ### Why this prompt is highly effective for an AI Assistant:

1. **It focuses on State Management:** It explicitly defines the states (`tracking`, `hand_lost`, `moving_too_fast`) which tells the AI exactly how the Flutter UI and Python backend should communicate.
2. **It separates concerns:** It clearly divides what the Python server is responsible for (the math and data validation) and what Flutter is responsible for (the animation pausing and color changing).
3. **It enforces data integrity:** By explicitly stating "Do *not* save the frame," it ensures the AI writes backend logic that rejects garbage data, fixing your "Low Confidence" bug at the source.
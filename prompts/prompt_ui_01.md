### Copy and Paste this Prompt

**Role:** Act as a Senior Flutter UI/UX Engineer.
**Project:** "GestureFlow" - A Desktop Client for Gesture-Based Computer Control.
**Tech Stack:** Flutter (Desktop Target: Windows/macOS), Provider (State Management), Lottie (Animations).

**Objective:**
Create a high-fidelity, futuristic, and accessible dashboard for a gesture recognition system. The UI must act as the primary control panel for configuration, monitoring, and training. The aesthetic should be "Cyberpunk Clean" or "Glassmorphism" to differentiate it from a basic prototype.

**Core UI Layout & Visual Hierarchy:**

1. **Sidebar (Left):**
* Navigation tabs: "Dashboard" (Active), "Gesture Library", "Settings".
* 
**System Status Indicator:** A persistent footer in the sidebar showing "Backend: Connected" (Green Dot) or "Disconnected" (Red Dot) to ensure clear communication of system state.




2. **Main Content Area (Dashboard View):**
* **Live Camera Feed Widget:** A large, central container displaying the video stream. Overlay a semi-transparent "Confidence Meter" bar at the bottom that fluctuates based on recognition certainty.


* **Master Toggle:** A prominent "System Active/Inactive" switch. When "Inactive," the camera feed should desaturate to visually indicate the system is paused.


* 
**Action Log:** A scrolling list below the feed showing real-time logs (e.g., *"Detected: 'Peace Sign' -> Action: 'Mute Volume'"*).




3. **Gesture Library & Management (Right Panel or Separate Tab):**
* 
**Grid Layout:** Display existing gestures as cards. Each card must show:


* A thumbnail or icon of the hand pose.
* The name (e.g., "Fist").
* The mapped action (e.g., "Scroll Down").


* 
**Edit/Delete Actions:** A trash icon to remove gestures.




* 
**"Add New Gesture" Button:** A floating action button or prominent card that triggers the "Guided Creation Flow".





**Critical UX Features & Workflows:**

A. The "Guided" Add Gesture Flow:
Create a `Dialog` or `ModalBottomSheet` with a 3-step stepper:

1. 
**Setup:** Text fields for "Gesture Name" and a Dropdown for "Map to Action" (e.g., Volume Up, Next Tab).


2. **Capture:** A "Start Recording" button. When pressed, show a 3-second countdown, then a circular progress bar filling up as frames are captured. If the hand is lost, pause the bar and show a "Hand Lost" warning (Error Prevention).


3. **Review:** Show a summary and a "Save to Library" button.

B. The "One-Click Retraining" Animation:

* **Trigger:** When the user modifies the library (Add/Delete), a "Train Model" banner appears at the top.
* **The Animation:** When clicked, overlay a full-screen semi-transparent loader. Use a **Lottie animation** (e.g., a neural network forming connections or a scanning radar).
* 
**Feedback:** Display text status updates below the animation: *"Preprocessing Data..." -> "Fitting Model..." -> "Ready"*.


* **Completion:** The animation should dissolve into a green "Success" checkmark before returning control to the user.

C. Accessibility & Polish:

* Use Tooltips on all icon buttons.
* Ensure high contrast for text (White text on Dark Grey background).
* Use `AnimatedContainer` and `Hero` widgets for smooth transitions between the Dashboard and the Gesture Library.



**Deliverable:**
Provide the Flutter code structure, separating `screens`, `widgets` (for the camera feed and gesture cards), and `models`. Focus heavily on the `TrainingOverlay` widget and the `GestureCard` design.

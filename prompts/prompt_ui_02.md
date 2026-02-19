Here is the specific **"Logic Implementation Prompt"** to fix the broken "Add Gesture" feature. This prompt assumes the UI layout exists (from your previous work) but focuses entirely on **wiring the buttons to the backend** to make it actually work.

---

### **Copy and Paste this Prompt**

**Role:** Act as a Senior Flutter Developer.

**Task:** Implement the logic for the "Add Gesture Wizard" in `GestureFlow`.
**Current Status:** The UI for the 3-step Wizard (Setup -> Capture -> Confirm) is built. The Python backend is running and listening for WebSocket commands.
**Problem:** The "Start Capture" and "Save" buttons are currently static. They do not trigger the backend.

**Objective:**
Wire the frontend Wizard to the backend so that when a user adds a gesture, the system actually records data, retrains the model, and updates the library.

**1. Update `WebSocketService.dart**`
Add the following specific methods to your existing service:

* `startRecording(String gestureLabel)`: Sends `{"command": "start_training", "label": gestureLabel}`.
* `stopRecording()`: Sends `{"command": "stop_training"}`. (This tells Python to fit the KNN model).
* **Stream Listener:** Ensure the incoming stream handles a `status` field.
* If `data['status'] == 'training_complete'`, notify the UI to move to Step 3.



**2. Implement `AddGestureWizard` Logic (Controller/Provider)**
Refactor the Wizard widget to handle the following **Asynchronous State Machine**:

* **Step 1 (Setup):**
* Validate that "Gesture Name" is not empty.
* On "Next", navigate to Step 2.


* **Step 2 (Capture) - The Critical Part:**
* **Action:** When user clicks "Start Capture":
1. Show a **3-second Countdown** (3...2...1).
2. **Trigger:** Call `webSocketService.startRecording(name)`.
3. **Visuals:** Change the `CircularProgressIndicator` to indeterminate (spinning) OR fill it over 2 seconds (simulating the 50-frame capture time).
4. **Wait:** Listen for the backend to send `{ "status": "training_complete" }` OR wait for a fixed 2.5 seconds (fallback).
5. **Finish:** Automatically move to Step 3.




* **Step 3 (Confirm):**
* Show a "Success" Lottie animation.
* **Action:** When user clicks "Save & Close":
1. Add the new gesture to the local Flutter `GestureLibrary` list (for immediate UI update).
2. Close the dialog.
3. Show a `SnackBar`: "Model Retrained Successfully."





**3. Data Protocol (Strict Adherence):**
Ensure the JSON sent matches the backend expectation exactly:

```dart
// Start Capture
channel.sink.add(jsonEncode({
  "command": "start_training",
  "label": _gestureNameController.text
}));

// Stop/Retrain (If manual stop is needed, otherwise backend auto-stops after 50 frames)
channel.sink.add(jsonEncode({
  "command": "stop_training"
}));

```

**4. Error Handling:**

* If the WebSocket is disconnected, disable the "Start Capture" button and show a "Backend Offline" warning in red text.

**Deliverables:**
Provide the updated code for `add_gesture_dialog.dart` (or your wizard file) and the updated `WebSocketService` methods. Focus on the `Future` and `Stream` logic.

---

### **How this fixes your issue:**

1. **Protocol Matching:** It explicitly tells the frontend *what* to send (`"start_training"`), which matches the Python backend logic we designed earlier (`main.py` listens for exactly this command).
2. **State Management:** It handles the "Countdown -> Record -> Wait" flow. Without this, the user clicks the button and nothing happens visually.
3. **Feedback Loop:** It ensures the user knows when the training is done (Step 2  Step 3 transition), solving the "is it working?" ambiguity.
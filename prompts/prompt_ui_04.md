
**Role:** Act as a Senior Flutter Frontend Architect and UI/UX Designer.

**Project:** "GestureFlow" - A Cyberpunk/Glassmorphism Desktop Client (Windows/macOS).
**Context:** I have a Python FastAPI backend running locally (`ws://localhost:8000/ws`) that streams Base64 video frames and gesture data. I need you to build the frontend to match specific high-fidelity designs.

**Input Resources:**

* I have attached HTML/CSS design files and screenshots for the Dashboard, Gesture Library, and "Add Gesture" Wizard.
* **Design Theme:** "Cyberpunk Glass." Dark mode, neon blue accents (`#1313ec`), frosted glass panels, and "Space Grotesk" typography.

**Objective:**
Create a production-ready Flutter Desktop application that replicates the attached designs pixel-perfectly and connects to the backend via WebSockets.

---

### **1. Technical Stack & Dependencies**

* **Framework:** Flutter (Target: Windows & macOS).
* **State Management:** `flutter_riverpod` (preferred) or `provider`.
* **Networking:** `web_socket_channel` (for real-time streaming).
* **UI Extras:**
* `window_manager` (To hide the default OS title bar and create a custom frameless window).
* `google_fonts` (Use "Space Grotesk").
* `flutter_animate` (For the scanning lines and fade-ins).
* `glassmorphism` or manual `BackdropFilter` widgets.



---

### **2. Design System (Translate from Attached HTML)**

You must implement a shared `AppTheme` class based on the provided Tailwind CSS config:

* **Colors:**
* `primary`: `Color(0xFF1313EC)` (Neon Blue)
* `bgDark`: `Color(0xFF050510)` (Deep Space Black)
* `glassSurface`: `Color(0xFF191933).withOpacity(0.7)`
* `neonGreen`: `Color(0xFF22C55E)` (Active Status)
* `neonRed`: `Color(0xFFEF4444)` (Recording/Error)


* **Typography:** `GoogleFonts.spaceGrotesk()` for all text.
* **Widgets:** Create a reusable `GlassPanel` widget that applies:
* `BackdropFilter(filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16))`
* `Container` with `LinearGradient` border (White 10% to Transparent).
* `BoxShadow` with neon glow for active elements.



---

### **3. Screen Implementation Details**

**A. Main Layout (Sidebar + Shell)**

* **Window:** Use `window_manager` to make the app frameless. Create a custom "Drag Area" top bar.
* **Sidebar:** Fixed width (280px). Glass background.
* **Nav Items:** Dashboard, Library, Settings.
* **Footer:** "Backend Status" indicator (Green dot = WebSocket Connected).



**B. Dashboard Screen (Refer to `dashboard/code.html`)**

* **Central Feed:** A large `AspectRatio` (16:9) container.
* **Content:** Display the Base64 image stream from the backend.
* **Overlays:**
* "REC • LIVE" badge (top left).
* "Bounding Box": Draw a neon blue rectangle over the hand (coordinates provided by backend).
* "Gesture Label": Large text at the bottom left (e.g., "Open Palm - 98%").




* **Metrics Row:** Three glass cards below the feed showing "Avg Confidence," "Latency," and "Gestures/Min."
* **Event Log (Right Panel):** A vertical list showing recent actions. Highlight the top item with a blue neon glow.

**C. Gesture Library (Refer to `gesture_library/code.html`)**

* **Layout:** A responsive `GridView` of cards.
* **Card Design:**
* Top: Gradient background with a large Icon (use `TablerIcons` or `MaterialSymbols`).
* Bottom: Gesture Name (White) and Mapped Action (Blue).
* **Hover Effect:** Scale up slightly and increase border glow.


* **"Create New" Card:** A dashed-border card that triggers the Wizard.

**D. The "Add Gesture" Wizard (Refer to `capture_flow/code.html`)**

* **UX Pattern:** Use a `Dialog` or transparent route overlay.
* **Step 1: Setup:** Form fields for "Gesture Name" and "Action Dropdown" (Volume Up, Mute, etc.).
* **Step 2: Capture:**
* Show the live camera feed again.
* **Animation:** Overlay a `CircularProgressIndicator` (Large, centered) that fills up as the backend captures frames.
* **Countdown:** A 3-2-1 timer before recording starts.


* **Step 3: Confirm:** Show a success message and "Save to Library" button.

---

### **4. Backend Integration Logic (`WebSocketService`)**

Create a singleton class `WebSocketService`:

1. **Connect:** `IOWebSocketChannel.connect('ws://localhost:8000/ws')`.
2. **Stream:** Expose a `Stream<AppState>` that creates a model from the incoming JSON.
* *Incoming JSON structure:* `{"image": "base64...", "gesture": "Fist", "status": "active"}`.


3. **Commands:**
* `startTraining(String label)`: Sends `{"command": "train", "label": "Fist"}`.
* `saveModel()`: Sends `{"command": "save_model"}`.



---

### **5. Special Requirement: Mouse Control Toggle**

* In the Dashboard "Quick Config" panel (bottom right of your screen design), add a `Switch` titled **"Touch Emulation / Mouse Control"**.
* **Logic:** When toggled, send `{"command": "toggle_mouse", "value": true/false}` to the backend.

**Deliverables:**
Provide the complete Flutter code structure. Focus heavily on the `GlassPanel` styling and the `WebSocketService` integration.

---
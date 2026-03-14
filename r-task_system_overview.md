# R-Task: Comprehensive System Architecture & Deep Dive

This document provides a highly detailed, granular breakdown of the **R-Task** system. It is designed to be the ultimate reference guide for your presentation, explaining exactly how the app, the backend, the AI, and the web components all communicate and function together.

---

## 1. The Technology Engine (The Stack)

R-Task is built on a modern, decoupled architecture. This means the mobile app, the website, and the backend server operate independently but communicate securely with each other.

### 1.1. The Mobile Application (User Facing)
*   **Framework**: **Flutter (Dart)**. We chose Flutter because it compiles to highly optimized, native machine code for both iOS and Android from a single codebase.
*   **State Management**: **Riverpod**. This ensures the app is highly reactive. When a user's name changes or a new message arrives, Riverpod instantly updates only the specific widget on the screen, saving battery and CPU.
*   **Routing**: **GoRouter**. Handles all screen navigation and allows for deep-linking (e.g., clicking a push notification directly opens a specific task).
*   **Local Storage**: **Shared Preferences & SQLite** for caching user settings (dark mode, notification preferences) locally on the device.

### 1.2. The Web Infrastructure (Landing Page & Admin Panel)
*   **Framework**: **React.js** (built with Vite for extreme speed). 
*   **Styling**: Modern, responsive **Tailwind CSS / Custom CSS** to provide a premium "dark mode" aesthetic with glassmorphism effects.
*   **Domains & Hosting**: 
    *   `r-task.online`: The public-facing landing page where users discover the app and download the `.apk`.
    *   `admin.r-task.online`: The secure, private dashboard exclusively for system administrators.
    *   Both are hosted on a highly scalable **Linux VPS** using **LiteSpeed Web Server** for lightning-fast edge delivery.

### 1.3. The AI Backend Server (The Brains)
*   **Environment**: **Node.js** running the **Express.js** framework.
*   **Location**: Hosted securely on a dedicated IP address at `server.r-task.online`.
*   **Core Responsibilities**: 
    1. Processing heavy document logic (extracting text from PDFs and Word docs).
    2. Communicating securely with the **Google Gemini AI Engine**.
    3. Serving protected API endpoints for the React Admin Panel.

### 1.4. The Database & Cloud Layer (Data Storage)
*   **Authentication**: **Firebase Auth**. Handles secure user login, password hashing, and token generation.
*   **Database**: **Cloud Firestore (NoSQL)**. A real-time database. The moment a leader assigns a task, Firestore instantly pushes that data to the assignee's phone in milliseconds—no manual refreshing required.
*   **File Storage**: **Firebase Cloud Storage**. Securely stores user profile pictures, chat attachments, and submitted project files.
*   **Push Notifications**: **Firebase Cloud Messaging (FCM)**. Wakes up the user's phone to alert them of new tasks or chat messages.

---

## 2. Core Feature Workflows (How It Actually Works)

Here is exactly how the most complex features in the system compute their logic from start to finish.

### 2.1. The AI-Powered Task Breakdown Pipeline
This is R-Task's flagship feature. It automates hours of manual management work in seconds.

1.  **File Upload**: A Team Leader creates a project in the app and uploads a complex project brief (like a 10-page PDF).
2.  **API Handshake**: The Flutter app sends this PDF securely to the Node.js backend at `server.r-task.online/api/ai/analyze-document`.
3.  **Text Extraction**: The Node.js server uses specialized libraries (`pdf-parse` for PDFs, `mammoth` for Word docs) to rip all the raw text out of the document.
4.  **AI Processing**: The backend takes this massive wall of text and feeds it into the **Google Gemini 2.5 AI API** with a highly specific, engineered prompt. The prompt instructs the AI to:
    *   Understand the ultimate goal of the document.
    *   Break the goal down into logical **Sub-Tasks**.
    *   Determine the **Priority** (High, Medium, Low) of each sub-task.
    *   Estimate the **Hours** required to complete each.
    *   Identify **Dependencies** (e.g., Task B cannot start until Task A is done).
5.  **JSON Response**: The AI returns a perfectly structured JSON object. The Node.js server relays this JSON back to the Flutter app.
6.  **User Review**: The Leader sees the AI's breakdown beautifully rendered on their screen. They can use the **AI Chat Widget** to tell the AI, *"Make the design task higher priority,"* and the AI will adjust the breakdown dynamically.
7.  **Execution (Database Write)**: When the Leader hits "Deploy," the Flutter app parses the JSON and writes a massive batch of new `Task` documents directly into Cloud Firestore.

### 2.2. Smart Distribution & Team Collaboration
*   **Assignment**: Once tasks are generated, the Leader assigns them to team members. The app writes the assignee's `uid` to the task document.
*   **Real-Time Sync**: The assignee's app is constantly listening to Firestore. The moment their `uid` is attached to a task, the task pops up on their dashboard.
*   **Group Chat**: Every project automatically gets a dedicated chat room. When a user sends a message, it is written to a `messages` subcollection in Firestore. Every other user in the project has an active listener on that collection, so the message appears instantly on their screen. If they attach a file, it uploads to Firebase Storage first, and the secure download URL is sent in the text message.

### 2.3. The Task Submission & Approval Loop
To ensure quality control, tasks don't just "finish" when a user clicks complete.
1.  **Submission**: The member clicks "Submit Work." They attach notes and a final file (e.g., a finished report). This creates a `Submission` document in Firestore linked to the specific task.
2.  **Notification**: FCM fires a push notification to the Team Leader: *"John has submitted work for Task A."*
3.  **Review**: The Leader opens the app, reviews the attached files, and taps **Approve** or **Reject**.
    *   **If Approved**: The task's status changes to `Completed`, and progress bars across the project update automatically.
    *   **If Rejected**: The Leader is forced to type a "Revision Note." The task status changes to `Needs Revision`, and it is kicked back to the member with the feedback attached.

### 2.4. Admin Panel & Backend Analytics
The system administrators need a bird's-eye view of the entire platform.
1.  **Secure Login**: An admin opens `admin.r-task.online` and logs in.
2.  **API Request**: The React dashboard makes an encrypted `GET` request to the Node.js server.
3.  **Server-Side Aggregation**: The Node.js server uses the **Firebase Admin SDK** (which has privileged, unrestricted access to the database) to securely count total users, scan all active projects, and tally up daily system usage.
4.  **Data Visualization**: The server returns this aggregated data to the React frontend, which beautifully renders it into charts, graphs, and manageable data tables.

---

## 3. System Security & Platform Distribution

*   **Firebase Security Rules**: The database is locked down. A student can only see tasks assigned to them or their group. They cannot read data from other groups or manipulate the system.
*   **CORS & Token Auth**: The Node.js server strictly verifies API tokens. It will reject any request that doesn't securely prove the user is logged into the official R-Task app. 
*   **Continuous Deployment Loop**: 
    1. The React Web Apps are compiled into hyper-optimized static HTML/JS files and hosted on the VPS.
    2. The Flutter code is compiled into an Android `.apk`.
    3. The `.apk` is uploaded directly to `r-task.online/apk/rtask.apk`. Because it lives on our own secure server, we bypass app-store delays, allowing users to download the exact, latest version of the platform instantly from the landing page.

---

## Presentation Summary (Elevator Pitch)
*"R-Task is not just a to-do list; it is a full-stack, AI-driven project management ecosystem. By combining the cross-platform power of Flutter for mobile, React for web dashboards, and a custom Node.js backend linked securely to Google's Gemini AI and Firebase's real-time database, R-Task autonomously breaks down complex projects, manages team communication with real-time sockets, and enforce a strict, transparent approval pipeline."*

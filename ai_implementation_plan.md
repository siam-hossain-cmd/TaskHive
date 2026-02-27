# TaskHive — AI Smart Assignment Analyzer: Full Implementation Plan

---

## 1. Overview

An AI-powered **end-to-end assignment workflow** integrated into TaskHive. Covers the entire lifecycle: **upload → AI analysis → task distribution → member submission → review & comments → approval → final compilation**. Works for both individual and group assignments.

---

## 2. Complete User Flow (What Happens Step by Step)

### Phase 1: Task Creation & AI Analysis

```
User taps "Create Task"
    │
    ├── Individual?  → Upload PDF/doc → AI analyzes → Creates single task with breakdown
    │
    └── Group?       → Upload PDF/doc → AI analyzes → Breaks into sub-tasks
                          │
                          ├── Leader comments / asks AI to modify breakdown
                          ├── AI re-organizes based on feedback
                          └── Leader confirms final sub-task list
```

### Phase 2: Team Assignment (Group Mode)

```
Sub-tasks are ready
    │
    ├── AI suggests distribution across team members
    ├── Leader sees assignment board:
    │       Member 1 → "Design UI mockups"
    │       Member 2 → "Build REST API"
    │       Member 3 → "Write database schema"
    │       ...
    ├── Leader can drag/reassign any task to any member
    └── Leader confirms → Tasks assigned → All members notified
```

### Phase 3: Member Submission & Collaboration

```
Each member sees their assigned task in their task list
    │
    ├── Member works on their part
    ├── Member uploads their completed doc/file as submission
    ├── ──► ALL other team members get notified: "Member X uploaded their part"
    │
    ├── Any member can view other members' submissions
    ├── Any member can comment on any submission
    │       └── e.g., "This section needs more detail"
    ├── Leader can request changes on a submission
    │       └── Adds comment → Member gets notified → Member re-submits
    └── Leader approves each member's submission
            └── ──► Auto-marks that sub-task as "Done ✓"
```

### Phase 4: Final Compilation & Completion

```
All member sub-tasks are approved
    │
    ├── Leader can compile the full assignment themselves
    │       └── Downloads all submissions → Merges → Uploads final
    │
    ├── OR Leader assigns a team member as "Compiler"
    │       └── That member downloads all parts → Makes full report → Uploads
    │
    ├── Final document uploaded to the assignment
    ├── Leader marks the FULL ASSIGNMENT as "Completed"
    └── All members notified: "Assignment completed! 🎉"
```

---

## 3. Core Features Breakdown

### 3.1 PDF/Document Upload & AI Analysis
- User uploads PDF, DOC, or DOCX during task creation
- AI reads and extracts:
  - **Assignment title & subject**
  - **Overall description/objective**
  - **Individual tasks/requirements** hidden in the document
  - **Estimated difficulty/priority** per task
  - **Deadline clues** if mentioned in the document
- Works for both **Individual** (single task breakdown) and **Group** (multi-member distribution)

### 3.2 AI Chat — Comment & Modify
- After AI generates the task breakdown, leader sees an **AI chat panel**
- Leader can type comments like:
  - *"Split the API task into frontend and backend"*
  - *"Add a testing task"*
  - *"Make the UI task high priority"*
  - *"Remove the report task"*
- AI processes the comment and **re-generates** the updated task list
- Leader keeps refining until satisfied

### 3.3 Smart Team Distribution
- AI suggests which member gets which sub-task (equal distribution)
- Leader sees **assignment board**: each sub-task mapped to a member
- Leader can **reassign** any task to any member
- On confirm → each sub-task becomes a `GroupTaskModel` assigned to that member
- All members get push notifications

### 3.4 Member Submission System
- Each member sees their assigned sub-task in their task list
- Member uploads their completed work as a doc/file (**submission**)
- Submission goes to `pendingApproval` status
- **All other team members** receive a notification when someone uploads
- Any member can **view** other members' submissions

### 3.5 Comment & Review System
- **Leader** can add comments on any member's submission
  - e.g., *"Change section 3"*, *"Add more references"*
  - Member gets notified → edits and re-submits
- **Other team members** can also comment on submissions
  - Peer review / suggestions
- Comment thread per submission (like a mini chat)

### 3.6 Approval Pipeline
- Leader reviews each submission
- **Approve** → Sub-task auto-marked as "Done ✓"
- **Reject with feedback** → Member gets notified with the feedback → re-submits
- Progress bar shows how many sub-tasks are approved out of total

### 3.7 Final Compilation
- Once all sub-tasks are approved:
  - Leader can **download all submissions** and compile themselves
  - OR Leader **assigns a "Compiler"** — a team member who merges all parts into one final document
- Compiler uploads the **full completed assignment**
- Leader marks the **entire assignment as "Completed"**
- All members notified of completion

---

## 4. Technical Architecture

### 4.1 Complete System Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        PHASE 1: TASK CREATION                          │
│                                                                         │
│  ┌─ Step 1: Mode ─────────────────────────────────────────────────┐    │
│  │  User chooses: [Individual] or [Group]                          │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                              │                                          │
│  ┌─ Step 2: Upload ───────────────────────────────────────────────┐    │
│  │  Upload PDF / DOC / DOCX (assignment sheet)                     │    │
│  │  + Optional: title, subject, due date, priority                 │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                              │                                          │
│  ┌─ Step 3: AI Analysis ──────────────────────────────────────────┐    │
│  │  → PDF sent to backend → text extracted → sent to Gemini AI    │    │
│  │  → AI returns sub-task breakdown                                │    │
│  │  → Leader sees editable sub-task cards                          │    │
│  │  → Leader can COMMENT / CHAT with AI:                           │    │
│  │      "Split task 2 into two parts"                              │    │
│  │      "Add a testing task"                                       │    │
│  │      "Make task 1 high priority"                                │    │
│  │  → AI re-generates updated breakdown                           │    │
│  │  → Leader confirms final sub-task list                          │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                              │                                          │
│               ┌──────────────┴──────────────┐                          │
│               │                              │                          │
│          [Individual]                   [Group]                         │
│               │                              │                          │
│    Creates personal task          ┌─ Step 4: Team + Assign ──────┐    │
│    with sub-task checklist        │  Select team / create new     │    │
│                                    │  AI suggests distribution:    │    │
│                                    │    Member 1 → Task A, B       │    │
│                                    │    Member 2 → Task C          │    │
│                                    │    Member 3 → Task D, E       │    │
│                                    │  Leader reassigns as needed   │    │
│                                    └──────────────────────────────┘    │
│                                              │                          │
│                                    ┌─ Step 5: Review ────────────┐    │
│                                    │  Final mapping displayed     │    │
│                                    │  "Assign All Tasks" button   │    │
│                                    │  → N GroupTaskModels created  │    │
│                                    │  → All members notified      │    │
│                                    └──────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                     PHASE 2: MEMBER WORK & SUBMISSION                   │
│                                                                         │
│  Each member sees their assigned sub-task(s) in their task list        │
│       │                                                                 │
│       ├── Member works on their part                                    │
│       ├── Member uploads completed doc/file → status: "Submitted"       │
│       ├── ──► ALL other members notified: "Alice uploaded Part 2"       │
│       └── Any member can VIEW other members' submissions                │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                   PHASE 3: REVIEW, COMMENT & APPROVAL                   │
│                                                                         │
│  Comment System (per submission):                                       │
│       ├── Leader comments: "Fix section 3, add references"              │
│       ├── Other members comment: "Nice work!" or "Check page 5"        │
│       ├── Member gets notified of each comment                          │
│       └── Comment thread = mini chat per sub-task                       │
│                                                                         │
│  Leader Actions:                                                        │
│       ├── "Request Changes" → member re-submits → re-review             │
│       └── "Approve" → auto-marks sub-task as DONE ✅                    │
│                                                                         │
│  Progress Bar: [████████░░░░] 3/5 sub-tasks approved                    │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                    PHASE 4: FINAL COMPILATION                           │
│                                                                         │
│  All sub-tasks approved ✅                                              │
│       │                                                                 │
│       ├── Option A: Leader compiles                                     │
│       │     └── Downloads all parts → merges → uploads final doc        │
│       │                                                                 │
│       ├── Option B: Leader assigns a "Compiler"                         │
│       │     └── Chosen member downloads all → makes full report         │
│       │     └── Uploads compiled assignment                             │
│       │                                                                 │
│       ├── Final document attached to the assignment                     │
│       ├── Leader marks FULL ASSIGNMENT as "Completed" ✅                │
│       └── ALL members notified: "Assignment completed!"                 │
└─────────────────────────────────────────────────────────────────────────┘
```

### 4.2 Backend API Design

#### API 1: `POST /api/ai/analyze` — Analyze PDF
```json
// Request
{
  "pdfUrl": "https://firebasestorage.googleapis.com/...",
  "teamMembers": [
    { "uid": "abc123", "name": "Alice" },
    { "uid": "def456", "name": "Bob" }
  ]
}

// Response
{
  "success": true,
  "analysis": {
    "title": "Software Engineering Assignment 3",
    "subject": "CSE 4201",
    "summary": "Build a full-stack e-commerce app with...",
    "subtasks": [
      {
        "title": "Design UI/UX mockups",
        "description": "Create wireframes and high-fidelity mockups",
        "priority": "medium",
        "estimatedHours": 3,
        "suggestedAssignee": "abc123"
      }
    ]
  },
  "conversationId": "conv_abc123"
}
```

#### API 2: `POST /api/ai/refine` — AI Chat (Modify Breakdown)
```json
// Request
{
  "conversationId": "conv_abc123",
  "message": "Split the API task into frontend and backend",
  "currentSubtasks": [ ... ]
}

// Response
{
  "success": true,
  "message": "Done! I've split 'Build REST API' into two separate tasks.",
  "updatedSubtasks": [ ... ]
}
```

#### API 3: `POST /api/tasks/submit` — Member Submits Work
```json
// Request
{
  "taskId": "task_xyz",
  "groupId": "group_abc",
  "fileUrl": "https://firebasestorage.googleapis.com/...",
  "fileName": "my_part.docx"
}

// Response — triggers notification to all group members
{
  "success": true,
  "status": "pendingApproval"
}
```

#### API 4: `POST /api/tasks/:id/comment` — Add Comment on Submission
```json
// Request
{
  "taskId": "task_xyz",
  "userId": "user_123",
  "text": "Please fix section 3 and add references",
  "type": "review"  // "review" | "suggestion" | "general"
}

// Response — triggers notification to task assignee
{
  "success": true,
  "commentId": "comment_abc"
}
```

#### API 5: `POST /api/tasks/:id/approve` — Leader Approves
```json
// Response — auto-updates status to "approved", notifies member
{ "success": true, "status": "approved" }
```

#### API 6: `POST /api/tasks/:id/request-changes` — Leader Requests Changes
```json
// Request
{
  "feedback": "Section 3 needs more detail. Add 2 more references."
}

// Response — notifies member with the feedback
{ "success": true, "status": "rejected" }
```

#### API 7: `POST /api/assignments/:id/compile` — Assign Compiler / Upload Final
```json
// Request
{
  "assignmentId": "assignment_abc",
  "compilerId": "user_456",           // null if leader does it
  "finalDocUrl": "https://..."        // null if assigning compiler
}
```

#### API 8: `POST /api/assignments/:id/complete` — Mark Full Assignment Done
```json
// Response — notifies ALL members
{ "success": true, "status": "completed" }
```

### 4.3 AI Prompt Strategy

```
System Prompt:
"You are TaskHive AI, a smart assignment analyzer. When given assignment 
document text, extract ALL actionable tasks and return structured JSON.

For each task provide:
- title: concise task name
- description: what needs to be done
- priority: high | medium | low
- estimatedHours: numeric estimate

If team members are provided, suggest fair distribution based on 
task count and estimated effort. Always return valid JSON.

When the user asks to modify the breakdown, update the subtask list 
accordingly and return the full updated JSON."

User Prompt (Initial Analysis):
"Analyze this assignment and break it into sub-tasks:

<extracted PDF text>

Team Members: Alice (abc123), Bob (def456), Charlie (ghi789)

Return JSON: { title, subject, summary, subtasks[] }"

User Prompt (Refinement):
"Current subtasks: <current JSON>

User says: 'Split task 2 into frontend and backend'

Return updated JSON with the modified subtasks array."
```

---

## 5. Data Models (New & Modified)

### 5.1 New: `AssignmentModel` (Parent container for group assignments)

```dart
enum AssignmentStatus { active, compilationPhase, completed }

class AssignmentModel {
  final String id;
  final String groupId;
  final String createdBy;          // leader who created it
  final String title;
  final String subject;
  final String summary;            // AI-generated summary
  final String originalPdfUrl;     // the uploaded assignment PDF
  final String? finalDocUrl;       // compiled final document
  final String? compilerId;        // member assigned to compile (null = leader)
  final AssignmentStatus status;
  final List<String> subtaskIds;   // list of GroupTaskModel IDs
  final DateTime dueDate;
  final DateTime createdAt;
}
```

### 5.2 New: `TaskCommentModel` (Comments on submissions)

```dart
class TaskCommentModel {
  final String id;
  final String taskId;
  final String groupId;
  final String userId;
  final String userName;
  final String text;
  final String type;               // "review" | "suggestion" | "general"
  final DateTime createdAt;
}
```

### 5.3 New: `AIAnalysisResult` (AI response model)

```dart
class AISubTask {
  final String title;
  final String description;
  final String priority;
  final double estimatedHours;
  final String? suggestedAssigneeId;
  String? assignedToId;            // mutable — leader changes this
  String? assignedToName;
}

class AIAnalysisResult {
  final String title;
  final String subject;
  final String summary;
  final List<AISubTask> subtasks;
  final String? conversationId;    // for AI chat refinement
}
```

### 5.4 Modified: `GroupTaskModel` (Add submission fields)

```dart
// NEW fields to add to existing GroupTaskModel:
final String? assignmentId;        // link to parent AssignmentModel
final String? submissionUrl;       // uploaded doc URL when member submits
final String? submissionFileName;  // original file name
final DateTime? submittedAt;       // when member submitted
final DateTime? approvedAt;        // when leader approved
```

### 5.5 Modified: `GroupTaskStatus` (Add new statuses)

```dart
enum GroupTaskStatus {
  pending,           // assigned but not started
  inProgress,        // member is working
  submitted,         // member uploaded their part
  pendingApproval,   // waiting for leader review
  changesRequested,  // leader asked for changes  ← NEW
  approved,          // leader approved
  rejected,          // leader rejected (legacy)
}
```

---

## 6. Firestore Collections (New)

```
Firestore Database
│
├── assignments/                        ← NEW collection
│   └── {assignmentId}
│       ├── title, subject, summary
│       ├── groupId, createdBy
│       ├── originalPdfUrl, finalDocUrl
│       ├── compilerId, status
│       ├── subtaskIds[]
│       ├── dueDate, createdAt
│       └── ...
│
├── task_comments/                      ← NEW collection
│   └── {commentId}
│       ├── taskId, groupId
│       ├── userId, userName
│       ├── text, type
│       └── createdAt
│
├── group_tasks/                        (EXISTING — add fields)
│   └── {taskId}
│       ├── ... existing fields ...
│       ├── assignmentId               ← NEW
│       ├── submissionUrl              ← NEW
│       ├── submissionFileName         ← NEW
│       ├── submittedAt                ← NEW
│       └── approvedAt                 ← NEW
│
└── ai_conversations/                   ← NEW collection (for AI chat context)
    └── {conversationId}
        ├── userId
        ├── messages[]
        └── createdAt
```

---

## 7. Codebase Changes Map

### 7.1 Backend (`backend/`)

| File | Action | Description |
|------|--------|-------------|
| `src/routes/ai.js` | **CREATE** | `/analyze` — PDF → text → Gemini → JSON. `/refine` — AI chat to modify breakdown |
| `src/routes/assignments.js` | **CREATE** | CRUD for assignments, compile, complete endpoints |
| `src/routes/tasks.js` | **MODIFY** | Add `/submit`, `/:id/comment`, `/:id/approve`, `/:id/request-changes` |
| `src/index.js` | **MODIFY** | Register `ai.js` and `assignments.js` routes |
| `package.json` | **MODIFY** | Add: `pdf-parse`, `@google/generative-ai` |

### 7.2 Flutter — Domain Models (`app/lib/features/`)

| File | Action | Description |
|------|--------|-------------|
| `tasks/domain/models/ai_analysis_model.dart` | **CREATE** | `AIAnalysisResult`, `AISubTask` |
| `tasks/domain/models/assignment_model.dart` | **CREATE** | `AssignmentModel` with Firestore serialization |
| `tasks/domain/models/task_comment_model.dart` | **CREATE** | `TaskCommentModel` |
| `groups/domain/models/group_model.dart` | **MODIFY** | Add submission fields to `GroupTaskModel`, add `changesRequested` status |

### 7.3 Flutter — Data Layer

| File | Action | Description |
|------|--------|-------------|
| `tasks/data/repositories/assignment_repository.dart` | **CREATE** | CRUD for assignments, download all submissions, mark complete |
| `groups/data/repositories/group_repository.dart` | **MODIFY** | Add: `submitTask()`, `getTaskComments()`, `addTaskComment()`, `requestChanges()` |

### 7.4 Flutter — Service Layer

| File | Action | Description |
|------|--------|-------------|
| `core/services/api_service.dart` | **MODIFY** | Add: `analyzeAssignment()`, `refineAnalysis()`, `submitWork()`, `addComment()`, `approve()`, `requestChanges()`, `assignCompiler()`, `completeAssignment()` |

### 7.5 Flutter — Presentation Layer (Screens)

| File | Action | Description |
|------|--------|-------------|
| `tasks/presentation/screens/create_task_screen.dart` | **MODIFY** | Add AI step, batch submit, assignment creation logic |
| `tasks/presentation/screens/create_task_ai_step.dart` | **CREATE** | AI analysis UI + AI chat panel for refinement |
| `tasks/presentation/screens/create_task_team_steps.dart` | **MODIFY** | Add assignment board (sub-tasks ↔ members mapping) |
| `groups/presentation/screens/assignment_detail_screen.dart` | **CREATE** | View assignment progress, all sub-tasks, approval status |
| `groups/presentation/screens/submission_detail_screen.dart` | **CREATE** | View a member's submission, comment thread, approve/reject |
| `groups/presentation/screens/compilation_screen.dart` | **CREATE** | Download all parts, assign compiler, upload final doc |

### 7.6 Flutter — Providers

| File | Action | Description |
|------|--------|-------------|
| `tasks/presentation/providers/assignment_providers.dart` | **CREATE** | Stream assignment, sub-tasks, comments |
| `groups/presentation/providers/group_providers.dart` | **MODIFY** | Add submission and comment providers |

---

## 8. Wizard Step Changes

### Current Flow (4 steps):
```
Step 0: Mode (Individual / Team)
Step 1: Task Details (title, desc, files)
Step 2: Team Setup (select members, leader)
Step 3: Review & Submit
```

### New Flow — Individual (4 steps):
```
Step 0: Mode → Individual
Step 1: Upload PDF/doc
Step 2: AI Analysis → sub-task checklist (editable + AI chat)
Step 3: Review & Create
```

### New Flow — Group (6 steps):
```
Step 0: Mode → Group
Step 1: Upload PDF/doc + basic details (title, due date)
Step 2: AI Analysis → sub-task breakdown + AI chat refinement        ← NEW
Step 3: Team Setup → select/create team, choose leader               (existing)
Step 4: Assignment Board → map sub-tasks to members, reassign        ← NEW
Step 5: Review → full mapping displayed → "Assign All Tasks"         ← MODIFIED
```

---

## 9. AI Provider

| Provider | Pros | Cost |
|----------|------|------|
| **Google Gemini API** | Firebase ecosystem, free tier (60 req/min), direct PDF support | Free tier / $0.075/1M tokens |
| **OpenAI GPT-4o** | Most accurate structured output | ~$2.50/1M tokens |
| **Claude API** | Large context, strong extraction | ~$3/1M tokens |

**Recommendation: Google Gemini** — native Firebase integration, generous free tier, `gemini-2.0-flash` supports PDF directly.

---

## 10. New Dependencies

### Backend (Node.js)
```json
{
  "pdf-parse": "^1.1.1",
  "@google/generative-ai": "^0.21.0"
}
```

### Flutter
No new packages needed — uses existing `http`, `file_picker`, Firebase Storage.

### Environment Variable
```
GEMINI_API_KEY=your_gemini_api_key_here
```

---

## 11. UX/UI Design

### 11.1 AI Analysis Screen (Step 2)
- **Pre-analysis state:** PDF file name displayed + "Analyze with AI ✨" button
- **Loading state:** Lottie sparkle animation + "Analyzing your assignment..."
- **Results state:**
  - Summary card (title, subject, overview)
  - Editable sub-task cards with priority badges & estimated hours
  - "Add Sub-Task" and "Remove" buttons
  - **AI Chat Panel** at bottom:
    - Text input: "Ask AI to modify..."
    - Leader types: "Split task 2" → AI updates the list live
  - "Continue" button when satisfied

### 11.2 Assignment Board (Step 4)
- **Left:** Sub-task cards with title + priority
- **Right:** Member avatars
- **Interaction:** Tap sub-task → tap member → assigned
- **Visual:** Member avatar badge on each sub-task card
- **AI suggestion label:** "AI Suggested" on pre-assigned tasks

### 11.3 Member Task View
- Member sees their sub-task(s) in regular task list
- Task card shows: title, description, priority, due date, parent assignment name
- **"Upload Submission"** button → file picker → upload doc
- Status badge: Pending → In Progress → Submitted → Approved ✓

### 11.4 Submission Detail Screen
- **Header:** Task title + assigned member name
- **File preview:** PDF/doc viewer or download button
- **Comment thread:** Scrollable chat-like thread
  - Leader comments highlighted differently
  - Any member can add comments
- **Leader actions:** "Approve ✅" or "Request Changes 🔄" buttons
- **Re-submission:** If changes requested, member sees feedback + "Re-upload" button

### 11.5 Assignment Progress Screen
- **Overall progress bar:** 3/5 tasks approved
- **Sub-task list:** Each with status icon (⏳ pending, 📤 submitted, ✅ approved, 🔄 changes requested)
- **When all approved:**
  - "Download All Submissions" button
  - "Assign Compiler" → pick a member
  - OR "Upload Final Document" → leader uploads
  - "Mark Assignment Complete ✅" button

---

## 12. Notification Matrix

| Event | Who Gets Notified | Message |
|-------|-------------------|---------|
| Tasks assigned | Each assigned member | "You've been assigned: {task title}" |
| Member submits work | All other group members | "{name} uploaded their part: {task title}" |
| Comment added | Task assignee (+ mentioned users) | "{name} commented on your task: {preview}" |
| Changes requested | Task assignee | "Leader requested changes: {feedback preview}" |
| Task approved | Task assignee | "Your task '{title}' has been approved! ✅" |
| Compiler assigned | Compiler member | "You've been assigned to compile the final report" |
| Assignment completed | All group members | "Assignment '{title}' is complete! 🎉" |

---

## 13. Error Handling

| Scenario | Handling |
|----------|----------|
| PDF has no readable text | "Could not read this PDF. Try a text-based PDF." |
| AI returns malformed JSON | Retry once, then fallback to manual task creation |
| Network timeout during analysis | "Retry" button with cached PDF URL |
| AI extracts 0 tasks | "No tasks found. Add them manually." + add button |
| Leader skips AI step | "Skip Analysis" button → manual task creation |
| Submission upload fails | Retry with resume support |
| Member re-submits | Previous submission archived, new one replaces it |

---

## 14. File Tree (All New & Modified Files)

```
backend/
  src/
    routes/
      ai.js                              ← NEW (analyze + refine endpoints)
      assignments.js                      ← NEW (assignment CRUD, compile, complete)
      tasks.js                            ← MODIFY (submit, comment, approve, request-changes)
    index.js                              ← MODIFY (register new routes)
  package.json                            ← MODIFY (add pdf-parse, generative-ai)
  .env                                    ← MODIFY (add GEMINI_API_KEY)

app/lib/
  core/
    services/
      api_service.dart                    ← MODIFY (add 8 new API methods)
  features/
    tasks/
      domain/
        models/
          ai_analysis_model.dart          ← NEW
          assignment_model.dart           ← NEW
          task_comment_model.dart         ← NEW
      data/
        repositories/
          assignment_repository.dart      ← NEW
      presentation/
        screens/
          create_task_screen.dart          ← MODIFY (new wizard steps, batch submit)
          create_task_ai_step.dart         ← NEW (AI analysis + chat UI)
          create_task_team_steps.dart      ← MODIFY (assignment board)
        providers/
          assignment_providers.dart        ← NEW
    groups/
      domain/
        models/
          group_model.dart                ← MODIFY (add submission fields, new status)
      data/
        repositories/
          group_repository.dart           ← MODIFY (submit, comments, approve)
      presentation/
        screens/
          assignment_detail_screen.dart   ← NEW (progress, sub-task list)
          submission_detail_screen.dart   ← NEW (file view, comments, approve)
          compilation_screen.dart         ← NEW (download all, assign compiler, upload final)
        providers/
          group_providers.dart            ← MODIFY (submission + comment providers)
```

---

## 15. Summary

| Metric | Count |
|--------|-------|
| **New Files** | 10 |
| **Modified Files** | 8 |
| **New Backend Routes** | 8 endpoints |
| **New Firestore Collections** | 3 (`assignments`, `task_comments`, `ai_conversations`) |
| **New Flutter Screens** | 4 |
| **New Data Models** | 4 |
| **Estimated Implementation Time** | 5–7 days |

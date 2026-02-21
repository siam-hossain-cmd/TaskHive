# TaskHive: Core Concept, Architecture & UI/UX Design

This document outlines the foundational architecture, core concepts, and design language for the Flutter-based task management application, internally referred to as "TaskHive". 

---

## 1. Core Concept & Vision
A modern, cross-platform mobile application (iOS & Android) built with Flutter. It serves as a comprehensive productivity system designed to handle both personal task management and collaborative group projects. The core philosophy is to provide a frictionless, premium user experience while supporting complex workflows like role-based permissions, continuous progress tracking, and robust file sharing.

---

## 2. Core Features Breakdown

### 2.1 Personal Task Management
*   **Rich Task Creation:** Users can define Title, Description, Subject, Due Date & Time, and Priority level.
*   **Smart Reminders:** 
    *   System-automated **24-hour warning** notifications containing a mini "Progress Report" (e.g., "You have 3 tasks left, deadline tomorrow!").
    *   User-defined custom notification times.
*   **File Management:** Unlimited file/PDF uploads attached directly to tasks for assignment storage and reference.
*   **Analytics:** Weekly performance analytics visualizing productivity trends.

### 2.2 Group & Collaborative Tasks
*   **Frictionless Connections:** Users connect via a **Unique User ID**, maintaining privacy (no phone numbers needed).
*   **Dynamic Group Workflow:** 
    *   **Assembly First:** Assign teammates via IDs prior to officially creating the group.
    *   **Role Setup:** Groups can be set up as **Democratic** (all members have equal rights) or **Leader-led**.
    *   **Approval Pipeline (Leader Mode):** In Leader mode, members submit tasks, which enter a "Pending Approval" state. The Leader reviews the attached files and officially clicks "Approve" to mark it complete, ensuring quality control.
*   **Shared Progress Tracking:** Real-time visibility into overall group completion percentages and individual member contributions.

---

## 3. Architecture Design Best Practices

To ensure massive scalability, maintainability, and high performance, the application will follow **Clean Architecture** principles.

### 3.1 Technology Stack
*   **Frontend Mobile:** Flutter (Dart) for 60/120 FPS native compilation on iOS and Android.
*   **Backend / BaaS:** Supabase or Firebase. 
    *   *Why?* Provides instant Authentication, Realtime Database (crucial for group progress sync), Cloud Storage (for unlimited PDFs), and Edge Functions (for the 24-hour auto-reminders via push notifications).
*   **State Management:** Riverpod. Modern, scalable, and highly testable state management that prevents memory leaks and handles asynchronous data beautifully.
*   **Local Database:** Isar Database or Hive. Used for offline caching so the app opens instantly and works without an internet connection.

### 3.2 Clean Architecture Layers
1.  **Presentation Layer (UI):** Contains Flutter Widgets, Screens, and Riverpod State Providers. Deals exclusively with rendering the UI and capturing user input.
2.  **Domain Layer (Entities & Logic):** Contains core models (`User`, `Task`, `Group`) and Use Cases (e.g., `SubmitTaskForApproval()`). This layer relies on pure Dart and is independent of Flutter or Firebase.
3.  **Data Layer (Repositories):** Handles data fetching, caching, and API calls. Adapts Firebase/Supabase data into Domain models.

---

## 4. UI/UX Concept & Design Language

The UI/UX must feel premium, professional, and highly responsive, mirroring top-tier enterprise apps but feeling accessible for students and individuals.

### 4.1 Visual Design Aesthetics
*   **Design System:** A blend of Modern Flat Design with subtle Glassmorphism (frosted glass effects) for overlays and bottom sheets.
*   **Color Palette (Premium & Modern):** 
    *   **Deep Dark Mode (Recommended Default):** Charcoal/Jet Black background with vibrant, glowing accent colors (e.g., Electric Blue, Neon Mint, or Sunset Orange) for progress bars, tags, and primary buttons.
    *   **Clean Light Mode:** Pure whites and soft, cool grays with the same vibrant accents to create contrast.
*   **Typography:** Modern, geometric sans-serif fonts like **Inter**, **Outfit**, or **SF Pro** for maximum legibility and a sleek look.

### 4.2 User Experience (UX) Flow
*   **The Dashboard:** A consolidated home view. Top section shows a horizontal scroll of "Daily Briefing" cards (overdue tasks, pending approvals). The middle section features beautiful circular progress rings for weekly analytics.
*   **Micro-Interactions & Gestures:** 
    *   Swipe-to-complete or Swipe-to-delete on task lists.
    *   **Haptic Feedback:** Subtle physical vibrations from the phone when crossing off a task or securing an approval to provide satisfying physical confirmation.
    *   Subtle confetti or checkmark build-animations upon completing a heavy task to reward the user psychologically.
*   **Interactive Calendar:** A seamless bottom-sheet or dedicated tab. Dates feature color-coded dots indicating task density and priority (e.g., Red dot = High priority due date, Green dot = Completed tasks).

---

## 5. Performance & Scalability Optimizations

*   **Offline-First Syncing:** The app saves all actions locally first (Optimistic UI updates) and syncs to the cloud in the background. If a user completes a task on the subway with no signal, the app registers it immediately and uploads the change when signal returns.
*   **File Upload Strategy (Unlimited PDF Management):** 
    *   Background isolate uploading: Large PDFs upload in the background without freezing the UI.
    *   App applies heavy compression to PDF thumbnails to ensure the file list loads instantly.
*   **Lazy Loading & Pagination:** Task lists and group history utilize lazy loading to maintain smooth scrolling, even if a group has 5,000 completed tasks.

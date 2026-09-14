# Student OS — Full-Stack University Student Workspace Platform

A production-grade, full-stack academic productivity platform and Operating System for university students (**"Notion + Google Drive + Google Calendar + Attendance Tracker + GPA Simulator + RAG AI Study Assistant"**).

---

## 🚀 Platform Overview & Features

Student OS is a unified student productivity suite designed to handle everything from course registration and block-based note taking to attendance governance, GPA forecasting, and grounded AI study assistance.

### 11 Core Integrated Modules

| # | Module | Core Capabilities |
| :--- | :--- | :--- |
| **1** | **Authentication & User Profiles** | Secure JWT Bearer authentication, Argon2/Bcrypt password hashing, token auto-refresh, and student profiles (Degree, University, Current Semester). |
| **2** | **Academic Hierarchy & Subjects** | Multi-tier organization (Degree $\rightarrow$ Semester $\rightarrow$ Subject) with credit calculations, custom icons, color tags, and course syllabus metadata. |
| **3** | **Notion-Style Block Notes Library** | 15 block types (Heading 1/2/3, Paragraph, Syntax-highlighted Code, Interactive Checklists, Quotes, Callouts, Tables, LaTeX Equations, Images, Files), pinned notes, favorites, tags, and full-text search. |
| **4** | **Cloud Drive & Storage Quota** | Multi-format file storage with 500 MB student quota enforcement, nested folders, category filters (PDF, DOCX, PPTX, Images, Media, Code), and file previews. |
| **5** | **Academic Planner & Kanban Tasks** | Kanban board $\leftrightarrow$ List view toggle, urgency badges (`Urgent`, `High`, `Medium`, `Low`), dynamic countdown timers (`Due in 18 hours`), grade weightings, and submission statuses (`Pending`, `In Progress`, `Submitted`, `Graded`). |
| **6** | **Exam Schedule & Unified Calendar** | Centralized assessment planner (Midterms, Finals, Quizzes, Lab Vivas) with seat numbers, locations, syllabus checklists, and a unified calendar merging exams and assignment deadlines. |
| **7** | **Timetable & Attendance Governance** | Weekly day-wise schedule with live class status, attendance logging (`Present`, `Late`, `Absent`, `Excused`), 75% minimum threshold monitoring, and automatic **Safe Bunk / Classes Needed to Target** calculation math. |
| **8** | **GPA Analytics & What-If Simulator** | Multi-scale support (4.0 / 10.0 / %), credit-weighted SGPA/CGPA, Latin Honors classification (*Summa Cum Laude*, *Magna Cum Laude*, *Cum Laude*), and an interactive **What-If Predictive Scenario Simulator & Target GPA Solver**. |
| **9** | **Smart Notifications & Alert Scanner** | Proactive background scanner generating alerts for imminent deadlines (< 24h), upcoming exams (< 48h), live classes, and low attendance warnings (< 75%). |
| **10** | **Vector Ingestion & Embeddings** | Multi-format text extractor (`pypdf`, `python-docx`, `python-pptx`, plain text, Note blocks), recursive chunking (500 chars, 100 overlap), 768-dim normalized dense vector generator, and cosine similarity search. |
| **11** | **RAG AI Study Assistant** | Grounded Q&A with strict in-text citations `[1]`, practice quiz generator with plausible distractors, 3D flip flashcard deck builder with concept mastery tracker, and high-yield exam revision summarizer. |

---

## 🛠️ Technology Stack

| Layer | Technologies |
| :--- | :--- |
| **Frontend** | Flutter (Dart 3), Material Design 3, Riverpod 2.6+ (State Management), GoRouter (Routing), Dio (HTTP Networking) |
| **Backend** | FastAPI (Python 3.11+ / 3.13), Motor (Async MongoDB driver), Pydantic v2 (Validation), Uvicorn (ASGI) |
| **Database** | MongoDB 6.0+ with automated compound indexing |
| **Document Processing** | `pypdf`, `python-docx`, `python-pptx`, `numpy` |
| **AI & Search** | 768-dim Normalized Dense Vector Embeddings, Cosine Similarity, Google Gemini API (`GEMINI_API_KEY`) with deterministic local fallback synthesizer |

---

## 📋 Prerequisites

Ensure the following tools are installed on your workstation:

* **Python**: `3.11` or newer ([Download Python](https://www.python.org/downloads/))
* **Flutter SDK**: `3.22` or newer with Dart 3+ ([Download Flutter](https://docs.flutter.dev/get-started/install))
* **MongoDB**: Community Server `6.0` or newer running locally on port `27017` ([Download MongoDB](https://www.mongodb.com/try/download/community)) or a [MongoDB Atlas](https://www.mongodb.com/cloud/atlas) connection URI.
* **Git**: ([Download Git](https://git-scm.com/))

---

## ⚡ Step-by-Step Setup & How to Run

### Step 1: Start MongoDB

Ensure MongoDB is running on your machine:

#### On Windows:
```powershell
# If installed as a Windows Service, it starts automatically.
# To start manually via Command Prompt / PowerShell:
mongod --dbpath "C:\data\db"
```

#### On macOS / Linux:
```bash
# Using brew (macOS):
brew services start mongodb-community

# Or using systemctl (Linux):
sudo systemctl start mongod
```

*Verify MongoDB is accessible at:* `mongodb://localhost:27017`

---

### Step 2: Setup and Run the FastAPI Backend

1. **Navigate to the `backend` directory**:
   ```bash
   cd backend
   ```

2. **Create and activate a Python virtual environment**:
   * **On Windows (PowerShell)**:
     ```powershell
     python -m venv venv
     .\venv\Scripts\Activate.ps1
     ```
   * **On Windows (CMD)**:
     ```cmd
     python -m venv venv
     venv\Scripts\activate.bat
     ```
   * **On macOS / Linux**:
     ```bash
     python3 -m venv venv
     source venv/bin/activate
     ```

3. **Install backend dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

4. **Configure Environment Variables (`.env`)**:
   A default `.env` file is present in `backend/.env`. You can adjust settings as needed:
   ```env
   PROJECT_NAME="Student OS API"
   VERSION="1.0.0"
   ENVIRONMENT="development"
   DEBUG=True

   # MongoDB Connection
   MONGODB_URL="mongodb://localhost:27017"
   DATABASE_NAME="student_os"

   # JWT Security Settings
   JWT_SECRET="student_os_super_secret_jwt_key_2026_dev_secure_entropy_key_change_in_prod"
   JWT_ALGORITHM="HS256"
   ACCESS_TOKEN_EXPIRE_MINUTES=60
   REFRESH_TOKEN_EXPIRE_DAYS=30

   # CORS Configuration
   CORS_ORIGINS=["*"]

   # Server Host and Port
   HOST="0.0.0.0"
   PORT=8000

   # (Optional) Google Gemini API Key for Enhanced Cloud LLM RAG Synthesis
   GEMINI_API_KEY=""
   ```

5. **Start the FastAPI server**:
   ```bash
   python run.py
   ```
   *Or using Uvicorn directly:*
   ```bash
   uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
   ```

6. **Verify Backend Status**:
   * **Swagger Interactive UI**: Open [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs) in your browser.
   * **Health Check**: Open [http://127.0.0.1:8000/api/v1/health](http://127.0.0.1:8000/api/v1/health).

---

### Step 3: Setup and Run the Flutter Frontend

1. **Open a new terminal and navigate to the `frontend` directory**:
   ```bash
   cd frontend
   ```

2. **Install Flutter packages**:
   ```bash
   flutter pub get
   ```

3. **Run the App**:
   You can run Student OS on your preferred platform:

   * **Chrome (Web)**:
     ```bash
     flutter run -d chrome
     ```
   * **Windows Desktop**:
     ```bash
     flutter run -d windows
     ```
   * **macOS Desktop**:
     ```bash
     flutter run -d macos
     ```
   * **Android Emulator / Device**:
     ```bash
     flutter run -d android
     ```
     *(Note: When running on an Android Emulator, the app automatically routes requests to `http://10.0.2.2:8000/api/v1`)*.
   * **iOS Simulator**:
     ```bash
     flutter run -d ios
     ```

---

## 🧪 Automated Testing & Verification

The project includes automated integration and unit test suites covering the entire stack.

### 1. Run Master End-to-End Test (All 11 Modules)
Executes a complete simulated student journey from authentication to block notes, file quota, vector chunking, exam planner, attendance math, GPA simulation, notifications, and AI study tools:
```bash
cd backend
python test_master_e2e.py
```

### 2. Run Individual Backend Phase Test Suites
```bash
cd backend
python test_rag_api.py           # Phase 11: RAG Engine & AI Study Assistant
python test_ingestion_api.py     # Phase 10: Document Ingestion & Vector Embeddings
python test_notifications_api.py # Phase 9: Smart Notifications & Alert Scanner
python test_analytics_api.py     # Phase 8: GPA Engine & What-If Simulator
python test_timetable_api.py     # Phase 7: Timetable & Attendance Tracking
python test_exams_api.py         # Phase 6: Exam Schedule & Study Calendar
python test_assignments_api.py   # Phase 5: Academic Planner & Assignments
python test_files_api.py         # Phase 4: Cloud File Manager & Storage Quota
python test_notes_api.py         # Phase 3: Notion-Style Block Notes
python test_subjects_api.py      # Phase 2: Academic Hierarchy & Subjects
```

### 3. Run Frontend Lint & Unit Tests
```bash
cd frontend
# 1. Verify 0 lint warnings
dart analyze lib test

# 2. Run 17 unit & model deserialization test suites
flutter test --no-pub
```

---

## 🌐 Complete API Endpoints Reference

All endpoints are prefixed with `/api/v1`:

### 🔐 Authentication & Users (`/api/v1/auth`, `/api/v1/users`)
* `POST /auth/register` — Register a new student account.
* `POST /auth/login` — Authenticate and receive JWT access & refresh tokens.
* `POST /auth/refresh` — Refresh expired JWT access token.
* `POST /auth/logout` — Invalidate student session.
* `GET /users/me` — Fetch current student profile.
* `PATCH /users/me` — Update academic details (degree, university, semester).

### 📚 Academic Hierarchy (`/api/v1/subjects`)
* `GET /subjects` — List all enrolled subjects with counts and semester filters.
* `POST /subjects` — Create a new subject with credit weighting and color tags.
* `GET /subjects/summary` — Aggregate enrolled credits and course breakdown.
* `GET /subjects/{id}` — Get single subject details.
* `PUT /subjects/{id}` — Update subject metadata.
* `DELETE /subjects/{id}` — Delete subject and cascade delete associations.

### 📝 Block Notes (`/api/v1/notes`)
* `GET /notes` — List notes with tag, subject, and favorite filtering.
* `POST /notes` — Create Notion-style structured note with 15 block types.
* `GET /notes/recent` — Fetch recently modified notes.
* `GET /notes/{id}` — Retrieve note with ordered blocks.
* `PUT /notes/{id}` — Update note title, tags, and block contents.
* `DELETE /notes/{id}` — Delete note.
* `PATCH /notes/{id}/favorite` — Toggle note favorite status.
* `PATCH /notes/{id}/pin` — Toggle note pinned status.

### ☁️ Cloud Drive & Files (`/api/v1/files`)
* `POST /files/upload` — Upload multipart file with auto type categorization.
* `GET /files` — List files with search, folder, and type filters.
* `GET /files/storage` — Get 500 MB quota usage and breakdown by file type.
* `GET /files/{id}/download` — Stream / download raw file binary.
* `PATCH /files/{id}/favorite` — Toggle file favorite status.
* `DELETE /files/{id}` — Delete file and reclaim quota.
* `POST /files/folders` — Create a folder.
* `GET /files/folders` — List folders.
* `DELETE /files/folders/{id}` — Delete folder.

### 📋 Academic Planner & Assignments (`/api/v1/assignments`)
* `GET /assignments` — List assignments with priority and status filters.
* `POST /assignments` — Create urgency-tracked assignment with weightings.
* `GET /assignments/upcoming` — Fetch upcoming assignments sorted by urgency.
* `GET /assignments/summary` — Planner summary (overdue, due this week, completion).
* `GET /assignments/{id}` — Get assignment details.
* `PUT /assignments/{id}` — Update assignment details.
* `PATCH /assignments/{id}/status` — Move assignment status (`pending` $\rightarrow$ `in_progress` $\rightarrow$ `submitted` $\rightarrow$ `graded`).
* `DELETE /assignments/{id}` — Delete assignment.

### 📅 Exams & Study Calendar (`/api/v1/exams`)
* `GET /exams` — List exams with subject and type filters.
* `POST /exams` — Schedule an exam with syllabus topics, seat number, and location.
* `GET /exams/upcoming` — Fetch imminent exams.
* `GET /exams/calendar` — Unified date-range calendar merging exams and assignment deadlines.
* `GET /exams/{id}` — Get exam details.
* `PUT /exams/{id}` — Update exam details.
* `DELETE /exams/{id}` — Delete exam.

### ⏰ Timetable & Attendance (`/api/v1/timetable`)
* `POST /timetable/slots` — Create weekly class time slot.
* `GET /timetable/weekly` — Get 7-day organized timetable.
* `GET /timetable/today` — Live class schedule with ongoing / upcoming status.
* `POST /timetable/attendance` — Log class attendance (`present`, `late`, `absent`, `excused`).
* `GET /timetable/attendance/summary` — 75% attendance rule summary with **Safe Bunk** & **Classes Needed to Target** metrics.
* `GET /timetable/attendance/logs` — Fetch chronological attendance history.

### 📊 GPA & Academic Analytics (`/api/v1/analytics`)
* `GET /analytics/gpa/summary` — CGPA, SGPA, Latin honors standing, and credit completion progress.
* `GET /analytics/gpa/semesters` — Semester-by-semester GPA breakdown.
* `PUT /analytics/subjects/{id}/grade` — Record letter/numerical grade for a subject.
* `POST /analytics/gpa/what-if` — What-If Predictive Scenario Simulator & Target GPA Solver.

### 🔔 Smart Notifications (`/api/v1/notifications`)
* `GET /notifications` — List active notifications and alerts with type filters.
* `GET /notifications/unread-count` — Real-time badge counter.
* `POST /notifications/generate-alerts` — Trigger proactive multi-module background scanner.
* `PATCH /notifications/{id}/read` — Mark notification as read.
* `POST /notifications/mark-all-read` — Mark all notifications as read.
* `DELETE /notifications/read` — Purge read notifications.

### 🧠 Document Ingestion & Embeddings (`/api/v1/ingestion`)
* `POST /ingestion/files/{id}/process` — Extract text and generate 768-dim vector chunks for a file.
* `POST /ingestion/notes/{id}/process` — Extract and vectorize Notion block note.
* `GET /ingestion/status/{source_id}` — Check source indexing status.
* `GET /ingestion/stats` — Total chunks, indexed files, notes, and token counts.
* `POST /ingestion/query` — Execute top-$K$ cosine similarity vector search.
* `DELETE /ingestion/sources/{source_id}` — Purge vector chunks for a source.

### 🤖 Grounded RAG AI Study Assistant (`/api/v1/ai`)
* `POST /ai/chat` — Conversational study Q&A grounded in uploaded notes & files with in-text citations.
* `POST /ai/generate-quiz` — Auto-generate MCQs with plausible distractors, explanations, and citations.
* `POST /ai/generate-flashcards` — Auto-generate 3D concept review flashcard decks.
* `POST /ai/summarize` — Generate high-yield exam revision cheat sheets.
* `GET /ai/conversations` — List previous study chat sessions.
* `GET /ai/conversations/{session_id}` — Retrieve conversation message history.
* `DELETE /ai/conversations/{session_id}` — Delete study session.

---

## 📂 Project Directory Layout

```
Notes_App/
├── backend/
│   ├── app/
│   │   ├── main.py                  # FastAPI Application Entry & Lifespan Hooks
│   │   ├── core/                    # Config, Database Pool, JWT Security
│   │   ├── schemas/                 # Pydantic v2 Models for all 11 modules
│   │   ├── repositories/            # Async MongoDB CRUD Repositories
│   │   ├── services/                # Business Logic, RAG Engine, Ingestion, Analytics
│   │   └── api/v1/                  # REST Routers mounted under /api/v1
│   ├── test_master_e2e.py           # Master End-to-End Student Journey Test
│   ├── test_rag_api.py              # Phase 11 RAG Integration Test
│   ├── test_ingestion_api.py        # Phase 10 Ingestion Integration Test
│   ├── test_notifications_api.py    # Phase 9 Notifications Integration Test
│   ├── test_analytics_api.py        # Phase 8 GPA Analytics Integration Test
│   ├── test_timetable_api.py        # Phase 7 Timetable Integration Test
│   ├── test_exams_api.py            # Phase 6 Exams Integration Test
│   ├── test_assignments_api.py      # Phase 5 Planner Integration Test
│   ├── test_files_api.py            # Phase 4 Files Integration Test
│   ├── test_notes_api.py            # Phase 3 Notes Integration Test
│   ├── test_subjects_api.py         # Phase 2 Subjects Integration Test
│   ├── requirements.txt             # Backend Python Dependencies
│   └── run.py                       # Backend Launch Script
│
└── frontend/
    ├── lib/
    │   ├── main.dart                # Flutter Application Entrypoint
    │   ├── core/                    # Theme, Router, Network Client, Token Storage
    │   ├── features/
    │   │   ├── auth/                # Login, Register, User Providers & Screens
    │   │   ├── subjects/            # Subjects List, Create/Edit Dialogs, Cards
    │   │   ├── notes/               # Block Note Editor, Markdown, Code, Checklists
    │   │   ├── files/               # Cloud Drive, Storage Quota Bar, File Viewer
    │   │   ├── assignments/         # Academic Planner, Kanban Board, Urgency Badges
    │   │   ├── exams/               # Exam Schedule, Assessments, Unified Calendar
    │   │   ├── timetable/           # Weekly Timetable, Live Schedule, Safe Bunks
    │   │   ├── analytics/           # CGPA Cards, Honors Standing, What-If Simulator
    │   │   ├── notifications/       # Notification Center, Alerts, Badge Counters
    │   │   ├── ingestion/           # Indexing Status Badges, Knowledge Base Card
    │   │   ├── ai/                  # AI Study Assistant Hub, Quizzes, Flashcards
    │   │   └── dashboard/           # Main Student Dashboard & Quick Actions
    │   └── shared/                  # Reusable Cards, Badges, Modals, Buttons
    └── test/
        └── widget_test.dart         # Unit & Model Serialization Tests (17 Suites)
```

---

## ❓ Troubleshooting & FAQs

### 1. `RuntimeError: Database connection has not been initialized`
* Ensure your local MongoDB server is running on port `27017` (`mongod --dbpath <data_dir>`).
* Verify `MONGODB_URL` in `backend/.env` points to your active MongoDB instance.

### 2. Android Emulator cannot connect to the backend (`Connection Refused`)
* Android Emulators use `http://10.0.2.2:8000` to refer to the host computer's `localhost`.
* The Flutter frontend is already configured in [`api_endpoints.dart`](file:///f:/Vibe_Coding/Notes_App/frontend/lib/core/constants/api_endpoints.dart) to automatically use `10.0.2.2` when running on Android. Ensure the FastAPI backend is running with `--host 0.0.0.0`.

### 3. Port 8000 is already in use
* Change the port in `backend/.env` or run Uvicorn with a custom port:
  ```bash
  uvicorn app.main:app --host 0.0.0.0 --port 8080 --reload
  ```
* Update the port in `frontend/lib/core/constants/api_endpoints.dart`.

### 4. Enabling Google Gemini Cloud LLM for AI Study Assistant
* By default, Student OS includes an intelligent local deterministic study synthesizer that works offline.
* To enable Google Gemini cloud synthesis:
  1. Obtain an API key from [Google AI Studio](https://aistudio.google.com/).
  2. Set `GEMINI_API_KEY="your_actual_key"` in `backend/.env`.
  3. Restart the backend.

---

## 📄 License

This project is licensed under the MIT License — free for academic, personal, and commercial development.

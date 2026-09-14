# Student OS — Project Issues & Known Technical Debt

This document tracks identified bugs, platform-specific edge cases, networking hurdles, database configurations, and mitigation strategies across the **Student OS** full-stack ecosystem (FastAPI + MongoDB + Flutter).

---

## 1. Networking & Device Connectivity

### 1.1 Android Physical Device vs. Emulator Gateway (`10.0.2.2` vs `127.0.0.1`)
- **Issue**: Android Studio AVD Emulators route `10.0.2.2` to the host machine's `localhost`. However, physical Android devices (connected via USB or Wi-Fi) cannot resolve `10.0.2.2` and will fail with `DioException [connection timeout]`.
- **Root Cause**: On physical hardware, `10.0.2.2` does not map to the host loopback adapter.
- **Resolution**:
  - **Over USB (Recommended)**: Run `adb reverse tcp:8000 tcp:8000`. This allows the phone to access the host backend on `http://127.0.0.1:8000/api/v1`.
  - **Over Wi-Fi (Same LAN)**: Launch Flutter with:
    ```bash
    flutter run --dart-define=API_BASE_URL=http://<HOST_LOCAL_IP>:8000/api/v1
    ```
  - **On AVD Emulator**: Launch Flutter with:
    ```bash
    flutter run --dart-define=USE_EMULATOR_GATEWAY=true
    ```

### 1.2 Windows Firewall Blocking Incoming Local LAN Connections
- **Issue**: Physical devices over Wi-Fi may time out when querying `http://<HOST_IP>:8000/api/v1` even when on the same subnet.
- **Root Cause**: Windows Defender Firewall often blocks incoming port 8000 traffic on Private/Public network profiles.
- **Resolution**: Add an inbound firewall rule allowing TCP traffic on port 8000 in Windows Defender Firewall or start the backend on `HOST="0.0.0.0"`.

---

## 2. Database & Authentication

### 2.1 MongoDB Atlas DNS SRV & Certificate Validation Warnings on Windows
- **Issue**: Connecting to MongoDB Atlas clusters (`mongodb+srv://...`) on Windows using Python 3.13 may log:
  ```text
  CryptographyDeprecationWarning: Parsed a negative serial number, which is disallowed by RFC 5280.
  ```
- **Impact**: Non-fatal warning emitted by OpenSSL/cryptography during TLS handshake.
- **Mitigation**: Standardize on `pymongo>=4.9.0` and `cryptography>=43.0.0`. Ensure IP whitelist (`0.0.0.0/0` or current IP) is enabled in MongoDB Atlas Network Access.

### 2.2 Unseeded Databases on Fresh Environment Setup
- **Issue**: When switching from local MongoDB (`mongodb://localhost:27017`) to a cloud Atlas cluster, the default student account (`alex.rivera@stanford.edu`) was missing, causing initial login attempts to return `401 Unauthorized`.
- **Resolution**: Implemented auto-seeding in `app.core.seed.seed_initial_data()` triggered on `connect_to_mongo()`. If the sample student is absent, the backend seeds the account (`Student123!`), subjects, notes, assignments, exams, and timetable slots.

### 2.3 Token Expiration & Refresh Flow
- **Issue**: Access tokens expire after 60 minutes (`ACCESS_TOKEN_EXPIRE_MINUTES=60`). If an access token expires during background app state, standard requests fail with `401`.
- **Resolution**: `AuthInterceptor` automatically attempts `POST /api/v1/auth/refresh` using the stored `refresh_token` before rejecting the request. If the refresh token has expired (after 30 days), local storage is cleared and the user is redirected to `/login`.

---

## 3. Frontend & Layout Responsiveness

### 3.1 Mobile Screen Width Overflows (`A RenderFlex overflowed by ... pixels`)
- **Issue**: Fixed `Row` layouts inside cards and headers exceeded available width on narrow mobile displays (e.g. 360–390px wide screens).
- **Key Affected Areas**:
  - Dashboard Hero Metrics (`Enrolled Subjects`, `Total Credits`, `Current Sem`).
  - Attendance Action Buttons (`Present`, `Late`, `Absent`, `Excused`) on `TodayScheduleCard`.
  - Due date and badge rows on `AssignmentCard` and `ExamCard`.
- **Resolution**: Replaced rigid `Row` widgets with `Wrap(spacing: 8, runSpacing: 8)` and `Expanded(child: Text(..., overflow: TextOverflow.ellipsis))` across all card components.

### 3.2 Kotlin Incremental Compilation Daemon Caches on Windows
- **Issue**: Flutter build on Windows occasionally encounters:
  ```text
  Could not close incremental caches in ...\build\file_picker\kotlin\compileDebugKotlin...
  IllegalArgumentException: this and base files have different roots: C:\... and F:\...
  ```
- **Root Cause**: Gradle daemon runs across two different drive letters (`C:` for pub cache and `F:` for project files), confusing Kotlin's incremental cache relative-path calculator.
- **Resolution**:
  - Run `flutter clean` and `flutter pub get`.
  - Alternatively, pass `--no-daemon` or build via `./gradlew assembleDebug --no-daemon` inside `frontend/android/`.

---

## 4. Ingestion Pipeline & AI Study Assistant

### 4.1 Missing Gemini API Key Fallback
- **Issue**: If `GEMINI_API_KEY` is not provided in `.env`, external LLM requests to Google AI Studio fail.
- **Resolution**:
  - `EmbeddingService` falls back to a deterministic 768-dimensional local sub-word n-gram dense vector projector with L2-normalization and cosine similarity ranking.
  - `RagService` falls back to local grounded heuristic summarization, practice quiz generators, and flashcard builders derived directly from indexed document chunks.

### 4.2 Large File Upload Timeouts
- **Issue**: Uploading 50+ MB PDFs over slow mobile networks can trigger Dio client timeouts (15s default).
- **Resolution**: Configured chunked extraction via `pypdf` / `python-docx` / `python-pptx` and separated the upload endpoint (`/files/upload`) from the asynchronous vector ingestion endpoint (`/ingestion/files/{id}/process`).

---

## 5. Summary Matrix & Priority Tracking

| ID | Module | Issue Description | Severity | Status | Resolution |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **NET-01** | Network | Physical Android USB connection failure | High | ✅ Resolved | Run `adb reverse tcp:8000 tcp:8000` |
| **AUTH-01** | Auth | Missing initial sample student on fresh DB | High | ✅ Resolved | Added auto-seed in `database.py` & `seed.py` |
| **AUTH-02** | Auth | Multi-subdomain university email validation | Medium | ✅ Resolved | Upgraded regex in `validators.dart` |
| **UI-01** | UI/UX | Right overflow on mobile dashboard & cards | Medium | ✅ Resolved | Replaced fixed `Row`s with `Wrap` & `Expanded` |
| **UI-02** | UI/UX | Small tap target on "Create an account" link | Medium | ✅ Resolved | Replaced `GestureDetector` with padded `InkWell` |
| **AI-01** | AI / RAG | Offline execution without Gemini API Key | Low | ✅ Resolved | Implemented deterministic local dense fallback |
| **BLD-01** | Build | Multi-drive letter Kotlin incremental cache | Low | ℹ️ Workaround | `flutter clean` / build with `--no-daemon` |

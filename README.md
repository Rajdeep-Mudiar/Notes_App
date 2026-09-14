# Student OS — Full-Stack University Student Workspace Platform

A production-quality academic productivity platform for university students ("Notion + Google Drive + Google Calendar + Student Planner + AI Study Assistant").

---

## Architecture Overview (Phase 1)

* **Frontend**: Flutter (Dart) with Material 3, Riverpod State Management, GoRouter, Dio HTTP client, SharedPreferences persistent token storage, and feature-based architecture.
* **Backend**: FastAPI (Python 3.13) with asynchronous MongoDB driver (Motor), Pydantic v2 schemas, bcrypt password hashing, and JWT bearer authentication.
* **Database**: MongoDB with automated indexing on `users.email` and `users.created_at`.

```
Notes_App/
├── backend/
│   ├── app/
│   │   ├── main.py
│   │   ├── core/
│   │   │   ├── config.py
│   │   │   ├── database.py
│   │   │   └── security.py
│   │   ├── models/
│   │   │   └── user.py
│   │   ├── schemas/
│   │   │   ├── auth.py
│   │   │   ├── user.py
│   │   │   └── response.py
│   │   ├── api/
│   │   │   ├── deps.py
│   │   │   └── v1/
│   │   │       ├── api.py
│   │   │       ├── auth.py
│   │   │       └── users.py
│   │   ├── repositories/
│   │   │   └── user_repository.py
│   │   └── services/
│   │       └── auth_service.py
│   ├── requirements.txt
│   ├── .env
│   ├── run.py
│   ├── verify_backend.py
│   └── test_e2e_http.py
└── frontend/
    ├── pubspec.yaml
    └── lib/
        ├── main.dart
        ├── core/
        │   ├── constants/
        │   ├── network/
        │   ├── router/
        │   ├── storage/
        │   ├── theme/
        │   └── utils/
        ├── features/
        │   ├── auth/
        │   └── dashboard/
        └── shared/
            └── widgets/
```

---

## How to Run the Application

### 1. Start MongoDB
Ensure MongoDB is running locally on port 27017:
```bash
mongod --dbpath <data_directory>
```

### 2. Run the FastAPI Backend
```bash
cd backend
python -m pip install -r requirements.txt
python run.py
```
* API Server will start at: `http://127.0.0.1:8000`
* Swagger Interactive Docs: `http://127.0.0.1:8000/docs`
* Health Check Endpoint: `http://127.0.0.1:8000/api/v1/health`

### 3. Run the Flutter Frontend
```bash
cd frontend
flutter pub get
flutter run -d chrome # or windows / android / ios
```

---

## Phase 1 Automated Tests

To run the backend integration & auth test suite:
```bash
cd backend
python verify_backend.py
python test_e2e_http.py
```

To run Flutter static analysis & tests:
```bash
cd frontend
flutter analyze
flutter test
```

import uuid
from datetime import datetime, timezone, timedelta
from fastapi.testclient import TestClient
import pymongo
from app.main import app
from app.core.config import settings

client = TestClient(app)


def test_exams_e2e_flow():
    print("==================================================")
    print("PHASE 6: EXAM SCHEDULE & STUDY CALENDAR E2E TEST")
    print("==================================================")

    test_email = f"exam_student_{uuid.uuid4().hex[:6]}@university.edu"
    test_password = "Password123!"

    with client:
        # 1. Register student
        print("\n[Step 1] Registering student...")
        reg_res = client.post("/api/v1/auth/register", json={
            "email": test_email,
            "password": test_password,
            "full_name": "Alan Turing",
            "university": "Cambridge University",
            "degree": "B.A. Mathematics & Computer Science",
            "current_semester": 6
        })
        assert reg_res.status_code == 201
        token = reg_res.json()["data"]["tokens"]["access_token"]
        user_id = reg_res.json()["data"]["user"]["id"]
        headers = {"Authorization": f"Bearer {token}"}
        print(f" Student registered (ID: {user_id})")

        # 2. Create Subject: Computer Architecture
        print("\n[Step 2] Creating Subject: Computer Architecture...")
        sub_res = client.post("/api/v1/subjects", headers=headers, json={
            "name": "Computer Architecture & Organization",
            "code": "CS304",
            "credits": 4,
            "color": "#F59E0B",
            "icon": "memory",
            "semester": 6
        })
        assert sub_res.status_code == 201
        subject_id = sub_res.json()["data"]["id"]
        print(f" Subject created (ID: {subject_id})")

        # 3. Schedule Midterm Exam (in 4 days)
        print("\n[Step 3] Scheduling Midterm Exam...")
        exam_date_1 = (datetime.now(timezone.utc) + timedelta(days=4, hours=2)).isoformat()
        create_res_1 = client.post("/api/v1/exams", headers=headers, json={
            "title": "Midterm Exam - Pipelining & Caching",
            "subject_id": subject_id,
            "exam_type": "midterm",
            "date_time": exam_date_1,
            "duration_minutes": 120,
            "location": "Turing Lecture Hall, Room 302",
            "seat_number": "D-14",
            "syllabus_topics": ["MIPS Instruction Set", "5-Stage Pipeline", "Hazard Resolution", "Direct-Mapped & Associative Caches"],
            "weight_percentage": 30.0,
            "target_grade": 92.0,
            "notes": "1 double-sided cheat sheet permitted. No graphing calculators."
        })
        assert create_res_1.status_code == 201, f"Error: {create_res_1.text}"
        exam_1 = create_res_1.json()["data"]
        exam_1_id = exam_1["id"]
        assert exam_1["title"] == "Midterm Exam - Pipelining & Caching"
        assert exam_1["exam_type"] == "midterm"
        assert exam_1["subject_code"] == "CS304"
        assert exam_1["duration_minutes"] == 120
        assert exam_1["seat_number"] == "D-14"
        assert len(exam_1["syllabus_topics"]) == 4
        print(f" Exam 1 scheduled: '{exam_1['title']}' (Countdown: {exam_1['countdown_text']})")

        # 4. Schedule Final Exam (in 30 days)
        print("\n[Step 4] Scheduling Final Exam...")
        exam_date_2 = (datetime.now(timezone.utc) + timedelta(days=30)).isoformat()
        create_res_2 = client.post("/api/v1/exams", headers=headers, json={
            "title": "Comprehensive Final Examination",
            "subject_id": subject_id,
            "exam_type": "final",
            "date_time": exam_date_2,
            "duration_minutes": 180,
            "location": "Main University Gymnasium / Grand Hall",
            "syllabus_topics": ["Complete Semester Syllabus", "Superscalar Out-of-Order Execution", "Virtual Memory & TLBs"],
            "weight_percentage": 45.0,
            "target_grade": 90.0,
        })
        assert create_res_2.status_code == 201
        exam_2 = create_res_2.json()["data"]
        exam_2_id = exam_2["id"]
        print(f" Exam 2 scheduled: '{exam_2['title']}' (Countdown: {exam_2['countdown_text']})")

        # 5. Create an Assignment to verify unified Calendar integration
        print("\n[Step 5] Creating Assignment to test unified Study Calendar...")
        asgn_due = (datetime.now(timezone.utc) + timedelta(days=6)).isoformat()
        asgn_res = client.post("/api/v1/assignments", headers=headers, json={
            "title": "Cache Simulator Project (Verilog)",
            "subject_id": subject_id,
            "due_date": asgn_due,
            "priority": "high",
            "weight_percentage": 15.0
        })
        assert asgn_res.status_code == 201
        print(" Related assignment created.")

        # 6. Check Subject exams_count auto-sync
        print("\n[Step 6] Checking Subject exams_count auto-sync...")
        sub_check = client.get(f"/api/v1/subjects/{subject_id}", headers=headers)
        assert sub_check.status_code == 200
        assert sub_check.json()["data"]["exams_count"] == 2
        print(" Subject exams_count accurately reflects 2 scheduled exams.")

        # 7. List Exams with filters
        print("\n[Step 7] Listing exams filtered by subject and type...")
        list_res = client.get(f"/api/v1/exams?subject_id={subject_id}&exam_type=midterm", headers=headers)
        assert list_res.status_code == 200
        list_data = list_res.json()["data"]
        assert list_data["total"] == 2
        assert len(list_data["items"]) == 1
        assert list_data["items"][0]["id"] == exam_1_id
        print(" Filtered exams list verified.")

        # 8. Test Upcoming Exams endpoint
        print("\n[Step 8] Testing GET /api/v1/exams/upcoming...")
        up_res = client.get("/api/v1/exams/upcoming?limit=5", headers=headers)
        assert up_res.status_code == 200
        upcoming = up_res.json()["data"]
        assert len(upcoming) == 2
        assert upcoming[0]["id"] == exam_1_id  # Earlier date first
        print(f" Retrieved {len(upcoming)} upcoming exam(s) in chronological order.")

        # 9. Test Unified Study Calendar endpoint
        print("\n[Step 9] Testing GET /api/v1/exams/calendar...")
        cal_start = (datetime.now(timezone.utc) - timedelta(days=1)).isoformat()
        cal_end = (datetime.now(timezone.utc) + timedelta(days=45)).isoformat()
        cal_res = client.get(f"/api/v1/exams/calendar?start_date={cal_start}&end_date={cal_end}", headers=headers)
        assert cal_res.status_code == 200
        cal_data = cal_res.json()["data"]
        assert cal_data["total_events"] == 3  # 2 exams + 1 assignment
        types = [ev["type"] for ev in cal_data["events"]]
        assert "exam" in types
        assert "assignment" in types
        print(f" Unified Study Calendar verified: {cal_data['total_events']} events (merged exams + assignment deadlines).")

        # 10. Update Exam 1 with Actual Grade and Feedback
        print("\n[Step 10] Updating Exam 1 with Actual Grade...")
        upd_res = client.put(f"/api/v1/exams/{exam_1_id}", headers=headers, json={
            "actual_grade": 94.5,
            "notes": "Scored 94.5%. Perfect score on Hazard Resolution section."
        })
        assert upd_res.status_code == 200
        exam_1_updated = upd_res.json()["data"]
        assert exam_1_updated["actual_grade"] == 94.5
        assert exam_1_updated["is_completed"] is True
        print(f" Exam 1 scored: {exam_1_updated['actual_grade']}% (Target was {exam_1_updated['target_grade']}%)")

        # 11. Delete Exam 2
        print("\n[Step 11] Deleting Exam 2...")
        del_res = client.delete(f"/api/v1/exams/{exam_2_id}", headers=headers)
        assert del_res.status_code == 200
        print(" Exam 2 deleted.")

        # 12. Verify Subject exams_count decremented to 1
        sub_check2 = client.get(f"/api/v1/subjects/{subject_id}", headers=headers)
        assert sub_check2.json()["data"]["exams_count"] == 1
        print(" Subject exams_count correctly decremented back to 1.")

    # Cleanup Database
    sync_client = pymongo.MongoClient(settings.MONGODB_URL)
    sync_db = sync_client[settings.DATABASE_NAME]
    sync_db["users"].delete_one({"email": test_email})
    sync_db["subjects"].delete_many({"user_id": user_id})
    sync_db["exams"].delete_many({"user_id": user_id})
    sync_db["assignments"].delete_many({"user_id": user_id})
    sync_client.close()
    print("\n Cleaned up test data from MongoDB.")

    print("\n All Phase 6 Exam Schedule & Study Calendar API Tests PASSED!")
    print("==================================================")


if __name__ == "__main__":
    test_exams_e2e_flow()

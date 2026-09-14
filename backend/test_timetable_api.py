import uuid
from datetime import date, datetime, timezone
from fastapi.testclient import TestClient
import pymongo

from app.main import app
from app.core.config import settings


def run_timetable_tests():
    print("=" * 50)
    print("PHASE 7: TIMETABLE & ATTENDANCE TRACKER E2E TEST")
    print("=" * 50)

    unique_id = uuid.uuid4().hex[:8]
    test_email = f"student_timetable_{unique_id}@stanford.edu"
    test_password = "SecurePassword123!"

    with TestClient(app) as client:
        # Step 1: Register User
        print("\n[Step 1] Registering student...")
        reg_payload = {
            "email": test_email,
            "password": test_password,
            "full_name": "Maya Lin",
            "university": "Stanford University",
            "degree": "B.S. Computer Systems",
            "current_semester": 4,
        }
        res = client.post("/api/v1/auth/register", json=reg_payload)
        assert res.status_code == 201, f"Registration failed: {res.text}"
        auth_data = res.json()["data"]
        token = auth_data["tokens"]["access_token"]
        user_id = auth_data["user"]["id"]
        headers = {"Authorization": f"Bearer {token}"}
        print(f" Student registered (ID: {user_id})")

        # Step 2: Create Subjects
        print("\n[Step 2] Creating Subjects for Timetable...")
        sub1_res = client.post(
            "/api/v1/subjects",
            headers=headers,
            json={
                "name": "Design & Analysis of Algorithms",
                "code": "CS161",
                "credits": 4,
                "color": "#4F46E5",
                "professor": "Dr. Tim Roughgarden",
            },
        )
        assert sub1_res.status_code == 201
        sub1_id = sub1_res.json()["data"]["id"]

        sub2_res = client.post(
            "/api/v1/subjects",
            headers=headers,
            json={
                "name": "Computer Systems & Networking",
                "code": "CS144",
                "credits": 4,
                "color": "#10B981",
                "professor": "Dr. Nick McKeown",
            },
        )
        assert sub2_res.status_code == 201
        sub2_id = sub2_res.json()["data"]["id"]
        print(f" Subjects created: CS161 (ID: {sub1_id}), CS144 (ID: {sub2_id})")

        # Step 3: Create Timetable Slots
        print("\n[Step 3] Scheduling Timetable Slots...")
        slot1_res = client.post(
            "/api/v1/timetable/slots",
            headers=headers,
            json={
                "subject_id": sub1_id,
                "day_of_week": "monday",
                "start_time": "09:00",
                "end_time": "10:30",
                "class_type": "lecture",
                "location": "Skilling Auditorium 080",
                "professor_name": "Dr. Tim Roughgarden",
            },
        )
        assert slot1_res.status_code == 201, f"Create slot 1 failed: {slot1_res.text}"
        slot1 = slot1_res.json()["data"]
        slot1_id = slot1["id"]
        assert slot1["subject_code"] == "CS161"
        assert slot1["day_of_week"] == "monday"
        print(f" Slot 1 created: CS161 Lecture Monday 09:00-10:30 (ID: {slot1_id})")

        slot2_res = client.post(
            "/api/v1/timetable/slots",
            headers=headers,
            json={
                "subject_id": sub2_id,
                "day_of_week": "monday",
                "start_time": "11:00",
                "end_time": "12:30",
                "class_type": "lab",
                "location": "Packard Electrical Bldg 108",
            },
        )
        assert slot2_res.status_code == 201
        slot2_id = slot2_res.json()["data"]["id"]
        print(f" Slot 2 created: CS144 Lab Monday 11:00-12:30 (ID: {slot2_id})")

        # Step 4: Test Collision Detection
        print("\n[Step 4] Testing Overlap Collision Detection...")
        overlap_res = client.post(
            "/api/v1/timetable/slots",
            headers=headers,
            json={
                "subject_id": sub2_id,
                "day_of_week": "monday",
                "start_time": "10:00",  # Overlaps with 09:00-10:30!
                "end_time": "11:30",
                "class_type": "tutorial",
            },
        )
        assert overlap_res.status_code == 400, f"Expected 400 collision rejection, got: {overlap_res.status_code}"
        print(f" Successfully prevented overlapping time slot: {overlap_res.json()['message']}")

        # Step 5: Test Weekly Schedule Endpoint
        print("\n[Step 5] Testing GET /api/v1/timetable/weekly...")
        weekly_res = client.get("/api/v1/timetable/weekly", headers=headers)
        assert weekly_res.status_code == 200
        weekly_data = weekly_res.json()["data"]
        assert len(weekly_data["monday"]) == 2
        assert weekly_data["total_slots"] == 2
        print(f" Weekly schedule verified: {weekly_data['total_slots']} slots across the week.")

        # Step 6: Test Today's Schedule Endpoint
        print("\n[Step 6] Testing GET /api/v1/timetable/today with simulated Monday date...")
        # 2026-09-14 is a Monday!
        today_res = client.get("/api/v1/timetable/today?date=2026-09-14", headers=headers)
        assert today_res.status_code == 200
        today_classes = today_res.json()["data"]
        assert len(today_classes) == 2
        assert today_classes[0]["slot"]["id"] == slot1_id
        assert today_classes[0]["status"] in ["ongoing", "upcoming", "completed"]
        print(f" Today's schedule returned {len(today_classes)} classes with live status: '{today_classes[0]['time_status_text']}'")

        # Step 7: Log Attendance
        print("\n[Step 7] Logging Attendance Records...")
        # Mark Slot 1 (CS161) as Present on 2026-09-14
        att1_res = client.post(
            "/api/v1/timetable/attendance",
            headers=headers,
            json={
                "slot_id": slot1_id,
                "subject_id": sub1_id,
                "date": "2026-09-14",
                "status": "present",
                "notes": "Covered master theorem and divide & conquer.",
            },
        )
        assert att1_res.status_code == 201
        att1 = att1_res.json()["data"]
        assert att1["status"] == "present"
        assert att1["subject_code"] == "CS161"
        print(" Logged CS161 attendance as 'present'.")

        # Mark Slot 2 (CS144) as Absent on 2026-09-14
        att2_res = client.post(
            "/api/v1/timetable/attendance",
            headers=headers,
            json={
                "slot_id": slot2_id,
                "subject_id": sub2_id,
                "date": "2026-09-14",
                "status": "absent",
                "notes": "Doctor appointment.",
            },
        )
        assert att2_res.status_code == 201
        att2_id = att2_res.json()["data"]["id"]
        print(" Logged CS144 attendance as 'absent'.")

        # Step 8: Verify Attendance Summary & Safe Bunk Analytics
        print("\n[Step 8] Verifying Attendance Analytics & Safe Bunk Math...")
        summary_res = client.get("/api/v1/timetable/attendance/summary?target_percentage=75.0", headers=headers)
        assert summary_res.status_code == 200
        summary = summary_res.json()["data"]
        assert summary["overall_total_classes"] == 2
        assert summary["overall_attended_classes"] == 1
        assert summary["overall_absent_classes"] == 1
        assert summary["overall_percentage"] == 50.0

        # CS161 should have 100% attendance and safe bunks
        cs161_stats = next(s for s in summary["subjects_stats"] if s["subject_id"] == sub1_id)
        assert cs161_stats["attendance_percentage"] == 100.0
        assert cs161_stats["is_critical"] is False

        # CS144 should have 0% attendance, is_critical = True, and need recovery classes
        cs144_stats = next(s for s in summary["subjects_stats"] if s["subject_id"] == sub2_id)
        assert cs144_stats["attendance_percentage"] == 0.0
        assert cs144_stats["is_critical"] is True
        assert cs144_stats["classes_needed_to_target"] >= 1
        print(f" Analytics verified: CS161=100% (Healthy), CS144=0% (Critical, needs {cs144_stats['classes_needed_to_target']} classes to hit 75%).")

        # Step 9: Update Attendance Log (Excused status)
        print("\n[Step 9] Updating Attendance Log...")
        upd_att_res = client.put(
            f"/api/v1/timetable/attendance/{att2_id}",
            headers=headers,
            json={"status": "excused", "notes": "Medical certificate submitted."},
        )
        assert upd_att_res.status_code == 200
        assert upd_att_res.json()["data"]["status"] == "excused"
        print(" Updated CS144 attendance status to 'excused'.")

        # Step 10: Re-verify Attendance Summary after Excused update
        print("\n[Step 10] Checking updated summary (Excused counts as attended)...")
        summary2_res = client.get("/api/v1/timetable/attendance/summary", headers=headers)
        assert summary2_res.status_code == 200
        summary2 = summary2_res.json()["data"]
        assert summary2["overall_attended_classes"] == 2
        assert summary2["overall_percentage"] == 100.0
        print(f" Summary updated: Overall attendance is now {summary2['overall_percentage']}%.")

        # Step 11: Update Slot 1
        print("\n[Step 11] Updating Slot 1 details...")
        upd_slot_res = client.put(
            f"/api/v1/timetable/slots/{slot1_id}",
            headers=headers,
            json={"location": "Gates Computer Science B01", "class_type": "seminar"},
        )
        assert upd_slot_res.status_code == 200
        assert upd_slot_res.json()["data"]["location"] == "Gates Computer Science B01"
        assert upd_slot_res.json()["data"]["class_type"] == "seminar"
        print(" Slot 1 updated successfully.")

        # Step 12: Delete Slot 2
        print("\n[Step 12] Deleting Slot 2...")
        del_slot_res = client.delete(f"/api/v1/timetable/slots/{slot2_id}", headers=headers)
        assert del_slot_res.status_code == 200
        assert del_slot_res.json()["data"]["deleted"] is True
        print(" Slot 2 deleted successfully.")

    # Cleanup Database
    sync_client = pymongo.MongoClient(settings.MONGODB_URL)
    sync_db = sync_client[settings.DATABASE_NAME]
    sync_db["users"].delete_one({"email": test_email})
    sync_db["subjects"].delete_many({"user_id": pymongo.collection.ObjectId(user_id)})
    sync_db["timetable_slots"].delete_many({"user_id": pymongo.collection.ObjectId(user_id)})
    sync_db["attendance_logs"].delete_many({"user_id": pymongo.collection.ObjectId(user_id)})
    sync_client.close()
    print("\n Cleaned up test data from MongoDB.")

    print("\n" + "=" * 50)
    print(" All Phase 7 Timetable & Attendance API Tests PASSED!")
    print("=" * 50)


if __name__ == "__main__":
    run_timetable_tests()

import uuid
from datetime import datetime, timezone, timedelta
from fastapi.testclient import TestClient
import pymongo

from app.main import app
from app.core.config import settings


def run_notifications_e2e_test():
    print("=" * 50)
    print("PHASE 9: SMART NOTIFICATIONS & ALERTS E2E TEST")
    print("=" * 50)

    unique_id = uuid.uuid4().hex[:8]
    test_email = f"student_notify_{unique_id}@mit.edu"
    test_password = "SecurePassword123!"

    with TestClient(app) as client:
        # 1. Register Student
        print("\n[Step 1] Registering student...")
        reg_payload = {
            "email": test_email,
            "password": test_password,
            "full_name": "Sarah Connor",
            "university": "MIT",
            "degree": "B.S. Robotics",
            "current_semester": 3,
        }
        reg_resp = client.post("/api/v1/auth/register", json=reg_payload)
        assert reg_resp.status_code == 201, f"Registration failed: {reg_resp.text}"
        token = reg_resp.json()["data"]["tokens"]["access_token"]
        user_id = reg_resp.json()["data"]["user"]["id"]
        headers = {"Authorization": f"Bearer {token}"}
        print(f" Student registered (ID: {user_id})")

        # 2. Create Subjects
        print("\n[Step 2] Creating Enrolled Subjects (ROB301 & ROB302)...")
        sub1_resp = client.post(
            "/api/v1/subjects",
            json={
                "name": "Robotics & Kinematics",
                "code": f"ROB_{unique_id[:4]}A",
                "credits": 4,
                "color": "#4F46E5",
                "semester": 3,
            },
            headers=headers,
        )
        assert sub1_resp.status_code == 201, f"Create sub1 failed: {sub1_resp.text}"
        sub1_id = sub1_resp.json()["data"]["id"]

        sub2_resp = client.post(
            "/api/v1/subjects",
            json={
                "name": "Embedded Control Systems",
                "code": f"ROB_{unique_id[:4]}B",
                "credits": 4,
                "color": "#10B981",
                "semester": 3,
            },
            headers=headers,
        )
        assert sub2_resp.status_code == 201, f"Create sub2 failed: {sub2_resp.text}"
        sub2_id = sub2_resp.json()["data"]["id"]
        print(" Subjects created successfully.")

        # 3. Create Imminent Assignment (Due in 6 hours)
        print("\n[Step 3] Creating Urgent Assignment due in 6 hours...")
        now = datetime.now(timezone.utc)
        due_in_6h = (now + timedelta(hours=6)).isoformat()
        asgn_resp = client.post(
            "/api/v1/assignments",
            json={
                "subject_id": sub1_id,
                "title": "Kinematic Arm Inverse Geometry Lab",
                "due_date": due_in_6h,
                "priority": "urgent",
                "status": "in_progress",
                "weight_percentage": 20.0,
            },
            headers=headers,
        )
        assert asgn_resp.status_code == 201, f"Create assignment failed: {asgn_resp.text}"
        asgn_id = asgn_resp.json()["data"]["id"]
        print(f" Urgent assignment created (ID: {asgn_id})")

        # 4. Create Imminent Exam (Scheduled in 24 hours)
        print("\n[Step 4] Creating Upcoming Exam scheduled in 24 hours...")
        exam_in_24h = (now + timedelta(hours=24)).isoformat()
        exam_resp = client.post(
            "/api/v1/exams",
            json={
                "subject_id": sub2_id,
                "title": "Embedded Systems Midterm",
                "exam_type": "midterm",
                "date_time": exam_in_24h,
                "duration_minutes": 120,
                "location": "Stata Center 32-123",
                "weight_percentage": 30.0,
            },
            headers=headers,
        )
        assert exam_resp.status_code == 201, f"Create exam failed: {exam_resp.text}"
        exam_id = exam_resp.json()["data"]["id"]
        print(f" Upcoming exam created (ID: {exam_id})")

        # 5. Create Timetable Slot for Today
        print("\n[Step 5] Creating Timetable Class Slot for Today...")
        day_name = now.strftime("%A").lower()
        slot_resp = client.post(
            "/api/v1/timetable/slots",
            json={
                "subject_id": sub1_id,
                "title": "Robotics Lab Session",
                "day_of_week": day_name,
                "start_time": "14:00",
                "end_time": "16:00",
                "class_type": "lab",
                "location": "Lab 4B",
            },
            headers=headers,
        )
        assert slot_resp.status_code == 201, f"Create slot failed: {slot_resp.text}"
        print(f" Today's class slot created for {day_name.capitalize()}")

        # 6. Log Absent Attendance to trigger attendance warning (<75%)
        print("\n[Step 6] Logging Absent Attendance to drop subject below 75% threshold...")
        att_resp = client.post(
            "/api/v1/timetable/attendance",
            json={
                "subject_id": sub2_id,
                "date": now.strftime("%Y-%m-%d"),
                "status": "absent",
                "notes": "Medical leave",
            },
            headers=headers,
        )
        assert att_resp.status_code == 201, f"Log attendance failed: {att_resp.text}"
        print(" Absent attendance recorded.")

        # 7. Trigger Smart Alert Generator Scanner
        print("\n[Step 7] Triggering POST /api/v1/notifications/generate-alerts...")
        gen_resp = client.post("/api/v1/notifications/generate-alerts", headers=headers)
        assert gen_resp.status_code == 200, f"Generate alerts failed: {gen_resp.text}"
        gen_data = gen_resp.json()["data"]
        new_count = gen_data["new_notifications_count"]
        assert new_count >= 3, f"Expected at least 3 notifications generated, got {new_count}"
        print(f" Smart alert scanner generated {new_count} notifications!")

        # 8. Test GET /api/v1/notifications/unread-count
        print("\n[Step 8] Checking GET /api/v1/notifications/unread-count...")
        unread_resp = client.get("/api/v1/notifications/unread-count", headers=headers)
        assert unread_resp.status_code == 200
        unread_count = unread_resp.json()["data"]["unread_count"]
        assert unread_count == new_count, f"Expected unread count {new_count}, got {unread_count}"
        print(f" Unread count accurately matches: {unread_count}")

        # 9. Test GET /api/v1/notifications with filtering
        print("\n[Step 9] Listing Notifications with filters...")
        list_all = client.get("/api/v1/notifications", headers=headers)
        assert list_all.status_code == 200
        all_items = list_all.json()["data"]["items"]
        assert len(all_items) >= 3

        types_found = {item["type"] for item in all_items}
        print(f" Notification types generated: {types_found}")
        assert "assignment_due" in types_found
        assert "exam_upcoming" in types_found

        # Filter by type=assignment_due
        asgn_filter_resp = client.get("/api/v1/notifications?type=assignment_due", headers=headers)
        assert asgn_filter_resp.status_code == 200
        asgn_items = asgn_filter_resp.json()["data"]["items"]
        assert len(asgn_items) >= 1
        target_notif = asgn_items[0]
        target_notif_id = target_notif["id"]
        print(f" Filtered by type=assignment_due returned {len(asgn_items)} item(s).")

        # 10. Mark single notification as read
        print(f"\n[Step 10] Marking notification {target_notif_id} as read...")
        read_resp = client.patch(f"/api/v1/notifications/{target_notif_id}/read", headers=headers)
        assert read_resp.status_code == 200
        assert read_resp.json()["data"]["is_read"] is True

        unread_resp2 = client.get("/api/v1/notifications/unread-count", headers=headers)
        assert unread_resp2.json()["data"]["unread_count"] == unread_count - 1
        print(f" Single notification read successfully. Remaining unread: {unread_count - 1}")

        # 11. Mark all notifications as read
        print("\n[Step 11] Marking all notifications as read...")
        mark_all_resp = client.post("/api/v1/notifications/mark-all-read", headers=headers)
        assert mark_all_resp.status_code == 200
        assert mark_all_resp.json()["data"]["marked_read_count"] >= 1

        unread_resp3 = client.get("/api/v1/notifications/unread-count", headers=headers)
        assert unread_resp3.json()["data"]["unread_count"] == 0
        print(" All notifications marked as read. Unread count = 0.")

        # 12. Create a custom system notification
        print("\n[Step 12] Creating custom system notification...")
        custom_resp = client.post(
            "/api/v1/notifications",
            json={
                "type": "system",
                "title": "Welcome to Student OS Notifications",
                "message": "Real-time background alerts are now active.",
                "priority": "normal",
                "action_route": "/home",
            },
            headers=headers,
        )
        assert custom_resp.status_code == 201
        custom_id = custom_resp.json()["data"]["id"]
        print(f" Custom notification created (ID: {custom_id})")

        # 13. Delete single notification
        print(f"\n[Step 13] Deleting custom notification {custom_id}...")
        del_resp = client.delete(f"/api/v1/notifications/{custom_id}", headers=headers)
        assert del_resp.status_code == 200
        print(" Single notification deleted successfully.")

        # 14. Clear all read notifications
        print("\n[Step 14] Clearing all read notifications...")
        clear_resp = client.delete("/api/v1/notifications/read", headers=headers)
        assert clear_resp.status_code == 200
        cleared_count = clear_resp.json()["data"]["deleted_count"]
        print(f" Cleared {cleared_count} read notification(s).")

    # Cleanup synchronous pymongo
    sync_client = pymongo.MongoClient(settings.MONGODB_URL)
    db = sync_client[settings.DATABASE_NAME]
    from bson import ObjectId
    db["users"].delete_one({"_id": ObjectId(user_id)})
    db["subjects"].delete_many({"user_id": ObjectId(user_id)})
    db["assignments"].delete_many({"user_id": ObjectId(user_id)})
    db["exams"].delete_many({"user_id": ObjectId(user_id)})
    db["timetable_slots"].delete_many({"user_id": ObjectId(user_id)})
    db["attendance_logs"].delete_many({"user_id": ObjectId(user_id)})
    db["notifications"].delete_many({"user_id": ObjectId(user_id)})
    sync_client.close()

    print("\n Cleaned up test data from MongoDB.")
    print("=" * 50)
    print(" All Phase 9 Notifications & Alerts API Tests PASSED!")
    print("=" * 50)


if __name__ == "__main__":
    run_notifications_e2e_test()

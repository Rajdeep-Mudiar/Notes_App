import uuid
from datetime import datetime, timezone, timedelta
from fastapi.testclient import TestClient
import pymongo
from app.main import app
from app.core.config import settings

client = TestClient(app)


def test_assignments_e2e_flow():
    print("==================================================")
    print("PHASE 5: ACADEMIC PLANNER & ASSIGNMENT TRACKER E2E TEST")
    print("==================================================")

    test_email = f"planner_student_{uuid.uuid4().hex[:6]}@university.edu"
    test_password = "Password123!"

    with client:
        # 1. Register student
        print("\n[Step 1] Registering student...")
        reg_res = client.post("/api/v1/auth/register", json={
            "email": test_email,
            "password": test_password,
            "full_name": "Marcus Aurelius",
            "university": "Oxford University",
            "degree": "B.S. Software Engineering",
            "current_semester": 5
        })
        assert reg_res.status_code == 201
        token = reg_res.json()["data"]["tokens"]["access_token"]
        user_id = reg_res.json()["data"]["user"]["id"]
        headers = {"Authorization": f"Bearer {token}"}
        print(f" Student registered (ID: {user_id})")

        # 2. Create Subject: Operating Systems
        print("\n[Step 2] Creating Subject: Operating Systems...")
        sub_res = client.post("/api/v1/subjects", headers=headers, json={
            "name": "Operating Systems",
            "code": "CS301",
            "credits": 4,
            "color": "#3B82F6",
            "icon": "desktop_windows",
            "semester": 5
        })
        assert sub_res.status_code == 201
        subject_id = sub_res.json()["data"]["id"]
        print(f" Subject created (ID: {subject_id})")

        # 3. Create Assignment 1 (Due in 3 days, Urgent, 25% weight)
        print("\n[Step 3] Creating Urgent Assignment: Kernel Memory Allocator...")
        due_date_1 = (datetime.now(timezone.utc) + timedelta(days=3)).isoformat()
        create_res_1 = client.post("/api/v1/assignments", headers=headers, json={
            "title": "Kernel Memory Allocator Lab",
            "subject_id": subject_id,
            "description": "Implement buddy memory allocation in C with slab allocator.",
            "due_date": due_date_1,
            "priority": "urgent",
            "weight_percentage": 25.0
        })
        assert create_res_1.status_code == 201, f"Error: {create_res_1.text}"
        asgn_1 = create_res_1.json()["data"]
        asgn_1_id = asgn_1["id"]
        assert asgn_1["title"] == "Kernel Memory Allocator Lab"
        assert asgn_1["priority"] == "urgent"
        assert asgn_1["status"] == "pending"
        assert asgn_1["subject_code"] == "CS301"
        assert asgn_1["is_overdue"] is False
        print(f" Assignment 1 created: '{asgn_1['title']}' (Countdown: {asgn_1['countdown_text']})")

        # 4. Create Assignment 2 (Due in 10 days, Medium priority)
        print("\n[Step 4] Creating Assignment 2: CPU Scheduling Report...")
        due_date_2 = (datetime.now(timezone.utc) + timedelta(days=10)).isoformat()
        create_res_2 = client.post("/api/v1/assignments", headers=headers, json={
            "title": "CPU Scheduling Algorithms Benchmark",
            "subject_id": subject_id,
            "description": "Compare Round Robin vs Multi-Level Feedback Queue performance.",
            "due_date": due_date_2,
            "priority": "medium",
            "weight_percentage": 15.0
        })
        assert create_res_2.status_code == 201
        asgn_2 = create_res_2.json()["data"]
        asgn_2_id = asgn_2["id"]
        print(f" Assignment 2 created: '{asgn_2['title']}' (Countdown: {asgn_2['countdown_text']})")

        # 5. Check Subject assignments_count updated to 2
        print("\n[Step 5] Checking Subject assignments_count auto-sync...")
        sub_check = client.get(f"/api/v1/subjects/{subject_id}", headers=headers)
        assert sub_check.status_code == 200
        assert sub_check.json()["data"]["assignments_count"] == 2
        print(" Subject assignments_count correctly updated to 2.")

        # 6. Test GET /api/v1/assignments list & filters
        print("\n[Step 6] Listing assignments with filters...")
        list_res = client.get(f"/api/v1/assignments?subject_id={subject_id}&priority=urgent", headers=headers)
        assert list_res.status_code == 200
        list_data = list_res.json()["data"]
        assert list_data["total"] == 1
        assert list_data["items"][0]["title"] == "Kernel Memory Allocator Lab"
        assert list_data["pending_count"] == 2
        assert list_data["urgent_count"] == 1
        print(" Filtered assignment list & counters verified.")

        # 7. Test Upcoming Assignments Endpoint (for Dashboard & Calendar)
        print("\n[Step 7] Testing GET /api/v1/assignments/upcoming...")
        up_res = client.get("/api/v1/assignments/upcoming?limit=5", headers=headers)
        assert up_res.status_code == 200
        upcoming = up_res.json()["data"]
        assert len(upcoming) == 2
        assert upcoming[0]["id"] == asgn_1_id  # Earlier due date first
        print(f" Retrieved {len(upcoming)} upcoming assignments in chronological order.")

        # 8. Test Summary Metrics Endpoint
        print("\n[Step 8] Testing GET /api/v1/assignments/summary...")
        summary_res = client.get("/api/v1/assignments/summary", headers=headers)
        assert summary_res.status_code == 200
        summary = summary_res.json()["data"]
        assert summary["total_assignments"] == 2
        assert summary["pending_count"] == 2
        assert summary["due_this_week_count"] == 1  # Only assignment 1 is within 7 days
        assert summary["overdue_count"] == 0
        print(f" Summary metrics: Total={summary['total_assignments']}, DueThisWeek={summary['due_this_week_count']}")

        # 9. Update Status (Workflow transition: pending -> in_progress -> submitted)
        print("\n[Step 9] Transitioning assignment status...")
        stat_res = client.patch(f"/api/v1/assignments/{asgn_1_id}/status", headers=headers, json={"status": "in_progress"})
        assert stat_res.status_code == 200
        assert stat_res.json()["data"]["status"] == "in_progress"

        stat_res2 = client.patch(f"/api/v1/assignments/{asgn_1_id}/status", headers=headers, json={"status": "submitted"})
        assert stat_res2.status_code == 200
        assert stat_res2.json()["data"]["status"] == "submitted"
        assert stat_res2.json()["data"]["countdown_text"] == "Completed"
        print(" Status transitions verified successfully.")

        # 10. Update Assignment (Grading & Feedback)
        print("\n[Step 10] Updating assignment details with Grade and Feedback...")
        upd_res = client.put(f"/api/v1/assignments/{asgn_1_id}", headers=headers, json={
            "status": "graded",
            "grade_received": 96.5,
            "feedback": "Outstanding implementation of slab caching with zero memory leaks."
        })
        assert upd_res.status_code == 200
        asgn_1_updated = upd_res.json()["data"]
        assert asgn_1_updated["status"] == "graded"
        assert asgn_1_updated["grade_received"] == 96.5
        assert asgn_1_updated["feedback"] == "Outstanding implementation of slab caching with zero memory leaks."
        print(f" Assignment graded: {asgn_1_updated['grade_received']}%")

        # 11. Delete Assignment 2
        print("\n[Step 11] Deleting assignment 2...")
        del_res = client.delete(f"/api/v1/assignments/{asgn_2_id}", headers=headers)
        assert del_res.status_code == 200
        print(" Assignment 2 deleted.")

        # 12. Verify Subject assignments_count decremented to 1
        sub_check2 = client.get(f"/api/v1/subjects/{subject_id}", headers=headers)
        assert sub_check2.json()["data"]["assignments_count"] == 1
        print(" Subject assignments_count correctly decremented to 1.")

    # Cleanup Database
    sync_client = pymongo.MongoClient(settings.MONGODB_URL)
    sync_db = sync_client[settings.DATABASE_NAME]
    sync_db["users"].delete_one({"email": test_email})
    sync_db["subjects"].delete_many({"user_id": user_id})
    sync_db["assignments"].delete_many({"user_id": user_id})
    sync_client.close()
    print("\n Cleaned up test data from MongoDB.")

    print("\n All Phase 5 Academic Planner & Assignment Tracker API Tests PASSED!")
    print("==================================================")


if __name__ == "__main__":
    test_assignments_e2e_flow()

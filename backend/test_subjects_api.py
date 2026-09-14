import uuid
from fastapi.testclient import TestClient
import pymongo
from app.main import app
from app.core.config import settings

client = TestClient(app)


def test_subjects_e2e_flow():
    print("==================================================")
    print("PHASE 2: SUBJECTS MANAGEMENT & ACADEMIC HIERARCHY")
    print("==================================================")

    test_email = f"subject_student_{uuid.uuid4().hex[:6]}@university.edu"
    test_password = "Password123!"

    with client:
        # 1. Register student
        print("\n[Step 1] Registering student...")
        reg_res = client.post("/api/v1/auth/register", json={
            "email": test_email,
            "password": test_password,
            "full_name": "Maya Chen",
            "university": "MIT",
            "degree": "B.S. Computer Science",
            "current_semester": 4
        })
        assert reg_res.status_code == 201
        token = reg_res.json()["data"]["tokens"]["access_token"]
        user_id = reg_res.json()["data"]["user"]["id"]
        headers = {"Authorization": f"Bearer {token}"}
        print(f" Student registered (ID: {user_id})")

        # 2. Create Subject 1: Data Structures
        print("\n[Step 2] Creating Subject: Data Structures (CS204)...")
        sub1_res = client.post("/api/v1/subjects", headers=headers, json={
            "name": "Data Structures & Algorithms",
            "code": "CS204",
            "professor": "Dr. Alan Turing",
            "credits": 4,
            "color": "#4F46E5",
            "icon": "code",
            "description": "Trees, Graphs, Dynamic Programming & Complexity Analysis",
            "semester": 4
        })
        assert sub1_res.status_code == 201, f"Error: {sub1_res.text}"
        sub1 = sub1_res.json()["data"]
        sub1_id = sub1["id"]
        print(f" Created Subject: {sub1['name']} [{sub1['code']}], Credits: {sub1['credits']}")

        # 3. Create Subject 2: Operating Systems
        print("\n[Step 3] Creating Subject: Operating Systems (CS205)...")
        sub2_res = client.post("/api/v1/subjects", headers=headers, json={
            "name": "Operating Systems",
            "code": "CS205",
            "professor": "Dr. Linus",
            "credits": 4,
            "color": "#0EA5E9",
            "icon": "memory",
            "description": "Processes, Threads, Virtual Memory & Concurrency",
            "semester": 4
        })
        assert sub2_res.status_code == 201
        sub2_id = sub2_res.json()["data"]["id"]
        print(" Created Subject 2: Operating Systems")

        # 4. Create Subject 3: DBMS
        print("\n[Step 4] Creating Subject: Database Management Systems (CS206)...")
        sub3_res = client.post("/api/v1/subjects", headers=headers, json={
            "name": "Database Management Systems",
            "code": "CS206",
            "professor": "Prof. Codd",
            "credits": 3,
            "color": "#10B981",
            "icon": "storage",
            "description": "Relational Algebra, SQL, Normalization & ACID Transactions",
            "semester": 4
        })
        assert sub3_res.status_code == 201
        print(" Created Subject 3: DBMS")

        # 5. Prevent Duplicate Subject Code in same semester
        print("\n[Step 5] Testing duplicate course code collision...")
        dup_res = client.post("/api/v1/subjects", headers=headers, json={
            "name": "Another DSA Course",
            "code": "CS204",
            "professor": "Dr. Duplicate",
            "credits": 4,
            "semester": 4
        })
        assert dup_res.status_code == 400
        print(f" Correctly rejected duplicate course code: {dup_res.json()['message']}")

        # 6. List subjects filtered by semester
        print("\n[Step 6] Listing subjects for Semester 4...")
        list_res = client.get("/api/v1/subjects?semester=4", headers=headers)
        assert list_res.status_code == 200
        subjects_list = list_res.json()["data"]["subjects"]
        assert len(subjects_list) == 3
        print(f" Listed {len(subjects_list)} subjects for Semester 4.")

        # 7. Get Academic Summary
        print("\n[Step 7] Checking Academic Summary & Credits Calculation...")
        summary_res = client.get("/api/v1/subjects/summary", headers=headers)
        assert summary_res.status_code == 200
        summary = summary_res.json()["data"]
        assert summary["total_subjects"] == 3
        assert summary["total_credits"] == 11  # 4 + 4 + 3 = 11
        assert summary["semester_credits"] == 11
        print(f" Academic summary: {summary['total_subjects']} active subjects, {summary['total_credits']} total credits enrolled.")

        # 8. Update Subject
        print("\n[Step 8] Updating Subject Details (Credits 4 -> 5)...")
        upd_res = client.put(f"/api/v1/subjects/{sub1_id}", headers=headers, json={
            "credits": 5,
            "professor": "Dr. Donald Knuth"
        })
        assert upd_res.status_code == 200
        assert upd_res.json()["data"]["credits"] == 5
        assert upd_res.json()["data"]["professor"] == "Dr. Donald Knuth"
        print(" Subject updated successfully.")

        # 9. Toggle Archive
        print("\n[Step 9] Archiving Subject (Operating Systems)...")
        arc_res = client.patch(f"/api/v1/subjects/{sub2_id}/archive", headers=headers)
        assert arc_res.status_code == 200
        assert arc_res.json()["data"]["is_archived"] is True
        print(" Subject archived.")

        # 10. Check list excluding archived
        list_active_res = client.get("/api/v1/subjects", headers=headers)
        assert len(list_active_res.json()["data"]["subjects"]) == 2

        # 11. Delete Subject
        print("\n[Step 10] Deleting Subject 3 (DBMS)...")
        del_res = client.delete(f"/api/v1/subjects/{sub1_id}", headers=headers)
        assert del_res.status_code == 200
        print(" Subject deleted successfully.")

    # Cleanup Database
    sync_client = pymongo.MongoClient(settings.MONGODB_URL)
    sync_db = sync_client[settings.DATABASE_NAME]
    sync_db["users"].delete_one({"email": test_email})
    sync_db["subjects"].delete_many({"user_id": user_id})
    sync_client.close()
    print("\n Cleaned up test data from MongoDB.")

    print("\n All Phase 2 Backend Subject Management Tests PASSED!")
    print("==================================================")


if __name__ == "__main__":
    test_subjects_e2e_flow()

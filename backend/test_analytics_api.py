import uuid
from fastapi.testclient import TestClient
import pymongo

from app.main import app
from app.core.config import settings


def run_analytics_tests():
    print("=" * 50)
    print("PHASE 8: GPA & ACADEMIC PERFORMANCE ANALYTICS E2E TEST")
    print("=" * 50)

    unique_id = uuid.uuid4().hex[:8]
    test_email = f"student_gpa_{unique_id}@stanford.edu"
    test_password = "SecurePassword123!"

    with TestClient(app) as client:
        # Step 1: Register User
        print("\n[Step 1] Registering student...")
        reg_res = client.post(
            "/api/v1/auth/register",
            json={
                "email": test_email,
                "password": test_password,
                "full_name": "Grace Hopper",
                "university": "Yale University",
                "degree": "B.S. Mathematics & Physics",
                "current_semester": 2,
            },
        )
        assert reg_res.status_code == 201, f"Registration failed: {reg_res.text}"
        auth_data = reg_res.json()["data"]
        token = auth_data["tokens"]["access_token"]
        user_id = auth_data["user"]["id"]
        headers = {"Authorization": f"Bearer {token}"}
        print(f" Student registered (ID: {user_id})")

        # Step 2: Create Semester 1 Subjects
        print("\n[Step 2] Creating Semester 1 Subjects (11 Credits Total)...")
        sub1_res = client.post(
            "/api/v1/subjects",
            headers=headers,
            json={
                "name": "Introduction to Computer Science",
                "code": "CS101",
                "credits": 4,
                "color": "#4F46E5",
                "semester": 1,
            },
        )
        assert sub1_res.status_code == 201
        sub1_id = sub1_res.json()["data"]["id"]

        sub2_res = client.post(
            "/api/v1/subjects",
            headers=headers,
            json={
                "name": "Discrete Mathematics",
                "code": "CS102",
                "credits": 3,
                "color": "#10B981",
                "semester": 1,
            },
        )
        assert sub2_res.status_code == 201
        sub2_id = sub2_res.json()["data"]["id"]

        sub3_res = client.post(
            "/api/v1/subjects",
            headers=headers,
            json={
                "name": "Calculus & Linear Algebra",
                "code": "MATH101",
                "credits": 4,
                "color": "#F59E0B",
                "semester": 1,
            },
        )
        assert sub3_res.status_code == 201
        sub3_id = sub3_res.json()["data"]["id"]
        print(f" Semester 1 courses created: CS101 (4cr), CS102 (3cr), MATH101 (4cr)")

        # Step 3: Create Semester 2 Subjects
        print("\n[Step 3] Creating Semester 2 Subjects (8 Credits Total)...")
        sub4_res = client.post(
            "/api/v1/subjects",
            headers=headers,
            json={
                "name": "Data Structures & Algorithms",
                "code": "CS201",
                "credits": 4,
                "color": "#3B82F6",
                "semester": 2,
            },
        )
        assert sub4_res.status_code == 201
        sub4_id = sub4_res.json()["data"]["id"]

        sub5_res = client.post(
            "/api/v1/subjects",
            headers=headers,
            json={
                "name": "Computer Systems & Hardware",
                "code": "CS202",
                "credits": 4,
                "color": "#8B5CF6",
                "semester": 2,
            },
        )
        assert sub5_res.status_code == 201
        sub5_id = sub5_res.json()["data"]["id"]
        print(f" Semester 2 courses created: CS201 (4cr), CS202 (4cr)")

        # Step 4: Record Grades for Semester 1
        print("\n[Step 4] Recording Grades for Semester 1 (A, A-, B+)...")
        # CS101: A (4.0)
        g1_res = client.put(
            f"/api/v1/analytics/subjects/{sub1_id}/grade",
            headers=headers,
            json={"letter_grade": "A", "target_grade": "A"},
        )
        assert g1_res.status_code == 200
        assert g1_res.json()["data"]["grade_point"] == 4.0

        # CS102: A- (3.7)
        g2_res = client.put(
            f"/api/v1/analytics/subjects/{sub2_id}/grade",
            headers=headers,
            json={"letter_grade": "A-", "target_grade": "A"},
        )
        assert g2_res.status_code == 200
        assert g2_res.json()["data"]["grade_point"] == 3.7

        # MATH101: B+ (3.3)
        g3_res = client.put(
            f"/api/v1/analytics/subjects/{sub3_id}/grade",
            headers=headers,
            json={"letter_grade": "B+", "target_grade": "A-"},
        )
        assert g3_res.status_code == 200
        assert g3_res.json()["data"]["grade_point"] == 3.3
        print(" Semester 1 grades recorded successfully.")

        # Step 5: Record Grades for Semester 2
        print("\n[Step 5] Recording Grades for Semester 2 (A, A)...")
        # CS201: A (4.0)
        g4_res = client.put(
            f"/api/v1/analytics/subjects/{sub4_id}/grade",
            headers=headers,
            json={"letter_grade": "A"},
        )
        assert g4_res.status_code == 200
        assert g4_res.json()["data"]["grade_point"] == 4.0

        # CS202: A (4.0)
        g5_res = client.put(
            f"/api/v1/analytics/subjects/{sub5_id}/grade",
            headers=headers,
            json={"letter_grade": "A"},
        )
        assert g5_res.status_code == 200
        assert g5_res.json()["data"]["grade_point"] == 4.0
        print(" Semester 2 grades recorded successfully.")

        # Step 6: Test GET /api/v1/analytics/gpa/summary
        print("\n[Step 6] Testing GET /api/v1/analytics/gpa/summary...")
        summary_res = client.get("/api/v1/analytics/gpa/summary", headers=headers)
        assert summary_res.status_code == 200
        summary = summary_res.json()["data"]

        # Expected:
        # Sem 1: (4*4.0 + 3*3.7 + 4*3.3) / 11 = (16.0 + 11.1 + 13.2) / 11 = 40.3 / 11 = 3.66
        # Sem 2: (4*4.0 + 4*4.0) / 8 = 32.0 / 8 = 4.00
        # Overall CGPA: (40.3 + 32.0) / 19 = 72.3 / 19 = 3.81
        assert summary["current_cgpa"] == 3.81
        assert summary["total_earned_credits"] == 19
        assert summary["total_enrolled_credits"] == 19
        assert summary["highest_sgpa_semester"] == 2
        assert summary["lowest_sgpa_semester"] == 1
        assert "Magna Cum Laude" in summary["honors_standing"]
        assert summary["academic_status"] == "Good Standing"
        assert len(summary["semester_breakdown"]) == 2
        print(f" Summary verified: CGPA = {summary['current_cgpa']} | Honors = '{summary['honors_standing']}' | Total Earned = {summary['total_earned_credits']} cr")

        # Step 7: Test GET /api/v1/analytics/gpa/semesters
        print("\n[Step 7] Testing GET /api/v1/analytics/gpa/semesters...")
        semesters_res = client.get("/api/v1/analytics/gpa/semesters", headers=headers)
        assert semesters_res.status_code == 200
        sem_list = semesters_res.json()["data"]
        assert len(sem_list) == 2
        assert sem_list[0]["sgpa"] == 3.66
        assert sem_list[1]["sgpa"] == 4.00
        print(f" Semester breakdown verified: Sem 1 SGPA = {sem_list[0]['sgpa']}, Sem 2 SGPA = {sem_list[1]['sgpa']}")

        # Step 8: Test "What-If" Predictive Scenario Simulator
        print("\n[Step 8] Testing POST /api/v1/analytics/gpa/what-if...")
        whatif_res = client.post(
            "/api/v1/analytics/gpa/what-if",
            headers=headers,
            json={
                "courses": [
                    {"course_name": "Operating Systems (CS301)", "credits": 4, "hypothetical_grade": "A"},
                    {"course_name": "Compilers (CS302)", "credits": 4, "hypothetical_grade": "A"},
                ],
                "target_cgpa": 3.85,
            },
        )
        assert whatif_res.status_code == 200
        whatif_data = whatif_res.json()["data"]
        # Baseline: 19 creds, 72.3 pts
        # Added: 8 creds @ 4.0 = 32.0 pts
        # Projected: (72.3 + 32.0) / 27 = 104.3 / 27 = 3.86
        assert whatif_data["baseline_cgpa"] == 3.81
        assert whatif_data["projected_cgpa"] == 3.87
        assert whatif_data["cgpa_difference"] == 0.06
        assert whatif_data["total_projected_credits"] == 27
        assert whatif_data["target_achieved"] is True
        print(f" What-If projection verified: {whatif_data['projection_message']}")

    # Cleanup Database
    sync_client = pymongo.MongoClient(settings.MONGODB_URL)
    sync_db = sync_client[settings.DATABASE_NAME]
    sync_db["users"].delete_one({"email": test_email})
    sync_db["subjects"].delete_many({"user_id": pymongo.collection.ObjectId(user_id)})
    sync_client.close()
    print("\n Cleaned up test data from MongoDB.")

    print("\n" + "=" * 50)
    print(" All Phase 8 GPA & Academic Performance Analytics API Tests PASSED!")
    print("=" * 50)


if __name__ == "__main__":
    run_analytics_tests()

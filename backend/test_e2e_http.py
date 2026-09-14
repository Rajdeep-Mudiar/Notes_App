from fastapi.testclient import TestClient
import pymongo
from app.main import app
from app.core.config import settings

client = TestClient(app)


def test_full_http_flow():
    print("==================================================")
    print("FASTAPI REST API: FULL E2E HTTP INTEGRATION TEST")
    print("==================================================")

    with client:
        # 1. Test Health Endpoint
        print("\n[HTTP 1] GET /api/v1/health")
        res = client.get("/api/v1/health")
        assert res.status_code == 200, f"Expected 200, got {res.status_code}: {res.text}"
        data = res.json()
        print(f" Response: {data['message']}")
        assert data["success"] is True
        assert data["data"]["mongodb"] == "connected"

        # 2. Test Registration
        print("\n[HTTP 2] POST /api/v1/auth/register")
        test_email = "e2e_student@stanford.edu"
        reg_payload = {
            "email": test_email,
            "password": "Password123!",
            "full_name": "Jordan Lee",
            "university": "Stanford University",
            "degree": "B.S. Artificial Intelligence",
            "current_semester": 3
        }
        res = client.post("/api/v1/auth/register", json=reg_payload)
        assert res.status_code == 201, f"Expected 201, got {res.status_code}: {res.text}"
        reg_json = res.json()
        assert reg_json["success"] is True
        access_token = reg_json["data"]["tokens"]["access_token"]
        refresh_token = reg_json["data"]["tokens"]["refresh_token"]
        user_id = reg_json["data"]["user"]["id"]
        print(f" Registered student: {reg_json['data']['user']['full_name']} (ID: {user_id})")

        # 3. Test Profile with Bearer Token
        print("\n[HTTP 3] GET /api/v1/users/me (with Bearer JWT)")
        headers = {"Authorization": f"Bearer {access_token}"}
        res = client.get("/api/v1/users/me", headers=headers)
        assert res.status_code == 200, f"Expected 200, got {res.status_code}: {res.text}"
        me_json = res.json()
        assert me_json["data"]["email"] == test_email
        print(f" Retrieved authenticated profile: {me_json['data']['full_name']} - {me_json['data']['degree']}")

        # 4. Test Login
        print("\n[HTTP 4] POST /api/v1/auth/login")
        login_payload = {
            "email": test_email,
            "password": "Password123!"
        }
        res = client.post("/api/v1/auth/login", json=login_payload)
        assert res.status_code == 200, f"Expected 200, got {res.status_code}: {res.text}"
        login_json = res.json()
        assert login_json["success"] is True
        print(f" Logged in successfully. Token type: {login_json['data']['tokens']['token_type']}")

        # 5. Test Refresh Token
        print("\n[HTTP 5] POST /api/v1/auth/refresh")
        refresh_payload = {"refresh_token": refresh_token}
        res = client.post("/api/v1/auth/refresh", json=refresh_payload)
        assert res.status_code == 200, f"Expected 200, got {res.status_code}: {res.text}"
        ref_json = res.json()
        assert ref_json["data"]["access_token"] is not None
        print(" Token refreshed successfully over HTTP.")

    # Synchronous cleanup using PyMongo
    sync_client = pymongo.MongoClient(settings.MONGODB_URL)
    sync_db = sync_client[settings.DATABASE_NAME]
    sync_db["users"].delete_one({"email": test_email})
    sync_client.close()
    print("\n Cleaned up test record from MongoDB.")

    print("\n All REST Endpoints & Authentication flows PASSED with 100% success!")
    print("==================================================")


if __name__ == "__main__":
    test_full_http_flow()

import asyncio
import uuid
import sys
from app.core.database import connect_to_mongo, close_mongo_connection, get_database
from app.repositories.user_repository import UserRepository
from app.services.auth_service import AuthService
from app.schemas.user import UserCreate, UserLogin
from app.schemas.auth import RefreshTokenRequest


async def run_verification():
    print("==================================================")
    print("STUDENT OS BACKEND: LIVE MONGODB & AUTH VERIFICATION")
    print("==================================================")

    # 1. Connect to MongoDB
    print("\n[Step 1] Connecting to MongoDB...")
    await connect_to_mongo()
    db = get_database()
    user_repo = UserRepository(db)
    auth_service = AuthService(user_repo)
    print(" Connected to MongoDB successfully.")

    # 2. Test Registration
    test_email = f"student_{uuid.uuid4().hex[:6]}@university.edu"
    test_password = "SecurePassword123!"
    user_in = UserCreate(
        email=test_email,
        password=test_password,
        full_name="Alex Rivera",
        university="Stanford University",
        degree="B.S. Computer Science",
        current_semester=4
    )

    print(f"\n[Step 2] Testing User Registration ({test_email})...")
    auth_data = await auth_service.register_user(user_in)
    assert auth_data.user.email == test_email
    assert auth_data.user.full_name == "Alex Rivera"
    assert auth_data.user.current_semester == 4
    assert auth_data.tokens.access_token is not None
    assert auth_data.tokens.refresh_token is not None
    print(f" Registration passed! Generated user ID: {auth_data.user.id}")
    print(f" Access Token prefix: {auth_data.tokens.access_token[:20]}...")

    # 3. Test Login
    print("\n[Step 3] Testing User Login with valid credentials...")
    login_in = UserLogin(email=test_email, password=test_password)
    login_res = await auth_service.login_user(login_in)
    assert login_res.user.id == auth_data.user.id
    print(" Login successful.")

    # 4. Test Invalid Password rejection
    print("\n[Step 4] Testing Login with invalid credentials...")
    try:
        await auth_service.login_user(UserLogin(email=test_email, password="WrongPassword!"))
        print(" FAILED: Expected HTTPException for invalid password.")
        sys.exit(1)
    except Exception as e:
        print(f" Correctly rejected invalid credentials: {e.detail}")

    # 5. Test Fetching Profile
    print("\n[Step 5] Testing Profile Retrieval by User ID...")
    profile = await auth_service.get_current_user_profile(auth_data.user.id)
    assert profile.email == test_email
    assert profile.university == "Stanford University"
    print(f" Profile retrieved: {profile.full_name}, {profile.degree} (Semester {profile.current_semester})")

    # 6. Test Token Refresh
    print("\n[Step 6] Testing Token Refresh...")
    new_tokens = await auth_service.refresh_tokens(login_res.tokens.refresh_token)
    assert new_tokens.access_token is not None
    assert new_tokens.refresh_token is not None
    print(" Token refresh passed.")

    # Clean up test user
    print("\n[Step 7] Cleaning up test user...")
    await user_repo.collection.delete_one({"email": test_email})
    print(" Test user cleaned up from MongoDB.")

    # Shutdown connection
    await close_mongo_connection()
    print("\n All Backend & MongoDB tests PASSED with 100% success!")
    print("==================================================")


if __name__ == "__main__":
    asyncio.run(run_verification())

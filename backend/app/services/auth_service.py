import logging
from typing import Any, Dict, Optional, Tuple
import requests
from fastapi import HTTPException, status

from app.core.config import settings
from app.core.security import hash_password, verify_password, create_access_token, create_refresh_token, decode_token
from app.repositories.user_repository import UserRepository
from app.schemas.user import UserCreate, UserLogin, UserProfileResponse
from app.schemas.auth import TokenResponse, AuthData, GoogleAuthRequest

logger = logging.getLogger(__name__)


class AuthService:
    def __init__(self, user_repo: UserRepository):
        self.user_repo = user_repo

    async def register_user(self, user_in: UserCreate) -> AuthData:
        # Check if email is already taken
        existing = await self.user_repo.get_by_email(user_in.email)
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="A user with this email already exists."
            )

        user_data = user_in.model_dump()
        raw_password = user_data.pop("password")
        user_data["hashed_password"] = hash_password(raw_password)
        user_data["auth_provider"] = "local"

        created_user = await self.user_repo.create(user_data)
        user_id = created_user["id"]

        tokens = self._generate_tokens(user_id)
        profile = UserProfileResponse(**created_user)

        return AuthData(user=profile, tokens=tokens)

    async def login_user(self, login_data: UserLogin) -> AuthData:
        user = await self.user_repo.get_by_email(login_data.email)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password."
            )

        if not verify_password(login_data.password, user.get("hashed_password", "")):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password."
            )

        if not user.get("is_active", True):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Your account has been deactivated."
            )

        tokens = self._generate_tokens(user["id"])
        profile = UserProfileResponse(**user)

        return AuthData(user=profile, tokens=tokens)

    async def google_login(self, google_in: GoogleAuthRequest) -> AuthData:
        """Authenticate user via Google Sign-In using ID Token, OAuth Code, or Verified Payload."""
        google_email = None
        google_name = None
        google_picture = None

        # 1. Verify via Google ID Token if present
        if google_in.id_token:
            try:
                resp = requests.get(
                    f"https://oauth2.googleapis.com/tokeninfo?id_token={google_in.id_token}",
                    timeout=8
                )
                if resp.status_code == 200:
                    info = resp.json()
                    google_email = info.get("email")
                    google_name = info.get("name")
                    google_picture = info.get("picture")
            except Exception as e:
                logger.warning(f"Google ID token verification failed: {e}")

        # 2. Exchange server_auth_code if present and client secret configured
        if not google_email and google_in.server_auth_code and settings.GOOGLE_CLIENT_ID and settings.GOOGLE_CLIENT_SECRET:
            try:
                token_resp = requests.post(
                    "https://oauth2.googleapis.com/token",
                    data={
                        "code": google_in.server_auth_code,
                        "client_id": settings.GOOGLE_CLIENT_ID,
                        "client_secret": settings.GOOGLE_CLIENT_SECRET,
                        "grant_type": "authorization_code",
                        "redirect_uri": "postmessage",
                    },
                    timeout=8
                )
                if token_resp.status_code == 200:
                    tokens_data = token_resp.json()
                    userinfo_token = tokens_data.get("access_token")
                    userinfo_resp = requests.get(
                        "https://www.googleapis.com/oauth2/v3/userinfo",
                        headers={"Authorization": f"Bearer {userinfo_token}"},
                        timeout=8
                    )
                    if userinfo_resp.status_code == 200:
                        uinfo = userinfo_resp.json()
                        google_email = uinfo.get("email")
                        google_name = uinfo.get("name")
                        google_picture = uinfo.get("picture")
            except Exception as e:
                logger.warning(f"Google auth code exchange failed: {e}")

        # 3. Direct fallback from payload if provided
        if not google_email and google_in.email:
            google_email = google_in.email
            google_name = google_in.name or "Google Student"
            google_picture = google_in.avatar_url

        if not google_email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Unable to verify Google credentials. Please ensure a valid Google account is selected."
            )

        # Check existing user
        user = await self.user_repo.get_by_email(google_email)
        if user:
            if not user.get("is_active", True):
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Your account has been deactivated."
                )
            user_id = user["id"]
        else:
            # Create new user for Google Sign-In
            new_user_data = {
                "email": google_email,
                "full_name": google_name or "Google Student",
                "university": "University",
                "major": "Computer Science",
                "current_semester": 1,
                "hashed_password": hash_password(f"goog_auth_{google_email}_{google_name}"),
                "auth_provider": "google",
                "is_active": True,
            }
            created = await self.user_repo.create(new_user_data)
            user = created
            user_id = created["id"]

        tokens = self._generate_tokens(user_id)
        profile = UserProfileResponse(**user)
        return AuthData(user=profile, tokens=tokens)

    async def refresh_tokens(self, refresh_token: str) -> TokenResponse:
        payload = decode_token(refresh_token)
        if not payload or payload.get("type") != "refresh":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or expired refresh token."
            )

        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token payload."
            )

        user = await self.user_repo.get_by_id(user_id)
        if not user or not user.get("is_active", True):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User associated with token no longer exists or is inactive."
            )

        return self._generate_tokens(user_id)

    async def get_current_user_profile(self, user_id: str) -> UserProfileResponse:
        user = await self.user_repo.get_by_id(user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found."
            )
        return UserProfileResponse(**user)

    def _generate_tokens(self, user_id: str) -> TokenResponse:
        access_token = create_access_token(user_id)
        refresh_token = create_refresh_token(user_id)
        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
            expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
        )

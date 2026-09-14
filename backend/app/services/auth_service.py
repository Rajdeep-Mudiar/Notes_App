from typing import Any, Dict, Tuple
from fastapi import HTTPException, status
from app.core.config import settings
from app.core.security import hash_password, verify_password, create_access_token, create_refresh_token, decode_token
from app.repositories.user_repository import UserRepository
from app.schemas.user import UserCreate, UserLogin, UserProfileResponse
from app.schemas.auth import TokenResponse, AuthData


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

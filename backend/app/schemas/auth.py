from typing import Optional
from pydantic import BaseModel, Field, EmailStr
from app.schemas.user import UserProfileResponse


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int


class RefreshTokenRequest(BaseModel):
    refresh_token: str = Field(..., min_length=1)


class GoogleAuthRequest(BaseModel):
    id_token: Optional[str] = None
    server_auth_code: Optional[str] = None
    access_token: Optional[str] = None
    email: Optional[EmailStr] = None
    name: Optional[str] = None
    avatar_url: Optional[str] = None


class AuthData(BaseModel):
    user: UserProfileResponse
    tokens: TokenResponse

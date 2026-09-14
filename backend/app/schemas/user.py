from datetime import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr, Field


class UserBase(BaseModel):
    email: EmailStr
    full_name: str = Field(..., min_length=2, max_length=100)
    university: Optional[str] = Field(default="My University", max_length=150)
    degree: Optional[str] = Field(default="Computer Science", max_length=150)
    current_semester: Optional[int] = Field(default=1, ge=1, le=16)
    avatar_url: Optional[str] = None


class UserCreate(UserBase):
    password: str = Field(..., min_length=6, max_length=100)


class UserLogin(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=1)


class UserUpdate(BaseModel):
    full_name: Optional[str] = Field(None, min_length=2, max_length=100)
    university: Optional[str] = Field(None, max_length=150)
    degree: Optional[str] = Field(None, max_length=150)
    current_semester: Optional[int] = Field(None, ge=1, le=16)
    avatar_url: Optional[str] = None


class UserProfileResponse(UserBase):
    id: str
    is_active: bool = True
    created_at: datetime
    updated_at: datetime


class UserInDB(UserBase):
    id: str
    hashed_password: str
    is_active: bool = True
    created_at: datetime
    updated_at: datetime

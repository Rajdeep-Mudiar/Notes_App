from fastapi import APIRouter, Depends, status
from app.api.deps import get_auth_service
from app.services.auth_service import AuthService
from app.schemas.user import UserCreate, UserLogin
from app.schemas.auth import AuthData, TokenResponse, RefreshTokenRequest
from app.schemas.response import ApiResponse

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=ApiResponse[AuthData], status_code=status.HTTP_201_CREATED)
async def register(
    user_in: UserCreate,
    auth_service: AuthService = Depends(get_auth_service)
):
    """Register a new student user and return profile with tokens."""
    data = await auth_service.register_user(user_in)
    return ApiResponse(
        success=True,
        message="Student registered successfully.",
        data=data
    )


@router.post("/login", response_model=ApiResponse[AuthData])
async def login(
    login_data: UserLogin,
    auth_service: AuthService = Depends(get_auth_service)
):
    """Authenticate student with email and password."""
    data = await auth_service.login_user(login_data)
    return ApiResponse(
        success=True,
        message="Logged in successfully.",
        data=data
    )


@router.post("/refresh", response_model=ApiResponse[TokenResponse])
async def refresh_token(
    refresh_in: RefreshTokenRequest,
    auth_service: AuthService = Depends(get_auth_service)
):
    """Issue a new access token using a valid refresh token."""
    tokens = await auth_service.refresh_tokens(refresh_in.refresh_token)
    return ApiResponse(
        success=True,
        message="Token refreshed successfully.",
        data=tokens
    )


@router.post("/logout", response_model=ApiResponse[None])
async def logout():
    """Client-side token disposal endpoint."""
    return ApiResponse(
        success=True,
        message="Logged out successfully."
    )

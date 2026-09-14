from fastapi import APIRouter, Depends
from app.api.deps import get_current_user, get_user_repository
from app.repositories.user_repository import UserRepository
from app.schemas.user import UserProfileResponse, UserUpdate
from app.schemas.response import ApiResponse

router = APIRouter(prefix="/users", tags=["Users"])


@router.get("/me", response_model=ApiResponse[UserProfileResponse])
async def get_me(current_user: UserProfileResponse = Depends(get_current_user)):
    """Get profile of currently logged-in student."""
    return ApiResponse(
        success=True,
        message="Profile retrieved successfully.",
        data=current_user
    )


@router.put("/me", response_model=ApiResponse[UserProfileResponse])
async def update_me(
    user_update: UserUpdate,
    current_user: UserProfileResponse = Depends(get_current_user),
    user_repo: UserRepository = Depends(get_user_repository)
):
    """Update profile information for the currently logged-in student."""
    update_data = {k: v for k, v in user_update.model_dump().items() if v is not None}
    if update_data:
        updated = await user_repo.update(current_user.id, update_data)
        if updated:
            return ApiResponse(
                success=True,
                message="Profile updated successfully.",
                data=UserProfileResponse(**updated)
            )
    
    return ApiResponse(
        success=True,
        message="Profile unchanged.",
        data=current_user
    )

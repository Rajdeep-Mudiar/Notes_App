from typing import Optional
from fastapi import APIRouter, Depends, Query, status
from app.api.deps import get_current_user, get_subject_service
from app.services.subject_service import SubjectService
from app.schemas.user import UserProfileResponse
from app.schemas.subject import (
    SubjectCreate,
    SubjectUpdate,
    SubjectResponse,
    SubjectListResponse,
    AcademicSummaryResponse
)
from app.schemas.response import ApiResponse

router = APIRouter(prefix="/subjects", tags=["Subjects"])


@router.post("", response_model=ApiResponse[SubjectResponse], status_code=status.HTTP_201_CREATED)
async def create_subject(
    subject_in: SubjectCreate,
    current_user: UserProfileResponse = Depends(get_current_user),
    subject_service: SubjectService = Depends(get_subject_service)
):
    """Create a new academic subject for the student."""
    subject = await subject_service.create_subject(current_user.id, subject_in)
    return ApiResponse(
        success=True,
        message=f"Subject '{subject.name}' created successfully.",
        data=subject
    )


@router.get("", response_model=ApiResponse[SubjectListResponse])
async def get_subjects(
    semester: Optional[int] = Query(None, ge=1, le=16, description="Filter subjects by semester"),
    include_archived: bool = Query(False, description="Include archived subjects"),
    current_user: UserProfileResponse = Depends(get_current_user),
    subject_service: SubjectService = Depends(get_subject_service)
):
    """Retrieve list of subjects for the authenticated student."""
    result = await subject_service.get_subjects(
        user_id=current_user.id,
        semester=semester,
        include_archived=include_archived
    )
    return ApiResponse(
        success=True,
        message="Subjects retrieved successfully.",
        data=result
    )


@router.get("/summary", response_model=ApiResponse[AcademicSummaryResponse])
async def get_academic_summary(
    current_user: UserProfileResponse = Depends(get_current_user),
    subject_service: SubjectService = Depends(get_subject_service)
):
    """Retrieve total credits, active subjects count, and semester breakdown."""
    summary = await subject_service.get_academic_summary(current_user.id)
    return ApiResponse(
        success=True,
        message="Academic summary retrieved successfully.",
        data=summary
    )


@router.get("/{subject_id}", response_model=ApiResponse[SubjectResponse])
async def get_subject_by_id(
    subject_id: str,
    current_user: UserProfileResponse = Depends(get_current_user),
    subject_service: SubjectService = Depends(get_subject_service)
):
    """Get complete details for a single subject."""
    subject = await subject_service.get_subject_by_id(subject_id, current_user.id)
    return ApiResponse(
        success=True,
        message="Subject details retrieved successfully.",
        data=subject
    )


@router.put("/{subject_id}", response_model=ApiResponse[SubjectResponse])
async def update_subject(
    subject_id: str,
    update_in: SubjectUpdate,
    current_user: UserProfileResponse = Depends(get_current_user),
    subject_service: SubjectService = Depends(get_subject_service)
):
    """Update subject information."""
    updated = await subject_service.update_subject(subject_id, current_user.id, update_in)
    return ApiResponse(
        success=True,
        message="Subject updated successfully.",
        data=updated
    )


@router.delete("/{subject_id}", response_model=ApiResponse[dict])
async def delete_subject(
    subject_id: str,
    current_user: UserProfileResponse = Depends(get_current_user),
    subject_service: SubjectService = Depends(get_subject_service)
):
    """Delete a subject from workspace."""
    success = await subject_service.delete_subject(subject_id, current_user.id)
    return ApiResponse(
        success=success,
        message="Subject deleted successfully.",
        data={"deleted_id": subject_id}
    )


@router.patch("/{subject_id}/archive", response_model=ApiResponse[SubjectResponse])
async def toggle_archive_subject(
    subject_id: str,
    current_user: UserProfileResponse = Depends(get_current_user),
    subject_service: SubjectService = Depends(get_subject_service)
):
    """Toggle subject active/archived state."""
    updated = await subject_service.toggle_archive_subject(subject_id, current_user.id)
    status_str = "archived" if updated.is_archived else "restored"
    return ApiResponse(
        success=True,
        message=f"Subject has been {status_str}.",
        data=updated
    )

from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status

from app.api.deps import get_current_user, get_assignment_service
from app.schemas.assignment import (
    AssignmentCreate,
    AssignmentListResponse,
    AssignmentResponse,
    AssignmentStatusUpdate,
    AssignmentSummaryResponse,
    AssignmentUpdate,
)
from app.schemas.response import ApiResponse
from app.schemas.user import UserProfileResponse
from app.services.assignment_service import AssignmentService

router = APIRouter(prefix="/assignments", tags=["Assignments"])


@router.post("", response_model=ApiResponse[AssignmentResponse], status_code=status.HTTP_201_CREATED)
async def create_assignment(
    assignment_in: AssignmentCreate,
    current_user: UserProfileResponse = Depends(get_current_user),
    service: AssignmentService = Depends(get_assignment_service),
):
    """Create a new academic assignment with due date, priority, and weight percentage."""
    assignment = await service.create_assignment(user_id=current_user.id, assignment_in=assignment_in)
    return ApiResponse(
        success=True,
        message=f"Assignment '{assignment['title']}' created successfully.",
        data=assignment,
    )


@router.get("", response_model=ApiResponse[AssignmentListResponse])
async def list_assignments(
    subject_id: Optional[str] = Query(None, description="Filter by course/subject ID"),
    status: Optional[str] = Query(None, description="Filter by workflow status (pending, in_progress, submitted, graded)"),
    priority: Optional[str] = Query(None, description="Filter by priority (low, medium, high, urgent)"),
    search: Optional[str] = Query(None, description="Search by assignment title"),
    limit: int = Query(100, ge=1, le=200),
    skip: int = Query(0, ge=0),
    current_user: UserProfileResponse = Depends(get_current_user),
    service: AssignmentService = Depends(get_assignment_service),
):
    """List student assignments with filters, counts, and status metrics."""
    result = await service.list_assignments(
        user_id=current_user.id,
        subject_id=subject_id,
        status=status,
        priority=priority,
        search=search,
        limit=limit,
        skip=skip,
    )
    return ApiResponse(
        success=True,
        message="Assignments retrieved successfully.",
        data=result,
    )


@router.get("/upcoming", response_model=ApiResponse[List[AssignmentResponse]])
async def get_upcoming_assignments(
    limit: int = Query(5, ge=1, le=20),
    current_user: UserProfileResponse = Depends(get_current_user),
    service: AssignmentService = Depends(get_assignment_service),
):
    """Get upcoming uncompleted assignments sorted by earliest due date (for Dashboard & Calendar)."""
    upcoming = await service.get_upcoming(user_id=current_user.id, limit=limit)
    return ApiResponse(
        success=True,
        message="Upcoming assignments retrieved.",
        data=upcoming,
    )


@router.get("/summary", response_model=ApiResponse[AssignmentSummaryResponse])
async def get_assignments_summary(
    current_user: UserProfileResponse = Depends(get_current_user),
    service: AssignmentService = Depends(get_assignment_service),
):
    """Get academic planner summary metrics (pending, in-progress, submitted, graded, overdue, due this week)."""
    summary = await service.get_summary(user_id=current_user.id)
    return ApiResponse(
        success=True,
        message="Assignment summary metrics retrieved.",
        data=summary,
    )


@router.get("/{assignment_id}", response_model=ApiResponse[AssignmentResponse])
async def get_assignment(
    assignment_id: str,
    current_user: UserProfileResponse = Depends(get_current_user),
    service: AssignmentService = Depends(get_assignment_service),
):
    """Get single assignment details."""
    assignment = await service.get_assignment(assignment_id=assignment_id, user_id=current_user.id)
    return ApiResponse(
        success=True,
        message="Assignment details retrieved.",
        data=assignment,
    )


@router.put("/{assignment_id}", response_model=ApiResponse[AssignmentResponse])
async def update_assignment(
    assignment_id: str,
    assignment_update: AssignmentUpdate,
    current_user: UserProfileResponse = Depends(get_current_user),
    service: AssignmentService = Depends(get_assignment_service),
):
    """Update assignment metadata, due date, status, priority, or grade received."""
    updated = await service.update_assignment(
        assignment_id=assignment_id,
        user_id=current_user.id,
        assignment_update=assignment_update,
    )
    return ApiResponse(
        success=True,
        message="Assignment updated successfully.",
        data=updated,
    )


@router.patch("/{assignment_id}/status", response_model=ApiResponse[AssignmentResponse])
async def update_assignment_status(
    assignment_id: str,
    status_update: AssignmentStatusUpdate,
    current_user: UserProfileResponse = Depends(get_current_user),
    service: AssignmentService = Depends(get_assignment_service),
):
    """Quick transition of assignment status (e.g. Kanban drag or checkbox click)."""
    updated = await service.update_status(
        assignment_id=assignment_id,
        user_id=current_user.id,
        new_status=status_update.status,
    )
    return ApiResponse(
        success=True,
        message=f"Assignment status changed to {status_update.status.value}.",
        data=updated,
    )


@router.delete("/{assignment_id}", response_model=ApiResponse[dict], status_code=status.HTTP_200_OK)
async def delete_assignment(
    assignment_id: str,
    current_user: UserProfileResponse = Depends(get_current_user),
    service: AssignmentService = Depends(get_assignment_service),
):
    """Delete an assignment."""
    await service.delete_assignment(assignment_id=assignment_id, user_id=current_user.id)
    return ApiResponse(
        success=True,
        message="Assignment deleted successfully.",
        data={"deleted_id": assignment_id},
    )

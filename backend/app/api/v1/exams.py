from datetime import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status

from app.api.deps import get_current_user, get_exam_service
from app.schemas.exam import (
    ExamCalendarResponse,
    ExamCreate,
    ExamListResponse,
    ExamResponse,
    ExamUpdate,
)
from app.schemas.response import ApiResponse
from app.schemas.user import UserProfileResponse
from app.services.exam_service import ExamService

router = APIRouter(prefix="/exams", tags=["Exams"])


@router.post("", response_model=ApiResponse[ExamResponse], status_code=status.HTTP_201_CREATED)
async def create_exam(
    exam_in: ExamCreate,
    current_user: UserProfileResponse = Depends(get_current_user),
    service: ExamService = Depends(get_exam_service),
):
    """Schedule a new academic examination or assessment."""
    exam = await service.create_exam(user_id=current_user.id, exam_in=exam_in)
    return ApiResponse(
        success=True,
        message=f"Exam '{exam['title']}' scheduled successfully.",
        data=exam,
    )


@router.get("", response_model=ApiResponse[ExamListResponse])
async def list_exams(
    subject_id: Optional[str] = Query(None, description="Filter by course/subject ID"),
    exam_type: Optional[str] = Query(None, description="Filter by exam type (quiz, midterm, final, lab_practical, oral_presentation)"),
    is_upcoming: Optional[bool] = Query(None, description="Filter only upcoming (true) or past (false) exams"),
    search: Optional[str] = Query(None, description="Search by exam title"),
    limit: int = Query(100, ge=1, le=200),
    skip: int = Query(0, ge=0),
    current_user: UserProfileResponse = Depends(get_current_user),
    service: ExamService = Depends(get_exam_service),
):
    """List scheduled student exams with filters and metrics."""
    result = await service.list_exams(
        user_id=current_user.id,
        subject_id=subject_id,
        exam_type=exam_type,
        is_upcoming=is_upcoming,
        search=search,
        limit=limit,
        skip=skip,
    )
    return ApiResponse(
        success=True,
        message="Exams retrieved successfully.",
        data=result,
    )


@router.get("/upcoming", response_model=ApiResponse[List[ExamResponse]])
async def get_upcoming_exams(
    limit: int = Query(5, ge=1, le=20),
    current_user: UserProfileResponse = Depends(get_current_user),
    service: ExamService = Depends(get_exam_service),
):
    """Get upcoming exams sorted chronologically for Dashboard and countdowns."""
    upcoming = await service.get_upcoming(user_id=current_user.id, limit=limit)
    return ApiResponse(
        success=True,
        message="Upcoming exams retrieved.",
        data=upcoming,
    )


@router.get("/calendar", response_model=ApiResponse[ExamCalendarResponse])
async def get_study_calendar(
    start_date: Optional[str] = Query(None, description="Start date for calendar window (ISO format or YYYY-MM-DD)"),
    end_date: Optional[str] = Query(None, description="End date for calendar window (ISO format or YYYY-MM-DD)"),
    current_user: UserProfileResponse = Depends(get_current_user),
    service: ExamService = Depends(get_exam_service),
):
    """Get unified study calendar events (combining scheduled exams and assignment deadlines)."""
    parsed_start = None
    parsed_end = None

    if start_date:
        clean_start = start_date.strip().replace(" ", "+").replace("Z", "+00:00")
        if len(clean_start) == 10:  # YYYY-MM-DD
            parsed_start = datetime.fromisoformat(clean_start + "T00:00:00+00:00")
        else:
            parsed_start = datetime.fromisoformat(clean_start)

    if end_date:
        clean_end = end_date.strip().replace(" ", "+").replace("Z", "+00:00")
        if len(clean_end) == 10:  # YYYY-MM-DD
            parsed_end = datetime.fromisoformat(clean_end + "T23:59:59+00:00")
        else:
            parsed_end = datetime.fromisoformat(clean_end)

    calendar_data = await service.get_calendar(
        user_id=current_user.id,
        start_date=parsed_start,
        end_date=parsed_end,
    )
    return ApiResponse(
        success=True,
        message="Study calendar events retrieved.",
        data=calendar_data,
    )


@router.get("/{exam_id}", response_model=ApiResponse[ExamResponse])
async def get_exam(
    exam_id: str,
    current_user: UserProfileResponse = Depends(get_current_user),
    service: ExamService = Depends(get_exam_service),
):
    """Get single exam details."""
    exam = await service.get_exam(exam_id=exam_id, user_id=current_user.id)
    return ApiResponse(
        success=True,
        message="Exam details retrieved.",
        data=exam,
    )


@router.put("/{exam_id}", response_model=ApiResponse[ExamResponse])
async def update_exam(
    exam_id: str,
    exam_update: ExamUpdate,
    current_user: UserProfileResponse = Depends(get_current_user),
    service: ExamService = Depends(get_exam_service),
):
    """Update exam schedule, location, syllabus topics, target score, or actual grade received."""
    updated = await service.update_exam(
        exam_id=exam_id,
        user_id=current_user.id,
        exam_update=exam_update,
    )
    return ApiResponse(
        success=True,
        message="Exam updated successfully.",
        data=updated,
    )


@router.delete("/{exam_id}", response_model=ApiResponse[dict], status_code=status.HTTP_200_OK)
async def delete_exam(
    exam_id: str,
    current_user: UserProfileResponse = Depends(get_current_user),
    service: ExamService = Depends(get_exam_service),
):
    """Delete an exam."""
    await service.delete_exam(exam_id=exam_id, user_id=current_user.id)
    return ApiResponse(
        success=True,
        message="Exam deleted successfully.",
        data={"deleted_id": exam_id},
    )

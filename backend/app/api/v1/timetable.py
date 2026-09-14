from datetime import date
from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, Query, status

from app.api.deps import get_current_user, get_timetable_service
from app.schemas.response import ApiResponse
from app.schemas.user import UserProfileResponse
from app.schemas.timetable import (
    AttendanceLogCreate,
    AttendanceLogResponse,
    AttendanceLogUpdate,
    AttendanceSummaryResponse,
    DayOfWeekEnum,
    TimetableSlotCreate,
    TimetableSlotResponse,
    TimetableSlotUpdate,
    TimetableWeeklyResponse,
    TodayClassResponse,
)
from app.services.timetable_service import TimetableService

router = APIRouter(prefix="/timetable", tags=["Timetable & Attendance"])


# --- Timetable Slots Endpoints ---

@router.post(
    "/slots",
    response_model=ApiResponse[TimetableSlotResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Create a new class timetable slot",
)
async def create_slot(
    data: TimetableSlotCreate,
    current_user: UserProfileResponse = Depends(get_current_user),
    service: TimetableService = Depends(get_timetable_service),
) -> ApiResponse[TimetableSlotResponse]:
    slot = await service.create_slot(current_user.id, data)
    return ApiResponse(success=True, message="Class slot scheduled successfully", data=slot)


@router.get(
    "/slots",
    response_model=ApiResponse[List[TimetableSlotResponse]],
    summary="List timetable slots with optional day and subject filters",
)
async def list_slots(
    day_of_week: Optional[DayOfWeekEnum] = Query(None, description="Filter by day of week"),
    subject_id: Optional[str] = Query(None, description="Filter by subject ID"),
    current_user: UserProfileResponse = Depends(get_current_user),
    service: TimetableService = Depends(get_timetable_service),
) -> ApiResponse[List[TimetableSlotResponse]]:
    day_val = day_of_week.value if day_of_week else None
    slots = await service.list_slots(
        user_id=current_user.id,
        day_of_week=day_val,
        subject_id=subject_id,
    )
    return ApiResponse(success=True, message="Timetable slots retrieved", data=slots)


@router.get(
    "/today",
    response_model=ApiResponse[List[TodayClassResponse]],
    summary="Get today's classes with live status and attendance records",
)
async def get_today_classes(
    custom_date: Optional[date] = Query(None, alias="date", description="Optional date in YYYY-MM-DD format"),
    current_user: UserProfileResponse = Depends(get_current_user),
    service: TimetableService = Depends(get_timetable_service),
) -> ApiResponse[List[TodayClassResponse]]:
    classes = await service.get_today_schedule(
        user_id=current_user.id,
        custom_date=custom_date,
    )
    return ApiResponse(success=True, message="Today's schedule retrieved", data=classes)


@router.get(
    "/weekly",
    response_model=ApiResponse[TimetableWeeklyResponse],
    summary="Get the full weekly timetable schedule grouped by day",
)
async def get_weekly_schedule(
    current_user: UserProfileResponse = Depends(get_current_user),
    service: TimetableService = Depends(get_timetable_service),
) -> ApiResponse[TimetableWeeklyResponse]:
    weekly = await service.get_weekly_schedule(current_user.id)
    return ApiResponse(success=True, message="Weekly schedule retrieved", data=weekly)


@router.get(
    "/slots/{id}",
    response_model=ApiResponse[TimetableSlotResponse],
    summary="Get a single timetable slot by ID",
)
async def get_slot(
    id: str,
    current_user: UserProfileResponse = Depends(get_current_user),
    service: TimetableService = Depends(get_timetable_service),
) -> ApiResponse[TimetableSlotResponse]:
    slot = await service.get_slot(id, current_user.id)
    return ApiResponse(success=True, message="Slot retrieved", data=slot)


@router.put(
    "/slots/{id}",
    response_model=ApiResponse[TimetableSlotResponse],
    summary="Update a timetable slot",
)
async def update_slot(
    id: str,
    data: TimetableSlotUpdate,
    current_user: UserProfileResponse = Depends(get_current_user),
    service: TimetableService = Depends(get_timetable_service),
) -> ApiResponse[TimetableSlotResponse]:
    slot = await service.update_slot(id, current_user.id, data)
    return ApiResponse(success=True, message="Class slot updated successfully", data=slot)


@router.delete(
    "/slots/{id}",
    response_model=ApiResponse[Dict[str, Any]],
    summary="Delete a timetable slot",
)
async def delete_slot(
    id: str,
    current_user: UserProfileResponse = Depends(get_current_user),
    service: TimetableService = Depends(get_timetable_service),
) -> ApiResponse[Dict[str, Any]]:
    await service.delete_slot(id, current_user.id)
    return ApiResponse(success=True, message="Class slot deleted successfully", data={"id": id, "deleted": True})


# --- Attendance Endpoints ---

@router.post(
    "/attendance",
    response_model=ApiResponse[AttendanceLogResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Log or update attendance for a class session",
)
async def log_attendance(
    data: AttendanceLogCreate,
    current_user: UserProfileResponse = Depends(get_current_user),
    service: TimetableService = Depends(get_timetable_service),
) -> ApiResponse[AttendanceLogResponse]:
    log = await service.log_attendance(current_user.id, data)
    return ApiResponse(success=True, message="Attendance logged successfully", data=log)


@router.get(
    "/attendance/summary",
    response_model=ApiResponse[AttendanceSummaryResponse],
    summary="Get comprehensive attendance statistics, safe bunks, and threshold metrics",
)
async def get_attendance_summary(
    target_percentage: float = Query(75.0, description="Minimum attendance threshold percentage"),
    current_user: UserProfileResponse = Depends(get_current_user),
    service: TimetableService = Depends(get_timetable_service),
) -> ApiResponse[AttendanceSummaryResponse]:
    summary = await service.get_attendance_summary(
        user_id=current_user.id,
        target_percentage=target_percentage,
    )
    return ApiResponse(success=True, message="Attendance summary retrieved", data=summary)


@router.get(
    "/attendance/logs",
    response_model=ApiResponse[List[AttendanceLogResponse]],
    summary="Get attendance history logs",
)
async def get_attendance_logs(
    subject_id: Optional[str] = Query(None, description="Filter by subject ID"),
    slot_id: Optional[str] = Query(None, description="Filter by slot ID"),
    limit: int = Query(100, ge=1, le=500),
    current_user: UserProfileResponse = Depends(get_current_user),
    service: TimetableService = Depends(get_timetable_service),
) -> ApiResponse[List[AttendanceLogResponse]]:
    logs = await service.get_attendance_logs(
        user_id=current_user.id,
        subject_id=subject_id,
        slot_id=slot_id,
        limit=limit,
    )
    return ApiResponse(success=True, message="Attendance logs retrieved", data=logs)


@router.put(
    "/attendance/{id}",
    response_model=ApiResponse[AttendanceLogResponse],
    summary="Update an existing attendance log",
)
async def update_attendance_log(
    id: str,
    data: AttendanceLogUpdate,
    current_user: UserProfileResponse = Depends(get_current_user),
    service: TimetableService = Depends(get_timetable_service),
) -> ApiResponse[AttendanceLogResponse]:
    log = await service.update_attendance_log(id, current_user.id, data)
    return ApiResponse(success=True, message="Attendance log updated successfully", data=log)


@router.delete(
    "/attendance/{id}",
    response_model=ApiResponse[Dict[str, Any]],
    summary="Delete an attendance record",
)
async def delete_attendance_log(
    id: str,
    current_user: UserProfileResponse = Depends(get_current_user),
    service: TimetableService = Depends(get_timetable_service),
) -> ApiResponse[Dict[str, Any]]:
    await service.delete_attendance_log(id, current_user.id)
    return ApiResponse(success=True, message="Attendance log deleted successfully", data={"id": id, "deleted": True})

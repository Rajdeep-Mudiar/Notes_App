from datetime import date, datetime, time, timezone, timedelta
from typing import Any, Dict, List, Optional
from fastapi import HTTPException, status

from app.repositories.timetable_repository import TimetableRepository
from app.repositories.attendance_repository import AttendanceRepository
from app.schemas.timetable import (
    AttendanceLogCreate,
    AttendanceLogResponse,
    AttendanceLogUpdate,
    AttendanceStatusEnum,
    AttendanceSummaryResponse,
    DayOfWeekEnum,
    TimetableSlotCreate,
    TimetableSlotResponse,
    TimetableSlotUpdate,
    TimetableWeeklyResponse,
    TodayClassResponse,
)


class TimetableService:
    def __init__(
        self,
        timetable_repo: TimetableRepository,
        attendance_repo: AttendanceRepository,
    ):
        self.timetable_repo = timetable_repo
        self.attendance_repo = attendance_repo

    @staticmethod
    def _validate_times(start_time: str, end_time: str) -> None:
        try:
            s_hour, s_min = map(int, start_time.split(":"))
            e_hour, e_min = map(int, end_time.split(":"))
            s_val = s_hour * 60 + s_min
            e_val = e_hour * 60 + e_min
            if e_val <= s_val:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="End time must be after start time.",
                )
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid time format. Please use HH:MM (e.g. 09:30).",
            )

    async def create_slot(self, user_id: str, data: TimetableSlotCreate) -> TimetableSlotResponse:
        self._validate_times(data.start_time, data.end_time)

        # Check collision
        has_overlap = await self.timetable_repo.check_collision(
            user_id=user_id,
            day_of_week=data.day_of_week.value,
            start_time=data.start_time,
            end_time=data.end_time,
        )
        if has_overlap:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Time slot overlaps with another scheduled class on {data.day_of_week.value.capitalize()}.",
            )

        slot = await self.timetable_repo.create_slot(user_id, data)
        return TimetableSlotResponse(**slot)

    async def get_slot(self, slot_id: str, user_id: str) -> TimetableSlotResponse:
        slot = await self.timetable_repo.get_slot_by_id(slot_id, user_id)
        if not slot:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Timetable slot not found.",
            )
        return TimetableSlotResponse(**slot)

    async def list_slots(
        self,
        user_id: str,
        day_of_week: Optional[str] = None,
        subject_id: Optional[str] = None,
    ) -> List[TimetableSlotResponse]:
        slots = await self.timetable_repo.list_slots(user_id, day_of_week, subject_id)
        return [TimetableSlotResponse(**s) for s in slots]

    async def update_slot(
        self, slot_id: str, user_id: str, data: TimetableSlotUpdate
    ) -> TimetableSlotResponse:
        existing = await self.timetable_repo.get_slot_by_id(slot_id, user_id)
        if not existing:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Timetable slot not found.",
            )

        new_day = data.day_of_week.value if data.day_of_week else existing["day_of_week"]
        new_start = data.start_time or existing["start_time"]
        new_end = data.end_time or existing["end_time"]

        self._validate_times(new_start, new_end)

        has_overlap = await self.timetable_repo.check_collision(
            user_id=user_id,
            day_of_week=new_day,
            start_time=new_start,
            end_time=new_end,
            exclude_slot_id=slot_id,
        )
        if has_overlap:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Time slot overlaps with another scheduled class on {new_day.capitalize()}.",
            )

        updated = await self.timetable_repo.update_slot(slot_id, user_id, data)
        return TimetableSlotResponse(**updated)

    async def delete_slot(self, slot_id: str, user_id: str) -> bool:
        success = await self.timetable_repo.delete_slot(slot_id, user_id)
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Timetable slot not found.",
            )
        return True

    async def get_weekly_schedule(self, user_id: str) -> TimetableWeeklyResponse:
        all_slots = await self.timetable_repo.list_slots(user_id)

        weekly = {
            "monday": [],
            "tuesday": [],
            "wednesday": [],
            "thursday": [],
            "friday": [],
            "saturday": [],
            "sunday": [],
        }

        for s in all_slots:
            day = s.get("day_of_week", "monday").lower()
            if day in weekly:
                weekly[day].append(TimetableSlotResponse(**s))

        return TimetableWeeklyResponse(
            monday=weekly["monday"],
            tuesday=weekly["tuesday"],
            wednesday=weekly["wednesday"],
            thursday=weekly["thursday"],
            friday=weekly["friday"],
            saturday=weekly["saturday"],
            sunday=weekly["sunday"],
            total_slots=len(all_slots),
        )

    async def get_today_schedule(
        self,
        user_id: str,
        custom_date: Optional[date] = None,
    ) -> List[TodayClassResponse]:
        target_date = custom_date or datetime.now(timezone.utc).date()
        day_names = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
        current_day_str = day_names[target_date.weekday()]

        today_slots = await self.timetable_repo.list_slots(
            user_id=user_id,
            day_of_week=current_day_str,
        )

        attendance_map = await self.attendance_repo.get_logs_for_date(user_id, target_date)

        now = datetime.now(timezone.utc)
        current_time_str = now.strftime("%H:%M")
        cur_hour, cur_min = now.hour, now.minute
        cur_total_min = cur_hour * 60 + cur_min

        results: List[TodayClassResponse] = []

        for slot_dict in today_slots:
            slot_resp = TimetableSlotResponse(**slot_dict)
            s_hour, s_min = map(int, slot_resp.start_time.split(":"))
            e_hour, e_min = map(int, slot_resp.end_time.split(":"))
            start_total_min = s_hour * 60 + s_min
            end_total_min = e_hour * 60 + e_min

            if cur_total_min < start_total_min:
                time_diff = start_total_min - cur_total_min
                status_str = "upcoming"
                if time_diff <= 60:
                    status_text = f"Starting in {time_diff} mins"
                else:
                    status_text = f"Starts at {slot_resp.start_time}"
            elif start_total_min <= cur_total_min <= end_total_min:
                remaining_min = end_total_min - cur_total_min
                status_str = "ongoing"
                status_text = f"Happening now (ends in {remaining_min} mins)"
            else:
                status_str = "completed"
                status_text = f"Finished at {slot_resp.end_time}"

            # Check attendance record
            att_doc = attendance_map.get(slot_resp.id)
            if not att_doc and slot_resp.subject_id:
                att_doc = attendance_map.get(f"sub_{slot_resp.subject_id}")

            att_status = None
            att_log_id = None
            if att_doc:
                att_status = AttendanceStatusEnum(att_doc["status"])
                att_log_id = str(att_doc["_id"])

            results.append(
                TodayClassResponse(
                    slot=slot_resp,
                    status=status_str,
                    time_status_text=status_text,
                    attendance_today=att_status,
                    attendance_log_id=att_log_id,
                )
            )

        return results

    # --- Attendance Actions ---

    async def log_attendance(
        self, user_id: str, data: AttendanceLogCreate
    ) -> AttendanceLogResponse:
        log = await self.attendance_repo.log_attendance(user_id, data)
        return AttendanceLogResponse(**log)

    async def get_attendance_logs(
        self,
        user_id: str,
        subject_id: Optional[str] = None,
        slot_id: Optional[str] = None,
        limit: int = 100,
    ) -> List[AttendanceLogResponse]:
        logs = await self.attendance_repo.list_logs(
            user_id=user_id,
            subject_id=subject_id,
            slot_id=slot_id,
            limit=limit,
        )
        return [AttendanceLogResponse(**l) for l in logs]

    async def update_attendance_log(
        self, log_id: str, user_id: str, data: AttendanceLogUpdate
    ) -> AttendanceLogResponse:
        updated = await self.attendance_repo.update_log(log_id, user_id, data)
        if not updated:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Attendance log not found.",
            )
        return AttendanceLogResponse(**updated)

    async def delete_attendance_log(self, log_id: str, user_id: str) -> bool:
        deleted = await self.attendance_repo.delete_log(log_id, user_id)
        if not deleted:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Attendance log not found.",
            )
        return True

    async def get_attendance_summary(
        self, user_id: str, target_percentage: float = 75.0
    ) -> AttendanceSummaryResponse:
        return await self.attendance_repo.get_attendance_summary(
            user_id=user_id,
            target_percentage=target_percentage,
        )

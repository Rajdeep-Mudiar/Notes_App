from datetime import date, datetime, time
from enum import Enum
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class DayOfWeekEnum(str, Enum):
    MONDAY = "monday"
    TUESDAY = "tuesday"
    WEDNESDAY = "wednesday"
    THURSDAY = "thursday"
    FRIDAY = "friday"
    SATURDAY = "saturday"
    SUNDAY = "sunday"


class ClassTypeEnum(str, Enum):
    LECTURE = "lecture"
    LAB = "lab"
    TUTORIAL = "tutorial"
    SEMINAR = "seminar"
    WORKSHOP = "workshop"
    OTHER = "other"


class AttendanceStatusEnum(str, Enum):
    PRESENT = "present"
    ABSENT = "absent"
    LATE = "late"
    EXCUSED = "excused"


# --- Timetable Slot Schemas ---

class TimetableSlotCreate(BaseModel):
    subject_id: Optional[str] = None
    title: Optional[str] = None  # Optional custom title if subject_id is omitted
    day_of_week: DayOfWeekEnum
    start_time: str = Field(..., description="24-hour format HH:MM, e.g., '09:00'")
    end_time: str = Field(..., description="24-hour format HH:MM, e.g., '10:30'")
    class_type: ClassTypeEnum = ClassTypeEnum.LECTURE
    location: str = Field(default="", description="Room, Hall, Building, or Online link")
    professor_name: Optional[str] = None
    notes: Optional[str] = None


class TimetableSlotUpdate(BaseModel):
    subject_id: Optional[str] = None
    title: Optional[str] = None
    day_of_week: Optional[DayOfWeekEnum] = None
    start_time: Optional[str] = None
    end_time: Optional[str] = None
    class_type: Optional[ClassTypeEnum] = None
    location: Optional[str] = None
    professor_name: Optional[str] = None
    notes: Optional[str] = None


class TimetableSlotResponse(BaseModel):
    id: str
    user_id: str
    subject_id: Optional[str] = None
    subject_code: Optional[str] = None
    subject_name: Optional[str] = None
    subject_color: Optional[str] = None
    title: str
    day_of_week: DayOfWeekEnum
    start_time: str
    end_time: str
    class_type: ClassTypeEnum
    location: str
    professor_name: Optional[str] = None
    notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime


class TodayClassResponse(BaseModel):
    slot: TimetableSlotResponse
    status: str = Field(..., description="'ongoing', 'upcoming', or 'completed'")
    time_status_text: str = Field(..., description="'Happening now', 'In 25 mins', 'Finished at 10:30'")
    attendance_today: Optional[AttendanceStatusEnum] = None
    attendance_log_id: Optional[str] = None


class TimetableWeeklyResponse(BaseModel):
    monday: List[TimetableSlotResponse] = []
    tuesday: List[TimetableSlotResponse] = []
    wednesday: List[TimetableSlotResponse] = []
    thursday: List[TimetableSlotResponse] = []
    friday: List[TimetableSlotResponse] = []
    saturday: List[TimetableSlotResponse] = []
    sunday: List[TimetableSlotResponse] = []
    total_slots: int = 0


# --- Attendance Log Schemas ---

class AttendanceLogCreate(BaseModel):
    slot_id: Optional[str] = None
    subject_id: Optional[str] = None
    date: date
    status: AttendanceStatusEnum = AttendanceStatusEnum.PRESENT
    notes: Optional[str] = None


class AttendanceLogUpdate(BaseModel):
    status: Optional[AttendanceStatusEnum] = None
    notes: Optional[str] = None


class AttendanceLogResponse(BaseModel):
    id: str
    user_id: str
    slot_id: Optional[str] = None
    subject_id: Optional[str] = None
    subject_code: Optional[str] = None
    subject_name: Optional[str] = None
    subject_color: Optional[str] = None
    date: date
    status: AttendanceStatusEnum
    notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime


class SubjectAttendanceStats(BaseModel):
    subject_id: str
    subject_code: str
    subject_name: str
    subject_color: str
    total_classes: int
    attended_classes: int  # present + late + excused
    absent_classes: int
    late_classes: int
    excused_classes: int
    attendance_percentage: float
    target_percentage: float = 75.0
    is_critical: bool  # attendance_percentage < target_percentage
    safe_bunks: int  # How many classes student can miss while staying >= 75%
    classes_needed_to_target: int  # If below 75%, how many consecutive classes needed


class AttendanceSummaryResponse(BaseModel):
    overall_total_classes: int
    overall_attended_classes: int
    overall_absent_classes: int
    overall_percentage: float
    minimum_required_percentage: float = 75.0
    critical_subjects_count: int
    subjects_stats: List[SubjectAttendanceStats]

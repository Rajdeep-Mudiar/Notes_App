from datetime import datetime
from enum import Enum
from typing import List, Optional
from pydantic import BaseModel, Field


class ExamTypeEnum(str, Enum):
    QUIZ = "quiz"
    MIDTERM = "midterm"
    FINAL = "final"
    LAB_PRACTICAL = "lab_practical"
    ORAL_PRESENTATION = "oral_presentation"

    @property
    def label(self) -> str:
        labels = {
            "quiz": "Quiz / Test",
            "midterm": "Midterm Exam",
            "final": "Final Exam",
            "lab_practical": "Lab Practical",
            "oral_presentation": "Oral Presentation",
        }
        return labels.get(self.value, self.value.replace("_", " ").title())


class ExamCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=200, description="Exam or Assessment title")
    subject_id: Optional[str] = Field(None, description="Course / Subject ID")
    exam_type: ExamTypeEnum = Field(ExamTypeEnum.MIDTERM, description="Type of examination")
    date_time: datetime = Field(..., description="Date and start time of the exam (ISO format)")
    duration_minutes: int = Field(60, ge=5, le=600, description="Duration in minutes (e.g. 120)")
    location: Optional[str] = Field("", max_length=300, description="Building, Room, Hall, or Zoom URL")
    seat_number: Optional[str] = Field(None, max_length=50, description="Assigned seat or desk number")
    syllabus_topics: List[str] = Field(default_factory=list, description="List of syllabus modules / chapters covered")
    weight_percentage: Optional[float] = Field(None, ge=0.0, le=100.0, description="Weight towards final course grade (0-100%)")
    target_grade: Optional[float] = Field(None, ge=0.0, le=100.0, description="Student target grade goal (%)")
    actual_grade: Optional[float] = Field(None, ge=0.0, le=100.0, description="Actual grade received (%)")
    notes: Optional[str] = Field("", max_length=3000, description="Permitted items, formula sheets, instructions")


class ExamUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    subject_id: Optional[str] = None
    exam_type: Optional[ExamTypeEnum] = None
    date_time: Optional[datetime] = None
    duration_minutes: Optional[int] = Field(None, ge=5, le=600)
    location: Optional[str] = Field(None, max_length=300)
    seat_number: Optional[str] = Field(None, max_length=50)
    syllabus_topics: Optional[List[str]] = None
    weight_percentage: Optional[float] = Field(None, ge=0.0, le=100.0)
    target_grade: Optional[float] = Field(None, ge=0.0, le=100.0)
    actual_grade: Optional[float] = Field(None, ge=0.0, le=100.0)
    notes: Optional[str] = Field(None, max_length=3000)


class ExamResponse(BaseModel):
    id: str
    user_id: str
    subject_id: Optional[str] = None
    subject_code: Optional[str] = None
    subject_name: Optional[str] = None
    subject_color: Optional[str] = None
    title: str
    exam_type: ExamTypeEnum
    date_time: datetime
    duration_minutes: int
    location: str = ""
    seat_number: Optional[str] = None
    syllabus_topics: List[str] = Field(default_factory=list)
    weight_percentage: Optional[float] = None
    target_grade: Optional[float] = None
    actual_grade: Optional[float] = None
    notes: str = ""
    is_completed: bool = False
    countdown_text: str = ""
    created_at: datetime
    updated_at: datetime


class ExamListResponse(BaseModel):
    items: List[ExamResponse]
    total: int
    upcoming_count: int
    completed_count: int


class CalendarEventItem(BaseModel):
    id: str
    type: str  # 'exam' or 'assignment'
    title: str
    date_time: datetime
    subject_code: Optional[str] = None
    subject_name: Optional[str] = None
    subject_color: Optional[str] = None
    priority_or_type: str  # 'urgent' / 'final' etc.
    is_completed: bool = False
    location_or_desc: Optional[str] = None


class ExamCalendarResponse(BaseModel):
    start_date: datetime
    end_date: datetime
    events: List[CalendarEventItem]
    total_events: int

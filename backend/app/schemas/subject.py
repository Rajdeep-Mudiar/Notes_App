from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field


class SubjectBase(BaseModel):
    name: str = Field(..., min_length=2, max_length=150, description="Subject title, e.g. Data Structures")
    code: str = Field(..., min_length=1, max_length=50, description="Course code, e.g. CS204")
    professor: Optional[str] = Field(default="TBD", max_length=100, description="Teacher / Professor name")
    credits: int = Field(default=3, ge=1, le=30, description="Academic credits for the course")
    color: str = Field(default="#4F46E5", description="Hex color code for visual identification")
    icon: str = Field(default="book", description="Icon identifier, e.g. book, code, calculation")
    description: Optional[str] = Field(default="", max_length=1000, description="Subject description & syllabus overview")
    semester: int = Field(default=1, ge=1, le=16, description="Semester number this subject belongs to")


class SubjectCreate(SubjectBase):
    pass


class SubjectUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=2, max_length=150)
    code: Optional[str] = Field(None, min_length=1, max_length=50)
    professor: Optional[str] = Field(None, max_length=100)
    credits: Optional[int] = Field(None, ge=1, le=30)
    color: Optional[str] = None
    icon: Optional[str] = None
    description: Optional[str] = Field(None, max_length=1000)
    semester: Optional[int] = Field(None, ge=1, le=16)
    is_archived: Optional[bool] = None


class SubjectResponse(SubjectBase):
    id: str
    user_id: str
    is_archived: bool = False
    created_at: datetime
    updated_at: datetime
    notes_count: int = 0
    files_count: int = 0
    assignments_count: int = 0
    exams_count: int = 0


class SubjectListResponse(BaseModel):
    subjects: List[SubjectResponse]
    total_count: int
    semester: Optional[int] = None


class AcademicSummaryResponse(BaseModel):
    total_subjects: int
    active_subjects: int
    archived_subjects: int
    total_credits: int
    current_semester: int
    semester_credits: int

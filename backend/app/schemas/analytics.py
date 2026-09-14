from enum import Enum
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class GradingScaleEnum(str, Enum):
    SCALE_4_0 = "scale_4_0"
    SCALE_10_0 = "scale_10_0"
    PERCENTAGE = "percentage"


class LetterGradeEnum(str, Enum):
    A_PLUS = "A+"
    A = "A"
    A_MINUS = "A-"
    B_PLUS = "B+"
    B = "B"
    B_MINUS = "B-"
    C_PLUS = "C+"
    C = "C"
    C_MINUS = "C-"
    D_PLUS = "D+"
    D = "D"
    F = "F"
    # 10.0 scale specific / European
    O = "O"
    P = "P"


class SubjectGradeInput(BaseModel):
    letter_grade: Optional[str] = Field(None, description="Letter grade, e.g., 'A', 'B+', 'O'")
    numerical_grade: Optional[float] = Field(None, ge=0.0, le=100.0, description="Percentage score (0-100)")
    target_grade: Optional[str] = Field(None, description="Target letter grade, e.g., 'A'")


class SubjectGradeResponse(BaseModel):
    subject_id: str
    subject_code: str
    subject_name: str
    subject_color: str
    semester: int
    credits: int
    letter_grade: Optional[str] = None
    numerical_grade: Optional[float] = None
    grade_point: Optional[float] = None
    target_grade: Optional[str] = None
    is_graded: bool = False


class SemesterGPAResponse(BaseModel):
    semester: int
    semester_label: str
    total_credits: int
    graded_credits: int
    sgpa: float  # Semester GPA
    subjects: List[SubjectGradeResponse] = []


class CGPASummaryResponse(BaseModel):
    current_cgpa: float
    target_cgpa: Optional[float] = 3.8
    scale: GradingScaleEnum = GradingScaleEnum.SCALE_4_0
    total_enrolled_credits: int
    total_earned_credits: int
    graduation_required_credits: int = 120
    credits_progress_percentage: float
    honors_standing: str  # e.g., "Summa Cum Laude", "Dean's List", "First Class with Distinction"
    academic_status: str  # "Good Standing", "Satisfactory", "Academic Warning"
    semester_breakdown: List[SemesterGPAResponse] = []
    highest_sgpa_semester: Optional[int] = None
    lowest_sgpa_semester: Optional[int] = None


# --- What-If Scenario Schemas ---

class WhatIfCourseInput(BaseModel):
    subject_id: Optional[str] = None
    course_name: Optional[str] = None
    credits: int = Field(default=4, ge=1, le=12)
    hypothetical_grade: str = Field(..., description="Letter grade e.g. 'A', 'B+', or grade point e.g. '4.0'")


class WhatIfScenarioRequest(BaseModel):
    courses: List[WhatIfCourseInput]
    target_cgpa: Optional[float] = None
    scale: GradingScaleEnum = GradingScaleEnum.SCALE_4_0


class WhatIfScenarioResponse(BaseModel):
    baseline_cgpa: float
    projected_cgpa: float
    cgpa_difference: float
    total_projected_credits: int
    target_cgpa: Optional[float] = None
    target_achieved: Optional[bool] = None
    required_average_grade_point: Optional[float] = None
    projection_message: str

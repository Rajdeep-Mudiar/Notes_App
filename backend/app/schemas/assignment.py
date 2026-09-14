from datetime import datetime
from enum import Enum
from typing import List, Optional
from pydantic import BaseModel, Field


class AssignmentPriorityEnum(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    URGENT = "urgent"


class AssignmentStatusEnum(str, Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    SUBMITTED = "submitted"
    GRADED = "graded"


class AssignmentCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=200, description="Assignment title")
    description: Optional[str] = Field("", max_length=5000, description="Detailed instructions or prompt")
    subject_id: Optional[str] = Field(None, description="Associated course/subject ID")
    due_date: datetime = Field(..., description="Due date and time (ISO format)")
    priority: AssignmentPriorityEnum = Field(AssignmentPriorityEnum.MEDIUM, description="Priority level")
    status: AssignmentStatusEnum = Field(AssignmentStatusEnum.PENDING, description="Workflow status")
    weight_percentage: Optional[float] = Field(None, ge=0.0, le=100.0, description="Weight towards final course grade (0-100%)")
    file_ids: List[str] = Field(default_factory=list, description="Attached file IDs")


class AssignmentUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=5000)
    subject_id: Optional[str] = None
    due_date: Optional[datetime] = None
    priority: Optional[AssignmentPriorityEnum] = None
    status: Optional[AssignmentStatusEnum] = None
    weight_percentage: Optional[float] = Field(None, ge=0.0, le=100.0)
    grade_received: Optional[float] = Field(None, ge=0.0, le=100.0, description="Grade received (e.g. 94.5%)")
    feedback: Optional[str] = Field(None, max_length=2000, description="Professor or TA feedback")
    file_ids: Optional[List[str]] = None


class AssignmentStatusUpdate(BaseModel):
    status: AssignmentStatusEnum


class AssignmentResponse(BaseModel):
    id: str
    user_id: str
    subject_id: Optional[str] = None
    subject_code: Optional[str] = None
    subject_name: Optional[str] = None
    subject_color: Optional[str] = None
    title: str
    description: str = ""
    due_date: datetime
    priority: AssignmentPriorityEnum
    status: AssignmentStatusEnum
    weight_percentage: Optional[float] = None
    grade_received: Optional[float] = None
    feedback: Optional[str] = None
    file_ids: List[str] = Field(default_factory=list)
    is_overdue: bool = False
    countdown_text: str = ""
    created_at: datetime
    updated_at: datetime


class AssignmentListResponse(BaseModel):
    items: List[AssignmentResponse]
    total: int
    pending_count: int
    in_progress_count: int
    submitted_count: int
    graded_count: int
    urgent_count: int


class AssignmentSummaryResponse(BaseModel):
    total_assignments: int
    pending_count: int
    in_progress_count: int
    submitted_count: int
    graded_count: int
    overdue_count: int
    due_this_week_count: int

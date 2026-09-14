from datetime import datetime
from enum import Enum
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class NotificationTypeEnum(str, Enum):
    ASSIGNMENT_DUE = "assignment_due"
    EXAM_UPCOMING = "exam_upcoming"
    CLASS_STARTING = "class_starting"
    ATTENDANCE_WARNING = "attendance_warning"
    GPA_ALERT = "gpa_alert"
    SYSTEM = "system"


class NotificationPriorityEnum(str, Enum):
    HIGH = "high"
    NORMAL = "normal"
    LOW = "low"


class NotificationCreate(BaseModel):
    type: NotificationTypeEnum
    title: str = Field(..., min_length=1, max_length=200)
    message: str = Field(..., min_length=1, max_length=1000)
    priority: NotificationPriorityEnum = NotificationPriorityEnum.NORMAL
    action_route: Optional[str] = Field(None, description="In-app navigation route, e.g., /assignments")
    metadata: Optional[Dict[str, Any]] = None


class NotificationResponse(BaseModel):
    id: str
    user_id: str
    type: NotificationTypeEnum
    title: str
    message: str
    priority: NotificationPriorityEnum
    is_read: bool = False
    action_route: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None
    created_at: datetime
    read_at: Optional[datetime] = None


class NotificationListResponse(BaseModel):
    items: List[NotificationResponse]
    total: int
    unread_count: int


class UnreadCountResponse(BaseModel):
    unread_count: int


class NotificationPreferencesSchema(BaseModel):
    class_reminders: bool = True
    assignment_reminders: bool = True
    exam_reminders: bool = True
    attendance_warnings: bool = True
    reminder_lead_hours: int = Field(default=24, ge=1, le=168)

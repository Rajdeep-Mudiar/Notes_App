import logging
from datetime import datetime, timezone, timedelta
from typing import List, Optional
from app.repositories.notification_repository import NotificationRepository
from app.repositories.assignment_repository import AssignmentRepository
from app.repositories.exam_repository import ExamRepository
from app.repositories.timetable_repository import TimetableRepository
from app.repositories.attendance_repository import AttendanceRepository
from app.schemas.notification import (
    NotificationCreate,
    NotificationListResponse,
    NotificationPriorityEnum,
    NotificationResponse,
    NotificationTypeEnum,
)

logger = logging.getLogger(__name__)


class NotificationService:
    def __init__(
        self,
        notification_repo: NotificationRepository,
        assignment_repo: AssignmentRepository,
        exam_repo: ExamRepository,
        timetable_repo: TimetableRepository,
        attendance_repo: AttendanceRepository,
    ):
        self.notification_repo = notification_repo
        self.assignment_repo = assignment_repo
        self.exam_repo = exam_repo
        self.timetable_repo = timetable_repo
        self.attendance_repo = attendance_repo

    async def get_notifications(
        self,
        user_id: str,
        is_read: Optional[bool] = None,
        type: Optional[str] = None,
        limit: int = 50,
        skip: int = 0,
    ) -> NotificationListResponse:
        items = await self.notification_repo.get_notifications(
            user_id=user_id,
            is_read=is_read,
            type=type,
            limit=limit,
            skip=skip,
        )
        total = await self.notification_repo.count_notifications(
            user_id=user_id,
            is_read=is_read,
            type=type,
        )
        unread_count = await self.notification_repo.get_unread_count(user_id=user_id)

        return NotificationListResponse(
            items=[NotificationResponse(**item) for item in items],
            total=total,
            unread_count=unread_count,
        )

    async def get_unread_count(self, user_id: str) -> int:
        return await self.notification_repo.get_unread_count(user_id=user_id)

    async def mark_as_read(self, notification_id: str, user_id: str) -> Optional[NotificationResponse]:
        doc = await self.notification_repo.mark_as_read(notification_id=notification_id, user_id=user_id)
        if doc:
            return NotificationResponse(**doc)
        return None

    async def mark_all_as_read(self, user_id: str) -> int:
        return await self.notification_repo.mark_all_as_read(user_id=user_id)

    async def delete_notification(self, notification_id: str, user_id: str) -> bool:
        return await self.notification_repo.delete_notification(notification_id=notification_id, user_id=user_id)

    async def delete_all_read(self, user_id: str) -> int:
        return await self.notification_repo.delete_all_read(user_id=user_id)

    async def create_custom_notification(
        self,
        user_id: str,
        notification_in: NotificationCreate,
    ) -> NotificationResponse:
        doc = await self.notification_repo.create_notification(user_id=user_id, notification_in=notification_in)
        return NotificationResponse(**doc)

    async def generate_smart_alerts(self, user_id: str) -> int:
        """
        Scans assignments, exams, classes, and attendance to generate smart timely alerts.
        Uses dedup keys to prevent duplicate notifications.
        """
        now = datetime.now(timezone.utc)
        today_str = now.strftime("%Y-%m-%d")
        day_of_week = now.strftime("%A").lower()
        created_count = 0

        # 1. Scan Upcoming Assignments (< 24 hours)
        try:
            upcoming_assignments = await self.assignment_repo.get_upcoming(user_id=user_id, limit=20)
            for asgn in upcoming_assignments:
                due_date = asgn["due_date"]
                if due_date.tzinfo is None:
                    due_date = due_date.replace(tzinfo=timezone.utc)

                time_remaining = due_date - now
                hours_remaining = time_remaining.total_seconds() / 3600.0

                if 0 <= hours_remaining <= 24:
                    dedup_key = f"asgn_{asgn['id']}_24h"
                    exists = await self.notification_repo.notification_exists(user_id, dedup_key)
                    if not exists:
                        sub_code = asgn.get("subject_code") or "Assignment"
                        await self.notification_repo.create_notification(
                            user_id=user_id,
                            notification_in=NotificationCreate(
                                type=NotificationTypeEnum.ASSIGNMENT_DUE,
                                title=f"Deadline Approaching: {asgn['title']}",
                                message=f"{sub_code} assignment is due in {int(hours_remaining)} hours ({asgn.get('countdown_text', 'Due soon')}).",
                                priority=NotificationPriorityEnum.HIGH if hours_remaining <= 6 else NotificationPriorityEnum.NORMAL,
                                action_route="/assignments",
                                metadata={"assignment_id": asgn["id"], "due_date": due_date.isoformat()},
                            ),
                            dedup_key=dedup_key,
                        )
                        created_count += 1
        except Exception as e:
            logger.warning(f"Error scanning assignment alerts: {e}")

        # 2. Scan Upcoming Exams (< 48 hours)
        try:
            upcoming_exams = await self.exam_repo.get_upcoming(user_id=user_id, limit=20)
            for exam in upcoming_exams:
                exam_date = exam["date_time"]
                if exam_date.tzinfo is None:
                    exam_date = exam_date.replace(tzinfo=timezone.utc)

                time_remaining = exam_date - now
                hours_remaining = time_remaining.total_seconds() / 3600.0

                if 0 <= hours_remaining <= 48:
                    dedup_key = f"exam_{exam['id']}_48h"
                    exists = await self.notification_repo.notification_exists(user_id, dedup_key)
                    if not exists:
                        sub_code = exam.get("subject_code") or "Course"
                        loc = f" at {exam['location']}" if exam.get("location") else ""
                        await self.notification_repo.create_notification(
                            user_id=user_id,
                            notification_in=NotificationCreate(
                                type=NotificationTypeEnum.EXAM_UPCOMING,
                                title=f"Upcoming Exam: {exam['title']}",
                                message=f"{sub_code} exam scheduled for {exam_date.strftime('%b %d, %H:%M')}{loc}. Don't forget your revision materials!",
                                priority=NotificationPriorityEnum.HIGH,
                                action_route="/exams",
                                metadata={"exam_id": exam["id"], "exam_date": exam_date.isoformat()},
                            ),
                            dedup_key=dedup_key,
                        )
                        created_count += 1
        except Exception as e:
            logger.warning(f"Error scanning exam alerts: {e}")

        # 3. Scan Today's Classes
        try:
            today_slots = await self.timetable_repo.list_slots(user_id=user_id, day_of_week=day_of_week)
            for slot in today_slots:
                slot_id = slot.get("id") or "slot"
                dedup_key = f"class_{slot_id}_{today_str}"
                exists = await self.notification_repo.notification_exists(user_id, dedup_key)
                if not exists:
                    sub_title = slot.get("title") or slot.get("subject_name") or "Scheduled Class"
                    time_range = f"{slot.get('start_time')} - {slot.get('end_time')}"
                    room = f" in {slot['location']}" if slot.get("location") else ""
                    await self.notification_repo.create_notification(
                        user_id=user_id,
                        notification_in=NotificationCreate(
                            type=NotificationTypeEnum.CLASS_STARTING,
                            title=f"Class Today: {sub_title}",
                            message=f"{slot.get('class_type', 'Class').capitalize()} scheduled for {time_range}{room}.",
                            priority=NotificationPriorityEnum.NORMAL,
                            action_route="/timetable",
                            metadata={"slot_id": slot_id, "start_time": slot.get("start_time")},
                        ),
                        dedup_key=dedup_key,
                    )
                    created_count += 1
        except Exception as e:
            logger.warning(f"Error scanning class alerts: {e}")

        # 4. Scan Attendance Health Warnings (< 75%)
        try:
            attendance_summary = await self.attendance_repo.get_attendance_summary(user_id=user_id, target_percentage=75.0)
            stats_list = attendance_summary.subjects_stats if hasattr(attendance_summary, "subjects_stats") else attendance_summary.get("subjects_stats", [])
            for stats in stats_list:
                is_critical = stats.is_critical if hasattr(stats, "is_critical") else stats.get("is_critical")
                total_classes = stats.total_classes if hasattr(stats, "total_classes") else stats.get("total_classes", 0)
                if is_critical and total_classes > 0:
                    sub_id = stats.subject_id if hasattr(stats, "subject_id") else stats["subject_id"]
                    dedup_key = f"att_warn_{sub_id}_{today_str}"
                    exists = await self.notification_repo.notification_exists(user_id, dedup_key)
                    if not exists:
                        pct = stats.attendance_percentage if hasattr(stats, "attendance_percentage") else stats.get("attendance_percentage", 0.0)
                        needed = stats.classes_needed_to_target if hasattr(stats, "classes_needed_to_target") else stats.get("classes_needed_to_target", 1)
                        sub_name = (stats.subject_name if hasattr(stats, "subject_name") else stats.get("subject_name")) or "Subject"
                        await self.notification_repo.create_notification(
                            user_id=user_id,
                            notification_in=NotificationCreate(
                                type=NotificationTypeEnum.ATTENDANCE_WARNING,
                                title=f"Attendance Warning: {sub_name}",
                                message=f"Your attendance is at {pct:.1f}% (below 75% threshold). Attend the next {needed} classes consecutively to recover.",
                                priority=NotificationPriorityEnum.HIGH,
                                action_route="/timetable",
                                metadata={"subject_id": sub_id, "attendance_percentage": pct},
                            ),
                            dedup_key=dedup_key,
                        )
                        created_count += 1
        except Exception as e:
            logger.warning(f"Error scanning attendance alerts: {e}")

        return created_count


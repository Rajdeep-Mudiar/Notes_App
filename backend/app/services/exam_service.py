from datetime import datetime, timezone, timedelta
from typing import Any, Dict, List, Optional
from fastapi import HTTPException, status

from app.repositories.exam_repository import ExamRepository
from app.repositories.subject_repository import SubjectRepository
from app.schemas.exam import ExamCreate, ExamUpdate


class ExamService:
    def __init__(self, exam_repo: ExamRepository, subject_repo: SubjectRepository):
        self.repo = exam_repo
        self.subject_repo = subject_repo

    async def create_exam(self, user_id: str, exam_in: ExamCreate) -> dict:
        if exam_in.subject_id:
            subject = await self.subject_repo.get_by_id(exam_in.subject_id, user_id)
            if not subject:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Subject not found or does not belong to student"
                )

        data = exam_in.model_dump()
        data["user_id"] = user_id
        created = await self.repo.create(data)

        if exam_in.subject_id:
            await self._sync_subject_exams(exam_in.subject_id, user_id)

        return created

    async def get_exam(self, exam_id: str, user_id: str) -> dict:
        exam = await self.repo.get_by_id(exam_id, user_id)
        if not exam:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Exam not found"
            )
        return exam

    async def list_exams(
        self,
        user_id: str,
        subject_id: Optional[str] = None,
        exam_type: Optional[str] = None,
        is_upcoming: Optional[bool] = None,
        search: Optional[str] = None,
        limit: int = 100,
        skip: int = 0,
    ) -> Dict[str, Any]:
        items = await self.repo.get_all(
            user_id=user_id,
            subject_id=subject_id,
            exam_type=exam_type,
            is_upcoming=is_upcoming,
            search=search,
            limit=limit,
            skip=skip,
        )

        counts = await self.repo.get_summary(user_id)

        return {
            "items": items,
            "total": counts["total"],
            "upcoming_count": counts["upcoming_count"],
            "completed_count": counts["completed_count"],
        }

    async def get_upcoming(self, user_id: str, limit: int = 5) -> List[dict]:
        return await self.repo.get_upcoming(user_id=user_id, limit=limit)

    async def get_calendar(
        self,
        user_id: str,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
    ) -> Dict[str, Any]:
        now = datetime.now(timezone.utc)
        if start_date is None:
            # Default to start of current month
            start_date = datetime(now.year, now.month, 1, tzinfo=timezone.utc)
        if end_date is None:
            # Default to end of next month
            if now.month == 12:
                end_date = datetime(now.year + 1, 2, 1, tzinfo=timezone.utc) - timedelta(seconds=1)
            else:
                end_date = datetime(now.year, now.month + 2 if now.month < 11 else 12, 28, tzinfo=timezone.utc)

        events = await self.repo.get_calendar_events(user_id, start_date, end_date)

        return {
            "start_date": start_date,
            "end_date": end_date,
            "events": events,
            "total_events": len(events),
        }

    async def update_exam(
        self,
        exam_id: str,
        user_id: str,
        exam_update: ExamUpdate,
    ) -> dict:
        existing = await self.get_exam(exam_id, user_id)

        if exam_update.subject_id:
            subject = await self.subject_repo.get_by_id(exam_update.subject_id, user_id)
            if not subject:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Subject not found"
                )

        update_data = exam_update.model_dump(exclude_unset=True)
        updated = await self.repo.update(exam_id, user_id, update_data)
        if not updated:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Exam not found or failed to update"
            )

        old_subject_id = existing.get("subject_id")
        new_subject_id = updated.get("subject_id")
        if old_subject_id:
            await self._sync_subject_exams(old_subject_id, user_id)
        if new_subject_id and new_subject_id != old_subject_id:
            await self._sync_subject_exams(new_subject_id, user_id)

        return updated

    async def delete_exam(self, exam_id: str, user_id: str) -> bool:
        deleted = await self.repo.delete(exam_id, user_id)
        if not deleted:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Exam not found"
            )

        if deleted.get("subject_id"):
            await self._sync_subject_exams(deleted["subject_id"], user_id)

        return True

    async def _sync_subject_exams(self, subject_id: str, user_id: str) -> None:
        try:
            count = await self.repo.count_by_subject(subject_id, user_id)
            await self.subject_repo.update(subject_id, user_id, {"exams_count": count})
        except Exception:
            pass

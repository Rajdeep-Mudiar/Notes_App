from typing import Any, Dict, List, Optional
from fastapi import HTTPException, status

from app.repositories.assignment_repository import AssignmentRepository
from app.repositories.subject_repository import SubjectRepository
from app.schemas.assignment import (
    AssignmentCreate,
    AssignmentStatusEnum,
    AssignmentUpdate,
)


class AssignmentService:
    def __init__(self, assignment_repo: AssignmentRepository, subject_repo: SubjectRepository):
        self.repo = assignment_repo
        self.subject_repo = subject_repo

    async def create_assignment(self, user_id: str, assignment_in: AssignmentCreate) -> dict:
        if assignment_in.subject_id:
            subject = await self.subject_repo.get_by_id(assignment_in.subject_id, user_id)
            if not subject:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Subject not found or does not belong to student"
                )

        data = assignment_in.model_dump()
        data["user_id"] = user_id
        created = await self.repo.create(data)

        if assignment_in.subject_id:
            await self._sync_subject_assignments(assignment_in.subject_id, user_id)

        return created

    async def get_assignment(self, assignment_id: str, user_id: str) -> dict:
        assignment = await self.repo.get_by_id(assignment_id, user_id)
        if not assignment:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Assignment not found"
            )
        return assignment

    async def list_assignments(
        self,
        user_id: str,
        subject_id: Optional[str] = None,
        status: Optional[str] = None,
        priority: Optional[str] = None,
        search: Optional[str] = None,
        limit: int = 100,
        skip: int = 0,
    ) -> Dict[str, Any]:
        items = await self.repo.get_all(
            user_id=user_id,
            subject_id=subject_id,
            status=status,
            priority=priority,
            search=search,
            limit=limit,
            skip=skip,
        )

        counts = await self.repo.get_summary(user_id)
        urgent = sum(1 for item in items if item.get("priority") == "urgent")

        return {
            "items": items,
            "total": len(items),
            "pending_count": counts["pending_count"],
            "in_progress_count": counts["in_progress_count"],
            "submitted_count": counts["submitted_count"],
            "graded_count": counts["graded_count"],
            "urgent_count": urgent,
        }

    async def get_upcoming(self, user_id: str, limit: int = 5) -> List[dict]:
        return await self.repo.get_upcoming(user_id=user_id, limit=limit)

    async def get_summary(self, user_id: str) -> dict:
        return await self.repo.get_summary(user_id=user_id)

    async def update_assignment(
        self,
        assignment_id: str,
        user_id: str,
        assignment_update: AssignmentUpdate,
    ) -> dict:
        existing = await self.get_assignment(assignment_id, user_id)

        if assignment_update.subject_id:
            subject = await self.subject_repo.get_by_id(assignment_update.subject_id, user_id)
            if not subject:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Subject not found"
                )

        update_data = assignment_update.model_dump(exclude_unset=True)
        updated = await self.repo.update(assignment_id, user_id, update_data)
        if not updated:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Assignment not found or failed to update"
            )

        # Re-sync old and new subjects if subject changed
        old_subject_id = existing.get("subject_id")
        new_subject_id = updated.get("subject_id")
        if old_subject_id:
            await self._sync_subject_assignments(old_subject_id, user_id)
        if new_subject_id and new_subject_id != old_subject_id:
            await self._sync_subject_assignments(new_subject_id, user_id)

        return updated

    async def update_status(
        self,
        assignment_id: str,
        user_id: str,
        new_status: AssignmentStatusEnum,
    ) -> dict:
        updated = await self.repo.update(assignment_id, user_id, {"status": new_status.value})
        if not updated:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Assignment not found"
            )
        return updated

    async def delete_assignment(self, assignment_id: str, user_id: str) -> bool:
        deleted = await self.repo.delete(assignment_id, user_id)
        if not deleted:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Assignment not found"
            )

        if deleted.get("subject_id"):
            await self._sync_subject_assignments(deleted["subject_id"], user_id)

        return True

    async def _sync_subject_assignments(self, subject_id: str, user_id: str) -> None:
        try:
            count = await self.repo.count_by_subject(subject_id, user_id)
            await self.subject_repo.update(subject_id, user_id, {"assignments_count": count})
        except Exception:
            pass

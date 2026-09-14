from typing import Any, Dict, List, Optional
from fastapi import HTTPException, status
from app.repositories.subject_repository import SubjectRepository
from app.repositories.user_repository import UserRepository
from app.schemas.subject import (
    SubjectCreate,
    SubjectUpdate,
    SubjectResponse,
    SubjectListResponse,
    AcademicSummaryResponse
)


class SubjectService:
    def __init__(self, subject_repo: SubjectRepository, user_repo: UserRepository):
        self.subject_repo = subject_repo
        self.user_repo = user_repo

    async def create_subject(self, user_id: str, subject_in: SubjectCreate) -> SubjectResponse:
        # Check if subject code already exists in this semester
        existing = await self.subject_repo.get_by_code_and_semester(
            user_id=user_id,
            code=subject_in.code,
            semester=subject_in.semester
        )
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Subject with code '{subject_in.code.upper()}' already exists in Semester {subject_in.semester}."
            )

        subject_dict = subject_in.model_dump()
        subject_dict["user_id"] = user_id

        created = await self.subject_repo.create(subject_dict)
        return SubjectResponse(**created)

    async def get_subjects(
        self,
        user_id: str,
        semester: Optional[int] = None,
        include_archived: bool = False
    ) -> SubjectListResponse:
        subjects_data = await self.subject_repo.get_all_by_user(
            user_id=user_id,
            semester=semester,
            include_archived=include_archived
        )
        subjects = [SubjectResponse(**s) for s in subjects_data]
        return SubjectListResponse(
            subjects=subjects,
            total_count=len(subjects),
            semester=semester
        )

    async def get_subject_by_id(self, subject_id: str, user_id: str) -> SubjectResponse:
        subject = await self.subject_repo.get_by_id(subject_id, user_id)
        if not subject:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Subject not found or does not belong to you."
            )
        return SubjectResponse(**subject)

    async def update_subject(self, subject_id: str, user_id: str, update_in: SubjectUpdate) -> SubjectResponse:
        existing = await self.subject_repo.get_by_id(subject_id, user_id)
        if not existing:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Subject not found."
            )

        update_dict = {k: v for k, v in update_in.model_dump().items() if v is not None}
        if not update_dict:
            return SubjectResponse(**existing)

        # Check code collision if code or semester changed
        new_code = update_dict.get("code", existing.get("code"))
        new_sem = update_dict.get("semester", existing.get("semester"))
        if new_code != existing.get("code") or new_sem != existing.get("semester"):
            collision = await self.subject_repo.get_by_code_and_semester(user_id, new_code, new_sem)
            if collision and collision["id"] != subject_id:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Subject with code '{new_code}' already exists in Semester {new_sem}."
                )

        updated = await self.subject_repo.update(subject_id, user_id, update_dict)
        if not updated:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update subject."
            )
        return SubjectResponse(**updated)

    async def delete_subject(self, subject_id: str, user_id: str) -> bool:
        existing = await self.subject_repo.get_by_id(subject_id, user_id)
        if not existing:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Subject not found."
            )
        deleted = await self.subject_repo.delete(subject_id, user_id)
        return deleted

    async def toggle_archive_subject(self, subject_id: str, user_id: str) -> SubjectResponse:
        existing = await self.subject_repo.get_by_id(subject_id, user_id)
        if not existing:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Subject not found."
            )
        new_status = not existing.get("is_archived", False)
        updated = await self.subject_repo.update(subject_id, user_id, {"is_archived": new_status})
        return SubjectResponse(**updated)

    async def get_academic_summary(self, user_id: str) -> AcademicSummaryResponse:
        user = await self.user_repo.get_by_id(user_id)
        current_semester = user.get("current_semester", 1) if user else 1
        summary = await self.subject_repo.get_academic_summary(user_id, current_semester)
        return AcademicSummaryResponse(**summary)

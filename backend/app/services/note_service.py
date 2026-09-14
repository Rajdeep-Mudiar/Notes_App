from typing import Any, Dict, List, Optional
from fastapi import HTTPException, status
from app.repositories.note_repository import NoteRepository
from app.repositories.subject_repository import SubjectRepository
from app.schemas.note import (
    NoteCreate,
    NoteUpdate,
    NoteResponse,
    NoteSummaryResponse,
    NoteListResponse
)


class NoteService:
    def __init__(self, note_repo: NoteRepository, subject_repo: SubjectRepository):
        self.note_repo = note_repo
        self.subject_repo = subject_repo

    def _extract_preview(self, blocks: List[Dict[str, Any]], max_chars: int = 150) -> str:
        """Extract a readable preview string from the first few text-containing blocks."""
        texts = []
        for b in blocks:
            content = b.get("content", "").strip()
            if content:
                texts.append(content)
            if len(" ".join(texts)) >= max_chars:
                break
        combined = " ".join(texts)
        if len(combined) > max_chars:
            return combined[:max_chars] + "..."
        return combined

    async def _populate_subject_metadata(self, note_dict: Dict[str, Any], user_id: str) -> Dict[str, Any]:
        subject_id = note_dict.get("subject_id")
        if subject_id:
            subject = await self.subject_repo.get_by_id(subject_id, user_id)
            if subject:
                note_dict["subject_name"] = subject.get("name")
                note_dict["subject_code"] = subject.get("code")
                note_dict["subject_color"] = subject.get("color")
        return note_dict

    async def create_note(self, user_id: str, note_in: NoteCreate) -> NoteResponse:
        # If subject_id provided, verify ownership
        if note_in.subject_id:
            subject = await self.subject_repo.get_by_id(note_in.subject_id, user_id)
            if not subject:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Specified subject not found or not owned by student."
                )

        note_dict = note_in.model_dump()
        note_dict["user_id"] = user_id
        note_dict["preview_snippet"] = self._extract_preview(note_dict.get("blocks", []))

        created = await self.note_repo.create(note_dict)

        # Update subject's notes_count if attached to a subject
        if note_in.subject_id:
            count = await self.note_repo.count_by_subject(note_in.subject_id, user_id)
            await self.subject_repo.update(note_in.subject_id, user_id, {"notes_count": count})

        populated = await self._populate_subject_metadata(created, user_id)
        return NoteResponse(**populated)

    async def get_notes(
        self,
        user_id: str,
        subject_id: Optional[str] = None,
        tag: Optional[str] = None,
        is_favorite: Optional[bool] = None,
        is_pinned: Optional[bool] = None,
        search: Optional[str] = None,
        limit: int = 100,
        skip: int = 0
    ) -> NoteListResponse:
        notes_data = await self.note_repo.get_all_by_user(
            user_id=user_id,
            subject_id=subject_id,
            tag=tag,
            is_favorite=is_favorite,
            is_pinned=is_pinned,
            search=search,
            limit=limit,
            skip=skip
        )

        summaries = []
        for n in notes_data:
            populated = await self._populate_subject_metadata(n, user_id)
            summaries.append(NoteSummaryResponse(
                id=populated["id"],
                user_id=populated["user_id"],
                title=populated["title"],
                subject_id=populated.get("subject_id"),
                subject_name=populated.get("subject_name"),
                subject_code=populated.get("subject_code"),
                subject_color=populated.get("subject_color"),
                tags=populated.get("tags", []),
                icon=populated.get("icon", "article"),
                preview_snippet=populated.get("preview_snippet", self._extract_preview(populated.get("blocks", []))),
                blocks_count=len(populated.get("blocks", [])),
                is_favorite=populated.get("is_favorite", False),
                is_pinned=populated.get("is_pinned", False),
                is_archived=populated.get("is_archived", False),
                created_at=populated["created_at"],
                updated_at=populated["updated_at"],
            ))

        return NoteListResponse(
            notes=summaries,
            total_count=len(summaries),
            subject_id=subject_id,
            tag=tag
        )

    async def get_recent_notes(self, user_id: str, limit: int = 5) -> List[NoteSummaryResponse]:
        notes_data = await self.note_repo.get_recent(user_id, limit=limit)
        summaries = []
        for n in notes_data:
            populated = await self._populate_subject_metadata(n, user_id)
            summaries.append(NoteSummaryResponse(
                id=populated["id"],
                user_id=populated["user_id"],
                title=populated["title"],
                subject_id=populated.get("subject_id"),
                subject_name=populated.get("subject_name"),
                subject_code=populated.get("subject_code"),
                subject_color=populated.get("subject_color"),
                tags=populated.get("tags", []),
                icon=populated.get("icon", "article"),
                preview_snippet=populated.get("preview_snippet", self._extract_preview(populated.get("blocks", []))),
                blocks_count=len(populated.get("blocks", [])),
                is_favorite=populated.get("is_favorite", False),
                is_pinned=populated.get("is_pinned", False),
                is_archived=populated.get("is_archived", False),
                created_at=populated["created_at"],
                updated_at=populated["updated_at"],
            ))
        return summaries

    async def get_note_by_id(self, note_id: str, user_id: str) -> NoteResponse:
        note = await self.note_repo.get_by_id(note_id, user_id)
        if not note:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Note not found or does not belong to you."
            )
        populated = await self._populate_subject_metadata(note, user_id)
        return NoteResponse(**populated)

    async def update_note(self, note_id: str, user_id: str, update_in: NoteUpdate) -> NoteResponse:
        existing = await self.note_repo.get_by_id(note_id, user_id)
        if not existing:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Note not found."
            )

        update_dict = {k: v for k, v in update_in.model_dump().items() if v is not None}
        if "blocks" in update_dict:
            update_dict["preview_snippet"] = self._extract_preview(update_dict["blocks"])

        old_subject_id = existing.get("subject_id")
        new_subject_id = update_dict.get("subject_id", old_subject_id)

        # If changing subject, verify new subject
        if new_subject_id and new_subject_id != old_subject_id:
            subject = await self.subject_repo.get_by_id(new_subject_id, user_id)
            if not subject:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="New subject not found or not owned by student."
                )

        updated = await self.note_repo.update(note_id, user_id, update_dict)

        # Refresh counts if subject changed
        if old_subject_id and old_subject_id != new_subject_id:
            count_old = await self.note_repo.count_by_subject(old_subject_id, user_id)
            await self.subject_repo.update(old_subject_id, user_id, {"notes_count": count_old})
        if new_subject_id:
            count_new = await self.note_repo.count_by_subject(new_subject_id, user_id)
            await self.subject_repo.update(new_subject_id, user_id, {"notes_count": count_new})

        populated = await self._populate_subject_metadata(updated, user_id)
        return NoteResponse(**populated)

    async def delete_note(self, note_id: str, user_id: str) -> bool:
        existing = await self.note_repo.get_by_id(note_id, user_id)
        if not existing:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Note not found."
            )

        subject_id = existing.get("subject_id")
        deleted = await self.note_repo.delete(note_id, user_id)

        if deleted and subject_id:
            count = await self.note_repo.count_by_subject(subject_id, user_id)
            await self.subject_repo.update(subject_id, user_id, {"notes_count": count})

        return deleted

    async def toggle_favorite(self, note_id: str, user_id: str) -> NoteResponse:
        existing = await self.note_repo.get_by_id(note_id, user_id)
        if not existing:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Note not found."
            )
        new_fav = not existing.get("is_favorite", False)
        updated = await self.note_repo.update(note_id, user_id, {"is_favorite": new_fav})
        populated = await self._populate_subject_metadata(updated, user_id)
        return NoteResponse(**populated)

    async def toggle_pin(self, note_id: str, user_id: str) -> NoteResponse:
        existing = await self.note_repo.get_by_id(note_id, user_id)
        if not existing:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Note not found."
            )
        new_pin = not existing.get("is_pinned", False)
        updated = await self.note_repo.update(note_id, user_id, {"is_pinned": new_pin})
        populated = await self._populate_subject_metadata(updated, user_id)
        return NoteResponse(**populated)

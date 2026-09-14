from typing import Optional
from fastapi import APIRouter, Depends, Query, status
from app.api.deps import get_current_user, get_note_service
from app.services.note_service import NoteService
from app.schemas.user import UserProfileResponse
from app.schemas.note import (
    NoteCreate,
    NoteUpdate,
    NoteResponse,
    NoteSummaryResponse,
    NoteListResponse
)
from app.schemas.response import ApiResponse

router = APIRouter(prefix="/notes", tags=["Notes"])


@router.post("", response_model=ApiResponse[NoteResponse], status_code=status.HTTP_201_CREATED)
async def create_note(
    note_in: NoteCreate,
    current_user: UserProfileResponse = Depends(get_current_user),
    note_service: NoteService = Depends(get_note_service)
):
    """Create a structured block-based note."""
    note = await note_service.create_note(current_user.id, note_in)
    return ApiResponse(
        success=True,
        message=f"Note '{note.title}' created successfully.",
        data=note
    )


@router.get("", response_model=ApiResponse[NoteListResponse])
async def get_notes(
    subject_id: Optional[str] = Query(None, description="Filter notes by subject ID"),
    tag: Optional[str] = Query(None, description="Filter notes by tag, e.g. 'algorithms'"),
    is_favorite: Optional[bool] = Query(None, description="Filter favorite notes"),
    is_pinned: Optional[bool] = Query(None, description="Filter pinned notes"),
    search: Optional[str] = Query(None, description="Search keyword in title, body, or tags"),
    limit: int = Query(100, ge=1, le=200),
    skip: int = Query(0, ge=0),
    current_user: UserProfileResponse = Depends(get_current_user),
    note_service: NoteService = Depends(get_note_service)
):
    """List notes with flexible filtering and search."""
    result = await note_service.get_notes(
        user_id=current_user.id,
        subject_id=subject_id,
        tag=tag,
        is_favorite=is_favorite,
        is_pinned=is_pinned,
        search=search,
        limit=limit,
        skip=skip
    )
    return ApiResponse(
        success=True,
        message="Notes retrieved successfully.",
        data=result
    )


@router.get("/recent", response_model=ApiResponse[list[NoteSummaryResponse]])
async def get_recent_notes(
    limit: int = Query(5, ge=1, le=20),
    current_user: UserProfileResponse = Depends(get_current_user),
    note_service: NoteService = Depends(get_note_service)
):
    """Get recently edited student notes for the dashboard."""
    recent = await note_service.get_recent_notes(current_user.id, limit=limit)
    return ApiResponse(
        success=True,
        message="Recent notes retrieved successfully.",
        data=recent
    )


@router.get("/{note_id}", response_model=ApiResponse[NoteResponse])
async def get_note_by_id(
    note_id: str,
    current_user: UserProfileResponse = Depends(get_current_user),
    note_service: NoteService = Depends(get_note_service)
):
    """Get complete note with all structured blocks."""
    note = await note_service.get_note_by_id(note_id, current_user.id)
    return ApiResponse(
        success=True,
        message="Note retrieved successfully.",
        data=note
    )


@router.put("/{note_id}", response_model=ApiResponse[NoteResponse])
async def update_note(
    note_id: str,
    update_in: NoteUpdate,
    current_user: UserProfileResponse = Depends(get_current_user),
    note_service: NoteService = Depends(get_note_service)
):
    """Update note title, tags, cover, or blocks."""
    updated = await note_service.update_note(note_id, current_user.id, update_in)
    return ApiResponse(
        success=True,
        message="Note updated successfully.",
        data=updated
    )


@router.delete("/{note_id}", response_model=ApiResponse[dict])
async def delete_note(
    note_id: str,
    current_user: UserProfileResponse = Depends(get_current_user),
    note_service: NoteService = Depends(get_note_service)
):
    """Delete a note."""
    success = await note_service.delete_note(note_id, current_user.id)
    return ApiResponse(
        success=success,
        message="Note deleted successfully.",
        data={"deleted_id": note_id}
    )


@router.patch("/{note_id}/favorite", response_model=ApiResponse[NoteResponse])
async def toggle_favorite_note(
    note_id: str,
    current_user: UserProfileResponse = Depends(get_current_user),
    note_service: NoteService = Depends(get_note_service)
):
    """Toggle note favorite status."""
    updated = await note_service.toggle_favorite(note_id, current_user.id)
    return ApiResponse(
        success=True,
        message="Favorite updated.",
        data=updated
    )


@router.patch("/{note_id}/pin", response_model=ApiResponse[NoteResponse])
async def toggle_pin_note(
    note_id: str,
    current_user: UserProfileResponse = Depends(get_current_user),
    note_service: NoteService = Depends(get_note_service)
):
    """Toggle note pinned status."""
    updated = await note_service.toggle_pin(note_id, current_user.id)
    return ApiResponse(
        success=True,
        message="Pin status updated.",
        data=updated
    )

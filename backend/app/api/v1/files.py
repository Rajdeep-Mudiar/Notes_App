from typing import List, Optional
from fastapi import APIRouter, Depends, File, Form, Query, UploadFile, status
from fastapi.responses import FileResponse as FastApiFileResponse

from app.api.deps import get_current_user, get_file_service
from app.schemas.file import (
    FileListResponse,
    FileResponse,
    FolderCreate,
    FolderResponse,
    StorageSummaryResponse,
)
from app.schemas.user import UserProfileResponse
from app.services.file_service import FileService

router = APIRouter(prefix="/files", tags=["Files"])


@router.post("/upload", response_model=FileResponse, status_code=status.HTTP_201_CREATED)
async def upload_file(
    file: UploadFile = File(...),
    subject_id: Optional[str] = Form(None),
    folder_id: Optional[str] = Form(None),
    current_user: UserProfileResponse = Depends(get_current_user),
    service: FileService = Depends(get_file_service),
):
    """Upload a file (PDF, PPT, DOCX, Image, Video, etc.) with optional subject & folder association."""
    # Convert empty strings to None if passed via multipart form
    subj_id = subject_id if subject_id and subject_id.strip() else None
    fld_id = folder_id if folder_id and folder_id.strip() else None

    return await service.save_uploaded_file(
        file=file,
        user_id=current_user.id,
        subject_id=subj_id,
        folder_id=fld_id,
    )


@router.get("", response_model=FileListResponse)
async def list_files_and_folders(
    subject_id: Optional[str] = Query(None, description="Filter by subject"),
    folder_id: Optional[str] = Query(None, description="Filter by folder ('root' for top-level)"),
    file_type: Optional[str] = Query(None, description="Filter by file type (pdf, document, image, etc.)"),
    search: Optional[str] = Query(None, description="Search by filename"),
    is_favorite: Optional[bool] = Query(None, description="Filter favorite files"),
    current_user: UserProfileResponse = Depends(get_current_user),
    service: FileService = Depends(get_file_service),
):
    """List files and folders matching the given filters."""
    return await service.list_files_and_folders(
        user_id=current_user.id,
        subject_id=subject_id,
        folder_id=folder_id,
        file_type=file_type,
        search=search,
        is_favorite=is_favorite,
    )


@router.get("/storage", response_model=StorageSummaryResponse)
async def get_storage_summary(
    current_user: UserProfileResponse = Depends(get_current_user),
    service: FileService = Depends(get_file_service),
):
    """Get the student's storage usage metrics, breakdown by file type, and remaining quota."""
    return await service.get_storage_summary(user_id=current_user.id)


@router.post("/folders", response_model=FolderResponse, status_code=status.HTTP_201_CREATED)
async def create_folder(
    folder_in: FolderCreate,
    current_user: UserProfileResponse = Depends(get_current_user),
    service: FileService = Depends(get_file_service),
):
    """Create a new folder."""
    return await service.create_folder(user_id=current_user.id, folder_in=folder_in)


@router.get("/folders", response_model=List[FolderResponse])
async def list_folders(
    subject_id: Optional[str] = Query(None, description="Filter folders by subject"),
    parent_id: Optional[str] = Query(None, description="Filter by parent folder"),
    current_user: UserProfileResponse = Depends(get_current_user),
    service: FileService = Depends(get_file_service),
):
    """List student folders."""
    return await service.list_folders(
        user_id=current_user.id,
        subject_id=subject_id,
        parent_id=parent_id,
    )


@router.delete("/folders/{folder_id}", status_code=status.HTTP_200_OK)
async def delete_folder(
    folder_id: str,
    current_user: UserProfileResponse = Depends(get_current_user),
    service: FileService = Depends(get_file_service),
):
    """Delete a folder (unlinks contained files to root)."""
    await service.delete_folder(folder_id=folder_id, user_id=current_user.id)
    return {"success": True, "message": "Folder deleted successfully"}


@router.get("/{file_id}", response_model=FileResponse)
async def get_file_metadata(
    file_id: str,
    current_user: UserProfileResponse = Depends(get_current_user),
    service: FileService = Depends(get_file_service),
):
    """Get file metadata."""
    return await service.get_file_metadata(file_id=file_id, user_id=current_user.id)


@router.get("/{file_id}/download")
async def download_file(
    file_id: str,
    current_user: UserProfileResponse = Depends(get_current_user),
    service: FileService = Depends(get_file_service),
):
    """Download or stream raw file content."""
    meta = await service.get_file_metadata(file_id=file_id, user_id=current_user.id)
    physical_path = await service.get_physical_file_path(file_id=file_id, user_id=current_user.id)

    return FastApiFileResponse(
        path=str(physical_path),
        media_type=meta["mime_type"],
        filename=meta["original_name"],
    )


@router.delete("/{file_id}", status_code=status.HTTP_200_OK)
async def delete_file(
    file_id: str,
    current_user: UserProfileResponse = Depends(get_current_user),
    service: FileService = Depends(get_file_service),
):
    """Delete file record and remove from disk."""
    await service.delete_file(file_id=file_id, user_id=current_user.id)
    return {"success": True, "message": "File deleted successfully"}


@router.patch("/{file_id}/favorite", response_model=FileResponse)
async def toggle_favorite_file(
    file_id: str,
    current_user: UserProfileResponse = Depends(get_current_user),
    service: FileService = Depends(get_file_service),
):
    """Toggle favorite star on a file."""
    return await service.toggle_favorite(file_id=file_id, user_id=current_user.id)

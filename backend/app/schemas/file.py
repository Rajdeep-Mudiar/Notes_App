from datetime import datetime
from enum import Enum
from typing import Dict, List, Optional
from pydantic import BaseModel, Field


class FileTypeEnum(str, Enum):
    PDF = "pdf"
    DOCUMENT = "document"
    PRESENTATION = "presentation"
    SPREADSHEET = "spreadsheet"
    IMAGE = "image"
    VIDEO = "video"
    AUDIO = "audio"
    ARCHIVE = "archive"
    CODE = "code"
    OTHER = "other"


class FolderCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100, description="Folder display name")
    subject_id: Optional[str] = Field(None, description="Associated subject ID if folder is subject-scoped")
    parent_id: Optional[str] = Field(None, description="Parent folder ID for nested folders")
    color: Optional[str] = Field("#4F46E5", description="Hex color for folder display")
    icon: Optional[str] = Field("folder", description="Icon name")


class FolderResponse(BaseModel):
    id: str
    user_id: str
    name: str
    subject_id: Optional[str] = None
    parent_id: Optional[str] = None
    color: str = "#4F46E5"
    icon: str = "folder"
    items_count: int = 0
    created_at: datetime
    updated_at: datetime


class FileResponse(BaseModel):
    id: str
    user_id: str
    subject_id: Optional[str] = None
    folder_id: Optional[str] = None
    filename: str
    original_name: str
    file_type: FileTypeEnum
    mime_type: str
    size_bytes: int
    size_formatted: str
    download_url: str
    is_favorite: bool = False
    created_at: datetime
    updated_at: datetime


class FileListResponse(BaseModel):
    items: List[FileResponse]
    folders: List[FolderResponse]
    total_files: int
    total_folders: int


class StorageSummaryResponse(BaseModel):
    used_bytes: int
    used_formatted: str
    total_limit_bytes: int
    total_limit_formatted: str
    percentage_used: float
    files_count: int
    by_type: Dict[str, int]

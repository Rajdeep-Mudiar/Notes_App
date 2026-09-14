import os
import shutil
import uuid
from pathlib import Path
from typing import Any, Dict, List, Optional
from fastapi import HTTPException, UploadFile, status

from app.repositories.file_repository import FileRepository
from app.repositories.subject_repository import SubjectRepository
from app.schemas.file import FileTypeEnum, FolderCreate


# 500 MB student quota limit
STUDENT_STORAGE_LIMIT_BYTES = 500 * 1024 * 1024

UPLOAD_DIR = Path(__file__).resolve().parent.parent.parent / "uploads"


class FileService:
    def __init__(self, file_repo: FileRepository, subject_repo: SubjectRepository):
        self.file_repo = file_repo
        self.subject_repo = subject_repo
        self.upload_dir = UPLOAD_DIR
        self.upload_dir.mkdir(parents=True, exist_ok=True)

    @staticmethod
    def format_bytes(size_bytes: int) -> str:
        if size_bytes < 1024:
            return f"{size_bytes} B"
        elif size_bytes < 1024 * 1024:
            return f"{size_bytes / 1024:.1f} KB"
        elif size_bytes < 1024 * 1024 * 1024:
            return f"{size_bytes / (1024 * 1024):.1f} MB"
        else:
            return f"{size_bytes / (1024 * 1024 * 1024):.2f} GB"

    @staticmethod
    def deduce_file_type(filename: str, mime_type: str) -> FileTypeEnum:
        ext = filename.split(".")[-1].lower() if "." in filename else ""

        if ext in ["pdf"] or "pdf" in mime_type:
            return FileTypeEnum.PDF
        elif ext in ["doc", "docx", "odt", "rtf", "txt", "md"] or "word" in mime_type or "text" in mime_type:
            return FileTypeEnum.DOCUMENT
        elif ext in ["ppt", "pptx", "odp", "key"] or "presentation" in mime_type or "powerpoint" in mime_type:
            return FileTypeEnum.PRESENTATION
        elif ext in ["xls", "xlsx", "ods", "csv"] or "sheet" in mime_type or "excel" in mime_type:
            return FileTypeEnum.SPREADSHEET
        elif ext in ["png", "jpg", "jpeg", "gif", "webp", "svg", "bmp"] or mime_type.startswith("image/"):
            return FileTypeEnum.IMAGE
        elif ext in ["mp4", "mkv", "mov", "avi", "webm", "flv"] or mime_type.startswith("video/"):
            return FileTypeEnum.VIDEO
        elif ext in ["mp3", "wav", "m4a", "ogg", "flac", "aac"] or mime_type.startswith("audio/"):
            return FileTypeEnum.AUDIO
        elif ext in ["zip", "rar", "7z", "tar", "gz"]:
            return FileTypeEnum.ARCHIVE
        elif ext in ["py", "dart", "js", "ts", "html", "css", "java", "cpp", "c", "json", "sql", "sh"]:
            return FileTypeEnum.CODE
        else:
            return FileTypeEnum.OTHER

    async def save_uploaded_file(
        self,
        file: UploadFile,
        user_id: str,
        subject_id: Optional[str] = None,
        folder_id: Optional[str] = None,
    ) -> dict:
        # Validate subject ownership if subject_id provided
        if subject_id:
            subject = await self.subject_repo.get_by_id(subject_id, user_id)
            if not subject:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Subject not found or does not belong to student"
                )

        # Validate folder ownership if folder_id provided
        if folder_id:
            folder = await self.file_repo.get_folder_by_id(folder_id, user_id)
            if not folder:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Folder not found or does not belong to student"
                )

        # Check storage quota
        usage = await self.file_repo.get_storage_usage(user_id)
        current_used = usage["total_bytes"]

        user_upload_dir = self.upload_dir / str(user_id)
        user_upload_dir.mkdir(parents=True, exist_ok=True)

        original_filename = file.filename or "untitled_file"
        file_ext = Path(original_filename).suffix
        safe_filename = f"{uuid.uuid4().hex}_{Path(original_filename).stem[:40]}{file_ext}"
        destination_path = user_upload_dir / safe_filename

        # Write file in chunks and calculate bytes
        size_bytes = 0
        try:
            with destination_path.open("wb") as buffer:
                while content := await file.read(1024 * 1024):  # 1MB chunks
                    buffer.write(content)
                    size_bytes += len(content)
        except Exception as e:
            if destination_path.exists():
                destination_path.unlink()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to write file to disk: {str(e)}"
            )

        if current_used + size_bytes > STUDENT_STORAGE_LIMIT_BYTES:
            if destination_path.exists():
                destination_path.unlink()
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail=f"Storage quota exceeded! Maximum allowed is {self.format_bytes(STUDENT_STORAGE_LIMIT_BYTES)}."
            )

        mime_type = file.content_type or "application/octet-stream"
        file_type = self.deduce_file_type(original_filename, mime_type)

        file_record = await self.file_repo.create_file({
            "user_id": user_id,
            "subject_id": subject_id,
            "folder_id": folder_id,
            "filename": safe_filename,
            "original_name": original_filename,
            "file_type": file_type.value,
            "mime_type": mime_type,
            "size_bytes": size_bytes,
            "size_formatted": self.format_bytes(size_bytes),
        })

        # Synchronize subject's files_count
        if subject_id:
            await self._sync_subject_files_count(subject_id, user_id)

        return file_record

    async def get_file_metadata(self, file_id: str, user_id: str) -> dict:
        file_doc = await self.file_repo.get_file_by_id(file_id, user_id)
        if not file_doc:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="File not found"
            )
        return file_doc

    async def get_physical_file_path(self, file_id: str, user_id: str) -> Path:
        file_doc = await self.get_file_metadata(file_id, user_id)
        path = self.upload_dir / str(user_id) / file_doc["filename"]
        if not path.exists():
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Physical file content not found on server"
            )
        return path

    async def list_files_and_folders(
        self,
        user_id: str,
        subject_id: Optional[str] = None,
        folder_id: Optional[str] = None,
        file_type: Optional[str] = None,
        search: Optional[str] = None,
        is_favorite: Optional[bool] = None,
    ) -> Dict[str, Any]:
        files = await self.file_repo.get_files(
            user_id=user_id,
            subject_id=subject_id,
            folder_id=folder_id,
            file_type=file_type,
            search=search,
            is_favorite=is_favorite,
        )
        # Folders are listed at this level if not searching by global search
        folders = []
        if not search and not file_type and not is_favorite:
            folders = await self.file_repo.get_folders(
                user_id=user_id,
                subject_id=subject_id,
                parent_id=folder_id,
            )

        return {
            "items": files,
            "folders": folders,
            "total_files": len(files),
            "total_folders": len(folders),
        }

    async def delete_file(self, file_id: str, user_id: str) -> bool:
        deleted_file = await self.file_repo.delete_file(file_id, user_id)
        if not deleted_file:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="File not found"
            )

        # Unlink from disk
        path = self.upload_dir / str(user_id) / deleted_file["filename"]
        if path.exists():
            try:
                path.unlink()
            except Exception:
                pass

        if deleted_file.get("subject_id"):
            await self._sync_subject_files_count(deleted_file["subject_id"], user_id)

        return True

    async def toggle_favorite(self, file_id: str, user_id: str) -> dict:
        updated = await self.file_repo.toggle_favorite(file_id, user_id)
        if not updated:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="File not found"
            )
        return updated

    async def get_storage_summary(self, user_id: str) -> dict:
        usage = await self.file_repo.get_storage_usage(user_id)
        used_bytes = usage["total_bytes"]
        limit_bytes = STUDENT_STORAGE_LIMIT_BYTES
        pct = (used_bytes / limit_bytes * 100.0) if limit_bytes > 0 else 0.0

        return {
            "used_bytes": used_bytes,
            "used_formatted": self.format_bytes(used_bytes),
            "total_limit_bytes": limit_bytes,
            "total_limit_formatted": self.format_bytes(limit_bytes),
            "percentage_used": round(pct, 2),
            "files_count": usage["files_count"],
            "by_type": usage["by_type"],
        }

    # ==================== FOLDERS ====================

    async def create_folder(self, user_id: str, folder_in: FolderCreate) -> dict:
        if folder_in.subject_id:
            subject = await self.subject_repo.get_by_id(folder_in.subject_id, user_id)
            if not subject:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Subject not found"
                )

        folder_data = folder_in.model_dump()
        folder_data["user_id"] = user_id
        return await self.file_repo.create_folder(folder_data)

    async def list_folders(
        self,
        user_id: str,
        subject_id: Optional[str] = None,
        parent_id: Optional[str] = None,
    ) -> List[dict]:
        return await self.file_repo.get_folders(
            user_id=user_id,
            subject_id=subject_id,
            parent_id=parent_id,
        )

    async def delete_folder(self, folder_id: str, user_id: str) -> bool:
        folder = await self.file_repo.get_folder_by_id(folder_id, user_id)
        if not folder:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Folder not found"
            )
        return await self.file_repo.delete_folder(folder_id, user_id)

    async def _sync_subject_files_count(self, subject_id: str, user_id: str) -> None:
        try:
            count = await self.file_repo.count_files(user_id=user_id, subject_id=subject_id)
            await self.subject_repo.update(subject_id, user_id, {"files_count": count})
        except Exception:
            pass

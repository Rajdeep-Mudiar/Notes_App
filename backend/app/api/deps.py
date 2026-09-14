from typing import Dict, Any
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.core.database import get_database
from app.core.security import decode_token
from app.repositories.user_repository import UserRepository
from app.repositories.subject_repository import SubjectRepository
from app.repositories.note_repository import NoteRepository
from app.repositories.file_repository import FileRepository
from app.repositories.assignment_repository import AssignmentRepository
from app.repositories.exam_repository import ExamRepository
from app.services.auth_service import AuthService
from app.services.subject_service import SubjectService
from app.services.note_service import NoteService
from app.services.file_service import FileService
from app.services.assignment_service import AssignmentService
from app.services.exam_service import ExamService
from app.schemas.user import UserProfileResponse

bearer_scheme = HTTPBearer(auto_error=True)


def get_user_repository(db: AsyncIOMotorDatabase = Depends(get_database)) -> UserRepository:
    return UserRepository(db)


def get_subject_repository(db: AsyncIOMotorDatabase = Depends(get_database)) -> SubjectRepository:
    return SubjectRepository(db)


def get_note_repository(db: AsyncIOMotorDatabase = Depends(get_database)) -> NoteRepository:
    return NoteRepository(db)


def get_file_repository(db: AsyncIOMotorDatabase = Depends(get_database)) -> FileRepository:
    return FileRepository(db)


def get_assignment_repository(db: AsyncIOMotorDatabase = Depends(get_database)) -> AssignmentRepository:
    return AssignmentRepository(db)


def get_exam_repository(db: AsyncIOMotorDatabase = Depends(get_database)) -> ExamRepository:
    return ExamRepository(db)


def get_auth_service(user_repo: UserRepository = Depends(get_user_repository)) -> AuthService:
    return AuthService(user_repo)


def get_subject_service(
    subject_repo: SubjectRepository = Depends(get_subject_repository),
    user_repo: UserRepository = Depends(get_user_repository)
) -> SubjectService:
    return SubjectService(subject_repo, user_repo)


def get_note_service(
    note_repo: NoteRepository = Depends(get_note_repository),
    subject_repo: SubjectRepository = Depends(get_subject_repository)
) -> NoteService:
    return NoteService(note_repo, subject_repo)


def get_file_service(
    file_repo: FileRepository = Depends(get_file_repository),
    subject_repo: SubjectRepository = Depends(get_subject_repository)
) -> FileService:
    return FileService(file_repo, subject_repo)


def get_assignment_service(
    assignment_repo: AssignmentRepository = Depends(get_assignment_repository),
    subject_repo: SubjectRepository = Depends(get_subject_repository)
) -> AssignmentService:
    return AssignmentService(assignment_repo, subject_repo)


def get_exam_service(
    exam_repo: ExamRepository = Depends(get_exam_repository),
    subject_repo: SubjectRepository = Depends(get_subject_repository)
) -> ExamService:
    return ExamService(exam_repo, subject_repo)


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    user_repo: UserRepository = Depends(get_user_repository)
) -> UserProfileResponse:
    token = credentials.credentials
    payload = decode_token(token)
    if not payload or payload.get("type") != "access":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token or token expired.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user_id: str = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user = await user_repo.get_by_id(user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User associated with token does not exist.",
        )

    if not user.get("is_active", True):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is inactive.",
        )

    return UserProfileResponse(**user)
